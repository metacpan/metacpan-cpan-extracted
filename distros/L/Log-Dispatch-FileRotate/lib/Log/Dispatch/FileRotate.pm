package Log::Dispatch::FileRotate;
$Log::Dispatch::FileRotate::VERSION = '1.38';
# ABSTRACT: Log to Files that Archive/Rotate Themselves

require 5.005;
use strict;

use base 'Log::Dispatch::Output';

use Date::Manip;
use File::Spec;
use Log::Dispatch::File;
use Log::Dispatch::FileRotate::Mutex;

sub DESTROY {
    my $self = shift;

    # get rid of current LDF
    if ($self->{LDF}) {
        delete $self->{LDF};
    }
}


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    # Turn ON/OFF debugging as required
    $self->{debug} = $p{DEBUG};
    $self->_basic_init(%p);
    $self->{LDF}   = Log::Dispatch::File->new(%p);  # Our log

    unless (defined $self->{timer}) {
        $self->{timer} = sub { time };
    }

    # Keep a copy of interesting stuff as well
    $self->{params} = \%p;

    # Size defaults to 10meg in all failure modes, hopefully
    my $ten_meg = 1024*1024*10;
    my $two_gig = 1024*1024*1024*2;
    my $size    = $ten_meg;

    if (defined $p{size}) {
        # allow perl-literal style nubers 10_000_000 -> 10000000
        $p{size} =~ s/_//g;
        $size = $p{size};
    }

    unless ($size =~ /^\d+$/ && $size < $two_gig && $size > 0) {
        $size = $ten_meg;
    }

    $self->{size} = $size;

    # Max number of files defaults to 1. No limit enforced here. Only
    # positive whole numbers allowed
    $self->{max} = $p{max};

    unless (defined $self->{max} && $self->{max} =~ /^\d+$/ && $self->{max} > 0) {
        $self->{max}  = 1
    }

    # Get a name for our Lock file
    my $name = $self->{params}->{filename};
    my ($vol, $dir, $f) = File::Spec->splitpath($name);
    $dir ||= '.';
    $f   ||= $name;

    $self->{lf} = File::Spec->catpath($vol, $dir, ".${f}.LCK");
    $self->debug('Lock file is '.$self->{lf});

    # Have we been called with a time based rotation pattern then setup
    # timebased stuff. TZ is important and must match current TZ or all
    # bets are off!
    if (defined $p{TZ}) {
        # Date::Manip deprecated TZ= in 6.x.  In order to maintain backwards
        # compat with 5.8, we use TZ if setdate is not avilable.  Otherwise we
        # use setdate.
        require version;
        if (version->parse(DateManipVersion()) < version->parse('6.0')) {
            Date_Init("TZ=".$p{TZ});
        }
        else {
            # Date::Manip 6.x deprecates TZ, use  SetDate instead
            Date_Init("setdate=now,".$p{TZ});
        }
    }

    if (defined $p{DatePattern}) {
        $self->setDatePattern($p{DatePattern});
    }

    $self->{check_both} = $p{check_both} ? 1 : 0;

    # User callback to rotate the file.
    $self->{user_constraint} = $p{user_constraint};

    # A post rotate callback.
    $self->{post_rotate} = $p{post_rotate};

    # Flag this as first creation point
    $self->{new} = 1;

    return $self;
}


sub filename {
    my $self = shift;

    return $self->{params}->{filename};
}


###########################################################################
#
# Subroutine setDatePattern
#
#       Args: a single string or ArrayRef of strings
#
#       Rtns: Nothing
#
# Description:
#     Set a recurrance for file rotation. We accept Date::Manip
#     recurrances and the log4j/DailyRollingFileAppender patterns
#
#     Date:Manip =>
#           0:0:0:0:5:30:0       every 5 hours and 30 minutes
#           0:0:0:2*12:30:0      every 2 days at 12:30 (each day)
#           3*1:0:2:12:0:0       every 3 years on Jan 2 at noon
#
#     DailyRollingFileAppender =>
#           yyyy-MM
#           yyyy-ww
#           yyyy-MM-dd
#           yyyy-MM-dd-a
#           yyyy-MM-dd-HH
#           yyyy-MM-dd-HH-MM
#
# To specify multiple recurances in a single string seperate them with a
# comma: yyyy-MM-dd,0:0:0:2*12:30:0
#
sub setDatePattern {
    my ($self, $arg) = @_;

    local($_);               # Don't crap on $_
    my @pats = ();

    my %lookup = (
        #                      Y:M:W:D:H:M:S
        'yyyy-mm'          => '0:1*0:1:0:0:0',     # Every Month
        'yyyy-ww'          => '0:0:1*0:0:0:0',     # Every week
        'yyyy-dd'          => '0:0:0:1*0:0:0',     # Every day
        'yyyy-mm-dd'       => '0:0:0:1*0:0:0',     # Every day
        'yyyy-dd-a'        => '0:0:0:1*12:0:0',    # Every day 12noon
        'yyyy-mm-dd-a'     => '0:0:0:1*12:0:0',    # Every day 12noon
        'yyyy-dd-hh'       => '0:0:0:0:1*0:0',     # Every hour
        'yyyy-mm-dd-hh'    => '0:0:0:0:1*0:0',     # Every hour
        'yyyy-dd-hh-mm'    => '0:0:0:0:0:1*0',     # Every minute
        'yyyy-mm-dd-hh-mm' => '0:0:0:0:0:1*0',     # Every minute
    );

    # Convert arg to array
    if (ref $arg eq 'ARRAY') {
        @pats = @$arg;
    }
    elsif (!ref $arg) {
        $arg =~ s/\s+//go;
        @pats = split /;/, $arg;
    }
    else {
        die "Bad reference type argument ".ref $arg;
    }

    # Handle (possibly multiple) recurrances
    foreach my $pat (@pats) {
        # Convert any log4j patterns across
        if ($pat =~ /^yyyy/i) {
            # log4j style
            $pat = $lookup{lc $pat};

            # Default to daily on bad pattern
            unless (defined $pat) {
                warn "Bad Rotation pattern ($pat) using yyyy-dd\n";
                $pat = 'yyyy-dd';
            }
        }

        my $abs = $self->_get_next_occurance($pat);

        $self->debug("Adding [dates,pat] =>[$abs,$pat]");

        my $ref = [$abs, $pat];

        push @{$self->{recurrance}}, $ref;
    }
}


sub log_message {
    my ($self, %p) = @_;

    my $mutex = $self->rotate(1);

    unless (defined $mutex) {
        $self->error('not logging');
        return;
    }

    $self->debug('normal log');

    $self->logit($p{message});

    $self->debug('releasing lock');

    $mutex->unlock;
}


sub rotate {
    my ($self, $hold_lock) = @_;
    # NOTE: $hold_lock is internal use only!

    my $max_size = $self->{size};
    my $numfiles = $self->{max};
    my $name     = $self->filename();
    my $fh       = $self->{LDF}->{fh};

    # Prime our time based data outside the critical code area
    my ($in_time_mode,$time_to_rotate) = $self->time_to_rotate();

    my $user_rotation = 0;
    if (ref $self->{user_constraint} eq 'CODE') {
        eval {
            $user_rotation = &{$self->{user_constraint}}();

            1;
        } or do {
            $self->error("user's callback error: $@");
        };
    }

    # Handle critical code for logging. No changes if someone else is in.  We
    # lock a lockfile, not the actual log filehandle since the log filehandle
    # will change if we rotate the logs.
    my $mutex = $self->mutex_for_path($self->{lf});

    unless ($mutex->lock) {
        $self->error("failed to get lock: $!");
        return;
    }

    $self->debug('got lock');

    my $have_to_rotate = 0;
    my ($inode, $size) = (stat $fh)[1,7]; # real inode and size
    my $finode         = (stat $name)[1]; # inode of filename for comparision

    $self->debug("s=$size, i=$inode, f=".
            (defined $finode ? $finode : "undef") .
            ", n=$name");

    # If finode and inode are the same then nobody has done a rename
    # under us and we can continue. Otherwise just close and reopen.
    if (!defined $finode || $inode != $finode) {
        # Oops someone moved things on us. So just reopen our log
        delete $self->{LDF};  # Should get rid of current LDF
        $self->{LDF} =  Log::Dispatch::File->new(%{$self->{params}});  # Our log

        $self->debug('Someone else rotated');
    }
    else {
        my $check_both = $self->{check_both};
        my $rotate_by_size = ($size >= $max_size) ? 1 : 0;

        if(($in_time_mode && $time_to_rotate) ||
           (!$in_time_mode && $rotate_by_size) ||
           ($rotate_by_size && $check_both) ||
           ($user_rotation))
        {
            $have_to_rotate = 1;
        }

        $self->debug("in time mode: $in_time_mode; time to rotate: $time_to_rotate;"
            ." rotate by size: $rotate_by_size; check_both: $check_both;"
            ." user rotation: $user_rotation; have to rotate: $have_to_rotate");
    }

    if ($have_to_rotate) {
        # Shut down the log
        delete $self->{LDF};  # Should get rid of current LDF

        $self->debug('Rotating');
        $self->_for_each_file(\&_move_file);
        $self->debug('Rotating Done');

        # reopen the logfile for writing.
        $self->{LDF} =  Log::Dispatch::File->new(%{$self->{params}});  # Our log

        if (ref $self->{post_rotate} eq 'CODE') {
            $self->debug('Calling user post-rotate callback');
            $self->_for_each_file($self->{post_rotate});
        }
    }

    if ($hold_lock) {
        return $mutex;
    }

    $mutex->unlock;

    return $have_to_rotate;
}

sub _for_each_file {
    my ($self, $callback) = @_;

    my $basename = $self->filename();
    my $idx      = $self->{max} - 1;

    while ($idx >= 0) {
        my $filename = $basename;

        if ($idx) {
            $filename .= ".$idx";
        }

        eval {
            if (-f $filename) {
                &{$callback}($filename, $idx, $self);
            }

            1;
        } or do {
            $self->error("callback error: $@");
        };

        $idx--;
    }

    return undef;
}

sub _move_file {
    my ($filename, $idx, $fileRotate) = @_;

    my $basename = $fileRotate->filename();
    my $newfile  = $basename . '.' . ($idx+1);

    $fileRotate->debug("rename $filename $newfile");

    rename $filename, $newfile;

    return undef;
}

sub logit {
    my ($self, $message) = @_;

    # Make sure we are at the EOF
    seek $self->{LDF}{fh}, 0, 2;

    $self->{LDF}->log_message(message => $message);

    return;
}

{
    my %MUTEXES;

    sub mutex_for_path {
        my ($self, $path) = @_;

        my %args;

        # use same permissions for the Mutex file
        if (exists $self->{params}{permissions}) {
            $args{permissions} = $self->{params}{permissions};
        }

        $MUTEXES{$path} ||= Log::Dispatch::FileRotate::Mutex->new($path, %args);
    }
}

###########################################################################
#
# Subroutine time_to_rotate
#
#       Args: none
#
#       Rtns: (1,n)  if we are in time mode and its time to rotate
#                    n defines the number of timers that expired
#             (1,0)  if we are in time mode but not ready to rotate
#             (0,0)  otherwise
#
# Description:
#     time_to_rotate - update internal clocks and return status as
#     defined above
#
# If we have just been created then the first recurrance is an indication
# to check against the log file.
#
#
#   my ($in_time_mode,$time_to_rotate) = $self->time_to_rotate();
sub time_to_rotate {
    my $self = shift;

    my $mode   = defined $self->{recurrance};
    my $rotate = 0;

    if ($mode) {
        # Then do some checking and update ourselves if we think we need
        # to rotate. Wether we rotate or not is up to our caller. We
        # assume they know what they are doing!

        # Only stat the log file here if we are in our first invocation.
        my $ftime = $self->{new}
            ? (stat $self->{LDF}{fh})[9]
            : 0;

        # Check need for rotation. Loop through our recurrances looking
        # for expiration times. Any we find that have expired we update.
        my $tm    = $self->{timer}->();
        my @recur = @{$self->{recurrance}};

        $self->{recurrance} = [];

        for my $rec (@recur) {
            my ($abs, $pat) = @$rec;

            # Extra checking
            unless (defined $abs && $abs) {
                warn "Bad time found for recurrance pattern $pat: $abs\n";
                next;
            }

            my $dorotate = 0;

            # If this is first time through
            if ($self->{new}) {
                # If it needs a rotate then flag it
                if ($ftime <= $abs) {
                    # Then we need to rotate
                    $self->debug("Need rotate file($ftime) <= $abs");
                    $rotate++;
                    $dorotate++;  # Just for debugging
                }

                # Move to next occurance regardless
                $self->debug("Dropping initial occurance($abs)");
                $abs = $self->_get_next_occurance($pat);
                unless (defined $abs && $abs) {
                    warn "Next occurance is null for $pat\n";
                    $abs = 0;
                }
            }
            elsif ($abs <= $tm) {
                # Then we need to rotate
                $self->debug("Need rotate $abs <= $tm");
                $abs = $self->_get_next_occurance($pat);
                unless (defined $abs && $abs) {
                    warn "Next occurance is null for $pat\n";
                    $abs = 0;
                }

                $rotate++;
                $dorotate++;  # Just for debugging
            }

            if ($abs) {
                push @{$self->{recurrance}}, [$abs, $pat];
            }

            $self->debug("time_to_rotate(mode,rotate,next) => ($mode,$dorotate,$abs)");
        }
    }

    $self->{new} = 0;  # No longer brand-spankers

    $self->debug("time_to_rotate(mode,rotate) => ($mode,$rotate)");

    return wantarray ? ($mode, $rotate) : $rotate;
}

###########################################################################
#
# Subroutine _gen_occurance
#
#       Args: Date::Manip occurance pattern
#
#       Rtns: array of dates for next few events
#
#  If asked we will return an inital occurance that is before the current
#  time. This can be used to see if we need to rotate on start up. We are
#  often called by CGI (short lived) proggies :-(
#
sub _gen_occurance {
    my ($self, $pat, $initial) = @_;

    # Do we return an initial occurance before the current time?
    $initial ||= 0;

    my $range = '';
    my $base  = 'now'; # default to calcs based on the current time

    if ($pat =~ /^0:0:0:0:0/) {
        # Small recurrance less than 1 hour
        $range = "4 hours later";
        $base  = "1 hours ago" if $initial;
    }
    elsif ($pat =~ /^0:0:0:0/) {
        # recurrance less than 1 day
        $range = "4 days later";
        $base  = "1 days ago" if $initial;
    }
    elsif ($pat =~ /^0:0:0:/) {
        # recurrance less than 1 week
        $range = "4 weeks later";
        $base  = "1 weeks ago" if $initial;
    }
    elsif ($pat =~ /^0:0:/) {
        # recurrance less than 1 month
        $range = "4 months later";
        $base  = "1 months ago" if $initial;
    }
    elsif ($pat =~ /^0:/) {
        # recurrance less than 1 year
        $range = "24 months later";
        $base  = "24 months ago" if $initial;
    }
    else {
        # years
        my ($yrs) = $pat =~ m/^(\d+):/;

        $yrs ||= 1;

        my $months = $yrs * 4 * 12;

        $range = "$months months later";
        $base  = "$months months ago" if $initial;
    }

    # The next date must start at least 1 second away from now other wise
    # we may rotate for every message we recieve with in this second :-(
    my $start = DateCalc($base,"+ 1 second");

    $self->debug("ParseRecur($pat,$base,$start,$range);");

    my @dates = ParseRecur($pat,$base,$start,$range);

    # Just in case we have a bad parse or our assumptions are wrong.
    # We default to days
    unless (scalar @dates >= 2) {
        warn "Failed to parse ($pat). Going daily\n";

        if ($initial) {
            @dates = ParseRecur('0:0:0:1*0:0:0',"2 days ago","2 days ago","1 months later");
        }
        else {
            @dates = ParseRecur('0:0:0:1*0:0:0',"now","now","1 months later");
        }
    }

    # Convert the dates to seconds since the epoch so we can use
    # numerical comparision instead of textual
    my @epochs = ();
    my @a = ('%Y','%m','%d','%H','%M','%S');
    foreach (@dates) {
        my ($y,$m,$d,$h,$mn,$s) = Date::Manip::UnixDate($_, @a);

        my $e = Date_SecsSince1970GMT($m,$d,$y,$h,$mn,$s);

        $self->debug("Date to epochs ($_) => ($e)");

        push @epochs, $e;
    }

    # Clean out all but the one previous to now if we are doing an
    # initial occurance
    my $now = time;

    if ($initial) {
        my $before = '';

        while (@epochs && $epochs[0] <= $now) {
            $before = shift @epochs;
        }

        if ($before) {
            unshift @epochs, $before;
        }
    }
    else {
        # Clean out dates that occur before now, being careful not to loop
        # forever (thanks James).
        while (@epochs && $epochs[0] <= $now) {
            shift @epochs;
        }
    }

    $self->debug("Recurrances are at: ". join "\n\t", @dates);

    warn "No recurrances found! Probably a timezone issue!\n" unless @dates;

    return @epochs;
}

###########################################################################
#
# Subroutine _get_next_occurance
#
#       Args: Date::Manip occurance pattern
#
#       Rtns: date
#
# We don't want to call Date::Manip::ParseRecur too often as it is very
# expensive. So, we cache what is returned from _gen_occurance().
sub _get_next_occurance {
    my ($self, $pat) = @_;

    # (ms) Throw out expired occurances
    my $now = $self->{timer}->();

    if (defined $self->{dates}{$pat}) {
        while (@{$self->{dates}{$pat}}) {
            last if $self->{dates}{$pat}->[0] >= $now;
            shift @{$self->{dates}{$pat}};
        }
    }

    # If this is first time then generate some new ones including one
    # before our time to test against the log file
    unless (defined $self->{'dates'}{$pat}) {
        @{$self->{'dates'}{$pat}} = $self->_gen_occurance($pat,1);
    }
    elsif (scalar(@{$self->{'dates'}{$pat}}) < 2) {
        # close to the end of what we have
        @{$self->{'dates'}{$pat}} = $self->_gen_occurance($pat);
    }

    return shift @{$self->{'dates'}{$pat}};
}


sub debug {
    my ($self, $message) = @_;

    return unless $self->{debug};

    warn localtime() . " $$ $message\n";

    return;
}

sub error {
    my ($self, $message) = @_;

    chomp $message;

    warn "$$ " . __PACKAGE__ . " $message\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::FileRotate - Log to Files that Archive/Rotate Themselves

=head1 VERSION

version 1.38

=head1 SYNOPSIS

  use Log::Dispatch::FileRotate;

  my $logger = Log::Dispatch::FileRotate->new(
      name      => 'file1',
      min_level => 'info',
      filename  => 'Somefile.log',
      mode      => 'append' ,
      size      => 10*1024*1024,
      max       => 6);

  # or for a time based rotation

  my $logger = Log::Dispatch::FileRotate->new(
      name      => 'file1',
      min_level => 'info',
      filename  => 'Somefile.log',
      mode      => 'append' ,
      TZ        => 'AEDT',
      DatePattern => 'yyyy-dd-HH');

  # and attach to Log::Dispatch
  my $dispatcher = Log::Dispatch->new;
  $dispatcher->add($logger);

  $dispatcher->log( level => 'info', message => "your comment\n" );

=head1 DESCRIPTION

This module extends the base class L<Log::Dispatch::Output> to provides a
simple object for logging to files under the Log::Dispatch::* system, and
automatically rotating them according to different constraints. This is
basically a L<Log::Dispatch::File> wrapper with additions.

=head2 Rotation

There are three different constraints which decide when a file must be
rotated.

The first is by size: when the log file grows more than a specified
size, then it's rotated.

The second constraint is with occurrences. If a L</DatePattern> is defined, a
file rotation ignores size constraint (unless C<check_both>) and uses the
defined date pattern constraints. When using L</DatePattern> make sure TZ is
defined correctly and that the TZ you use is understood by Date::Manip. We use
Date::Manip to generate our recurrences. Bad TZ equals bad recurrences equals
surprises! Read the L<Date::Manip> man page for more details on
TZ. L</DatePattern> will default to a daily rotate if your entered pattern is
incorrect. You will also get a warning message.

You can also check both constraints together by using the C<check_both>
parameter.

The latter constraint is a user callback. This function is called outside the
restricted area (see L</Concurrency>) and,
if it returns a true value, a rotation will happen unconditionally.

All check are made before logging. The C<rotate> method leaves us check these
constraints without logging anything.

To let more power at the user, a C<post_rotate> callback it'll call after every
rotation.

=head2 Concurrency

Multiple writers are allowed by this module. There is a restricted area where
only one writer can be inside. This is done by using an external lock file,
which name is "C<.filename.LCK>" (never deleted).

The user constraint and the L</DatePattern> constraint are checked outside this
restricted area. So, when you write a callback, don't rely on the logging
file because it can disappear under your feet.

Within this restricted area we:

=over 4

=item *

check the size constraint

=item *

eventually rotate the log file

=item *

if it's defined, call the C<post_rotate> function

=item *

write the log message

=back

=head1 METHODS

=head2 new(%p)

The constructor takes the following parameters in addition to parameters
documented in L<Log::Dispatch::File>:

=over 4

=item max ($)

The maximum number of log files to create. Default 1.

=item size ($)

The maximum (or close to) size the log file can grow too. Default 10M.

=item DatePattern ($)

The L</DatePattern> as defined above.

=item TZ ($)

The TimeZone time based calculations should be done in. This should match
L<Date::Manip>'s concept of timezones and of course your machines timezone.

=item check_both ($)

1 for checking L</DatePattern> and size concurrently, 0 otherwise.  Default 0.

=item user_constraint (\&)

If this callback is defined and returns true, a rotation will happen
unconditionally.

=item post_rotate (\&)

This callback is called after that all files were rotated. Will be called one
time for every rotated file (in reverse order) with this arguments:

=over 4

=item C<filename>

the path of the rotated file

=item C<index>

the index of the rotated file from C<max>-1 to 0, in the latter case
C<filename> is the new, empty, log file

=item C<fileRotate>

a object reference to this instance

=back

With this, you can have infinite files renaming each time the rotated file
log. E.g:

  my $file = Log::Dispatch::FileRotate
  ->new(
        ...
        post_rotate => sub {
          my ($filename, $idx, $fileRotate) = @_;
          if ($idx == 1) {
            use POSIX qw(strftime);
            my $basename = $fileRotate->filename();
            my $newfilename =
              $basename . '.' . strftime('%Y%m%d%H%M%S', localtime());
            $fileRotate->debug("moving $filename to $newfilename");
            rename($filename, $newfilename);
          }
        },
       );

B<Note>: this is called within the restricted area (see L</Concurrency>). This
means that any other concurrent process is locked in the meanwhile. For the
same reason, don't use the C<log()> or C<log_message()> methods because you
will get a deadlock!

=item DEBUG ($)

Turn on lots of warning messages to STDERR about what this module is
doing if set to 1. Really only useful to me.

=back

=head2 filename()

Returns the log filename.

=head2 setDatePattern( $ or [ $, $, ... ] )

Set a new suite of recurrances for file rotation. You can pass in a
single string or a reference to an array of strings. Multiple recurrences
can also be define within a single string by seperating them with a
semi-colon (;)

See the discussion above regarding the setDatePattern paramater for more
details.

=head2 log_message( message => $ )

Sends a message to the appropriate output.  Generally this shouldn't
be called directly but should be called through the C<log()> method
(in L<Log::Dispatch::Output>).

=head2 rotate()

Rotates the file, if it has to be done. You can call this method if you want to
check, and eventually do, a rotation without logging anything.

Returns 1 if a rotation was done, 0 otherwise. C<undef> on error.

=head2 debug($)

If C<DEBUG> is true, prints a standard warning message.

=head1 Tip

If you have multiple writers that were started at different times you
will find each writer will try to rotate the log file at a recurrence
calculated from its start time. To sync all the writers just use a config
file and update it after starting your last writer. This will cause
C<new()> to be called by each of the writers
close to the same time, and if your recurrences aren't too close together
all should sync up just nicely.

I initially assumed a long running process but it seems people are using
this module as part of short running CGI programs. So, now we look at the
last modified time stamp of the log file and compare it to a previous
occurance of a L</DatePattern>, on startup only. If the file stat shows
the mtime to be earlier than the previous recurrance then I rotate the
log file.

=head1 DatePattern

As I said earlier we use L<Date::Manip> for generating our recurrence
events. This means we can understand L<Date::Manip>'s recurrence patterns
and the normal log4j DatePatterns. We don't use DatePattern to define the
extension of the log file though.

DatePattern can therefore take forms like:

      Date::Manip style
            0:0:0:0:5:30:0       every 5 hours and 30 minutes
            0:0:0:2*12:30:0      every 2 days at 12:30 (each day)
            3*1:0:2:12:0:0       every 3 years on Jan 2 at noon

      DailyRollingFileAppender log4j style
            yyyy-MM              every month
            yyyy-ww              every week
            yyyy-MM-dd           every day
            yyyy-MM-dd-a         every day at noon
            yyyy-MM-dd-HH        every hour
            yyyy-MM-dd-HH-MM     every minute

To specify multiple recurrences in a single string separate them with a
semicolon:
        yyyy-MM-dd; 0:0:0:2*12:30:0

This says we want to rotate every day AND every 2 days at 12:30. Put in
as many as you like.

A complete description of L<Date::Manip> recurrences is beyond us here
except to quote (from the man page):

           A recur description is a string of the format
           Y:M:W:D:H:MN:S .  Exactly one of the colons may
           optionally be replaced by an asterisk, or an asterisk
           may be prepended to the string.

           Any value "N" to the left of the asterisk refers to
           the "Nth" one.  Any value to the right of the asterisk
           refers to a value as it appears on a calendar/clock.
           Values to the right can be listed a single values,
           ranges (2 numbers separated by a dash "-"), or a comma
           separated list of values or ranges.  In a few cases,
           negative values are appropriate.

           This is best illustrated by example.

             0:0:2:1:0:0:0        every 2 weeks and 1 day
             0:0:0:0:5:30:0       every 5 hours and 30 minutes
             0:0:0:2*12:30:0      every 2 days at 12:30 (each day)
             3*1:0:2:12:0:0       every 3 years on Jan 2 at noon
             0:1*0:2:12,14:0:0    2nd of every month at 12:00 and 14:00
             1:0:0*45:0:0:0       45th day of every year
             0:1*4:2:0:0:0        4th tuesday (day 2) of every month
             0:1*-1:2:0:0:0       last tuesday of every month
             0:1:0*-2:0:0:0       2nd to last day of every month

=head1 TODO

compression, signal based rotates, proper test suite

Could possibly use L<Logfile::Rotate> as well/instead.

=head1 SEE ALSO

=over 4

=item *

L<Log::Dispatch::File::Stamped>

Log directly to timestamped files.

=back

=head1 HISTORY

Originally written by Mark Pfeiffer, <markpf at mlp-consulting dot com dot au>
inspired by Dave Rolsky's, <autarch at urth dot org>, code :-)

Kevin Goess <cpan at goess dot org> suggested multiple writers should be
supported. He also conned me into doing the time based stuff.  Thanks Kevin!
:-)

Thanks also to Dan Waldheim for helping with some of the locking issues in a
forked environment.

And thanks to Stephen Gordon for his more portable code on lockfile naming.

=head1 SOURCE

The development version is on github at L<https://https://github.com/mschout/perl-log-dispatch-filerotate>
and may be cloned from L<git://https://github.com/mschout/perl-log-dispatch-filerotate.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-log-dispatch-filerotate/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Mark Pfeiffer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
