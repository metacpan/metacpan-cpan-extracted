package Log::Dispatch::FileRotate;
$Log::Dispatch::FileRotate::VERSION = '1.25';
# ABSTRACT: Log to Files that Archive/Rotate Themselves

require 5.005;
use strict;

use Log::Dispatch::Output;

use base qw( Log::Dispatch::Output );

use Log::Dispatch::File;   # We are a wrapper around Log::Dispatch::File

use Date::Manip;  # For time based recurring rotations
use File::Spec;   # For file-names

use Params::Validate qw(validate SCALAR BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );


sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

	$self->{'debug'} = 0;
    $self->_basic_init(%p);
    $self->{'LDF'} =  Log::Dispatch::File->new(%p);  # Our log
	$self->{'timer'} = sub { time() } unless defined $self->{'timer'};

	# Keep a copy of interesting stuff as well
	$self->{params} = \%p;

	# Turn ON/OFF debugging as required
	$p{'DEBUG'} ? $self->debug(1) : $self->debug(0);
	
	# Size defaults to 10meg in all failure modes, hopefully
	my $ten_meg = 1024*1024*10;
	my $two_gig = 1024*1024*1024*2;
	my $size = $ten_meg;
	if (defined $p{size}) {
		# allow perl-literal style nubers 10_000_000 -> 10000000
		$p{size} =~ s/_//g;
		$size = $p{size};
	}
	$size = $ten_meg unless $size =~ /^\d+$/ && $size < $two_gig && $size > 0;
	$self->{size} = $size;

	# Max number of files defaults to 1. No limit enforced here. Only
	# positive whole numbers allowed
	$self->{max}  = $p{max};
	$self->{max}  = 1 unless defined $self->{max} && $self->{max} =~ /^\d+$/ && $self->{max} > 0 ;

	# Get a name for our Lock file
	my $name = $self->{params}->{filename};
	my ($vol, $dir, $f) = File::Spec->splitpath($name);
	$dir = '.' unless $dir;
	$f = $name unless $f;

	my $lockfile = File::Spec->catpath($vol, $dir, ".".$f.".LCK");
	warn "Lock file is $lockfile\n" if $self->{'debug'};
	$self->{'lf'} = $lockfile;

	# Have we been called with a time based rotation pattern then setup
	# timebased stuff. TZ is important and must match current TZ or all
	# bets are off!
	if(defined $p{'TZ'})
	{
		# Date::Manip deprecated TZ= in 6.x.  In order to maintain backwards
		# compat with 5.8, we use TZ if setdate is not avilable.  Otherwise we
		# use setdate.
		require version;
		if (version->parse(DateManipVersion()) < version->parse('6.0'))
		{
			Date_Init("TZ=".$p{'TZ'});
		}
		else
		{
			# Date::Manip 6.x deprecates TZ, use  SetDate instead
			Date_Init("setdate=now,".$p{'TZ'});
		}
	}
	if(defined $p{'DatePattern'})
	{
		$self->setDatePattern($p{'DatePattern'});
	}

	# Flag this as first creation point
	$self->{'new'} = 1;

    return $self;
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
#			0:0:0:0:5:30:0       every 5 hours and 30 minutes
#			0:0:0:2*12:30:0      every 2 days at 12:30 (each day)
#			3*1:0:2:12:0:0       every 3 years on Jan 2 at noon
#
#	  DailyRollingFileAppender =>
#			yyyy-MM
#			yyyy-ww
#			yyyy-MM-dd
#			yyyy-MM-dd-a
#			yyyy-MM-dd-HH
#			yyyy-MM-dd-HH-MM
#
# To specify multiple recurances in a single string seperate them with a
# comma: yyyy-MM-dd,0:0:0:2*12:30:0
#
sub setDatePattern
{
    my $self = shift;        # My object
    my($arg) = shift;

	local($_);               # Don't crap on $_
	my @pats = ();

	my %lookup = (
		#					 Y:M:W:D:H:M:S
		'yyyy-mm'		=> 	'0:1*0:1:0:0:0',  # Every Month
		'yyyy-ww'		=> 	'0:0:1*0:0:0:0',  # Every week
		'yyyy-dd'		=> 	'0:0:0:1*0:0:0',  # Every day 
		'yyyy-mm-dd'	=> 	'0:0:0:1*0:0:0',  # Every day 
		'yyyy-dd-a'		=> 	'0:0:0:1*12:0:0', # Every day 12noon
		'yyyy-mm-dd-a'	=> 	'0:0:0:1*12:0:0', # Every day 12noon
		'yyyy-dd-hh'	=> 	'0:0:0:0:1*0:0',  # Every hour
		'yyyy-mm-dd-hh'	=> 	'0:0:0:0:1*0:0',  # Every hour
		'yyyy-dd-hh-mm'	=> 	'0:0:0:0:0:1*0',  # Every minute
		'yyyy-mm-dd-hh-mm'	=> 	'0:0:0:0:0:1*0',  # Every minute
	);

	# Convert arg to array
	if( ref($arg) eq 'ARRAY' )
	{
		@pats = @$arg;
	}
	elsif( !ref($arg) )
	{
		$arg =~ s/\s+//go;
		@pats = split(/;/,$arg);
	}
	else
	{
		die "Bad reference type argument ".ref($arg);
	}

	# Handle (possibly multiple) recurrances
	foreach my $pat (@pats)
	{
		# Convert any log4j patterns across
		if($pat =~ /^yyyy/i) # Then log4j style
		{
			$pat = lc($pat); # Use lowercase lookup
			# Default to daily on bad pattern
			unless(grep($pat eq $_,keys %lookup))
			{
				warn "Bad Rotation pattern ($pat) using yyyy-dd\n";
				$pat = 'yyyy-dd';
			}
			$pat = $lookup{$pat};
		}

		my $abs = $self->_get_next_occurance($pat);
		warn "Adding [dates,pat] =>[$abs,$pat]\n" if $self->{debug};
		my $ref = [$abs, $pat];
		push(@{$self->{'recurrance'}}, $ref);

	}

}



sub log_message
{
    my $self = shift;
    my %p = @_;

	my $max_size = $self->{size};
	my $numfiles = $self->{max};
	my $name     = $self->{params}->{filename};
	my $fh       = $self->{LDF}->{fh};

	# Prime our time based data outside the critical code area
	my ($in_time_mode,$time_to_rotate) = $self->time_to_rotate();

	# Handle critical code for logging. No changes if someone else is in
	if( !$self->lfhlock_test() )
	{
		warn "$$ waiting on lock\n" if $self->{debug};
		unless($self->lfhlock())
		{
			warn "$$ Log::Dispatch::FileRotate failed to get lock: ", $self->{_lfhlock_test_err}, ". Not logging.\n";
			return;
		}
		warn "$$ got lock after wait\n" if $self->{debug};
	}

	my $size   = (stat($fh))[7];   # Stat the handle to get real size
	my $inode  = (stat($fh))[1];   # get real inode
	my $finode = (stat($name))[1]; # Stat the name for comparision
	warn localtime()." $$  s=$size, i=$inode, f=".
			(defined $finode ? $finode : "undef") .
			 ", n=$name\n" if $self->{debug};

	# If finode and inode are the same then nobody has done a rename
	# under us and we can continue. Otherwise just close and reopen.
	# Time mode overrides Size mode
	if(!defined($finode) || $inode != $finode)
	{
		# Oops someone moved things on us. So just reopen our log
		delete $self->{LDF};  # Should get rid of current LDF
		$self->{LDF} =  Log::Dispatch::File->new(%{$self->{params}});  # Our log

		warn localtime()." $$ Someone else rotated: normal log\n" if $self->{debug};
		$self->logit($p{message});
	}
	elsif($in_time_mode && !$time_to_rotate)
	{
		warn localtime()." $$ In time mode: normal log\n" if $self->{debug};
		$self->logit($p{message});
	}
	elsif(!$in_time_mode && defined($size) && $size < $max_size )
	{
		warn localtime()." $$ In size mode: normal log\n" if $self->{debug};
		$self->logit($p{message});
	}
	# Need to rotate
	elsif(($in_time_mode && $time_to_rotate) || 
	      (!$in_time_mode && $size)
		 )
	{
		# Shut down the log
		delete $self->{LDF};  # Should get rid of current LDF

		my $idx = $numfiles -1;

		warn localtime() . " $$ Rotating\n" if $self->{debug};
		while($idx >= 0)
		{
			if($idx <= 0)
			{
				warn "$$ rename $name $name.1\n" if $self->{debug};
				rename($name, "$name.1");
			}
			else
			{
				warn "$$ rename $name.$idx $name.".($idx+1)."\n" if $self->{debug};
				rename("$name.$idx", "$name.".($idx+1));
			}

			$idx--;
		}
		warn localtime() . " $$ Rotating Done\n" if $self->{debug}; 

		# reopen the logfile for writing.
		$self->{LDF} =  Log::Dispatch::File->new(%{$self->{params}});  # Our log

		# Write it out
		warn localtime()." $$ rotated: normal log\n" if $self->{debug};
		$self->logit($p{message});
	}
	#else size is zero :-} just don't do anything!

	$self->lfhunlock();
}

sub DESTROY
{
    my $self = shift;

    if ( $self->{LDF} )
    {
		delete $self->{LDF};  # Should get rid of current LDF
    }

	# Clean up locks
	close $self->{lfh} if $self->{lfh};
 	unlink $self->{lf} if $self->{lf} && -f $self->{lf};
}

sub logit
{
	my $self = $_[0];

	$self->lock();
	$self->{LDF}->log_message(message => $_[1]);
	$self->unlock();
	return;
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
#	my ($in_time_mode,$time_to_rotate) = $self->time_to_rotate();
sub time_to_rotate
{
    my $self   = shift;        # My object
	my $mode   = defined($self->{'recurrance'});
	my $rotate = 0;

	if($mode)
	{
		# Then do some checking and update ourselves if we think we need
		# to rotate. Wether we rotate or not is up to our caller. We
		# assume they know what they are doing!

		# Only stat the log file here if we are in our first invocation.
		my $ftime = 0;
		if($self->{'new'})
		{
			# Last time the log file was changed
			$ftime   = (stat($self->{LDF}{fh}))[9];

			# In Date::Manip format
			# $ftime   = ParseDate(scalar(localtime($ftime)));
		}

		# Check need for rotation. Loop through our recurrances looking
		# for expiration times. Any we find that have expired we update.
		my $tm    = $self->{timer}->();
		my @recur = @{$self->{'recurrance'}};
		@{$self->{'recurrance'}} = ();
		for my $rec (@recur)
		{
			my ($abs,$pat) = @$rec;

			# Extra checking
			unless(defined $abs && $abs)
			{
				warn "Bad time found for recurrance pattern $pat: $abs\n";
				next;
			}
			my $dorotate = 0;

			# If this is first time through
			if($self->{'new'})
			{
				# If it needs a rotate then flag it
				if($ftime <= $abs)
				{
					# Then we need to rotate
					warn "Need rotate file($ftime) <= $abs\n" if $self->{debug};
					$rotate++;
					$dorotate++;  # Just for debugging
				}

				# Move to next occurance regardless
				warn "Dropping initial occurance($abs)\n" if $self->{debug};
				$abs = $self->_get_next_occurance($pat);
				unless(defined $abs && $abs)
				{
					warn "Next occurance is null for $pat\n";
					$abs = 0;
				}
			}
			# Elsif it is time to rotate
			#elsif(Date_Cmp($abs,$tm) <= 0)
			elsif($abs <= $tm)
			{
				# Then we need to rotate
				warn "Need rotate $abs <= $tm\n" if $self->{debug};
				$abs = $self->_get_next_occurance($pat);
				unless(defined $abs && $abs)
				{
					warn "Next occurance is null for $pat\n";
					$abs = 0;
				}
				$rotate++;
				$dorotate++;  # Just for debugging
			}
			push(@{$self->{'recurrance'}},[$abs,$pat]) if $abs;
			warn "time_to_rotate(mode,rotate,next) => ($mode,$dorotate,$abs)\n" if $self->{debug};
		}
		
	}

	$self->{'new'} = 0;  # No longer brand-spankers

	warn "time_to_rotate(mode,rotate) => ($mode,$rotate)\n" if $self->{debug};
	return wantarray ? ($mode,$rotate) : $rotate;
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
sub _gen_occurance
{
    my $self = shift;        # My object
    my $pat  = shift;

	# Do we return an initial occurance before the current time?
	my $initial = shift || 0;

	my $range = '';
	my $base  = 'now'; # default to calcs based on the current time

	if($pat =~ /^0:0:0:0:0/) # Small recurrance less than 1 hour
	{
		$range = "4 hours later";
		$base  = "1 hours ago" if $initial;
	}
	elsif($pat =~ /^0:0:0:0/) # recurrance less than 1 day
	{
		$range = "4 days later";
		$base  = "1 days ago" if $initial;
	}
	elsif($pat =~ /^0:0:0:/) #  recurrance less than 1 week
	{
		$range = "4 weeks later";
		$base  = "1 weeks ago" if $initial;
	}
	elsif($pat =~ /^0:0:/) #  recurrance less than 1 month
	{
		$range = "4 months later";
		$base  = "1 months ago" if $initial;
	}
	elsif($pat =~ /^0:/) #  recurrance less than 1 year
	{
		$range = "24 months later";
		$base  = "24 months ago" if $initial;
	}
	else # years
	{
		my($yrs) = $pat =~ m/^(\d+):/;
		$yrs = 1 unless $yrs;
		my $months = $yrs * 4 * 12;

		$range = "$months months later";
		$base  = "$months months ago" if $initial;
	}

	# The next date must start at least 1 second away from now other wise
	# we may rotate for every message we recieve with in this second :-(
	my $start = DateCalc($base,"+ 1 second");

	warn "ParseRecur($pat,$base,$start,$range);\n" if $self->{debug};
	my @dates = ParseRecur($pat,$base,$start,$range);

	# Just in case we have a bad parse or our assumptions are wrong.
	# We default to days
	unless(scalar @dates >= 2)
	{
		warn "Failed to parse ($pat). Going daily\n";
		@dates = ParseRecur('0:0:0:1*0:0:0',"now","now","1 months later");
		if($initial)
		{
			@dates = ParseRecur('0:0:0:1*0:0:0',"2 days ago","2 days ago","1 months later");
		}
	}

	# Convert the dates to seconds since the epoch so we can use
	# numerical comparision instead of textual
	my @epochs = ();
	my @a = ('%Y','%m','%d','%H','%M','%S');
	foreach(@dates)
	{
		my($y,$m,$d,$h,$mn,$s) = Date::Manip::UnixDate($_, @a);
		my $e = Date_SecsSince1970GMT($m,$d,$y,$h,$mn,$s);
		if( $self->{debug} )
		{
			warn "Date to epochs ($_) => ($e)\n";
		}
		push @epochs, $e;
	}

	# Clean out all but the one previous to now if we are doing an
	# initial occurance
	my $now = time();
	if($initial)
	{
		my $before = '';
		while(@epochs && ( $epochs[0] <= $now) )
		{
			$before = shift(@epochs);
			#warn "Shifting $before\n";
		}
		#warn "Unshifting $before\n";
		unshift(@epochs,$before) if $before;
	}
	else
	{
		# Clean out dates that occur before now, being careful not to loop
		# forever (thanks James).
		shift(@epochs) while @epochs && ( $epochs[0] <= $now);
	}

	if($self->{debug})
	{
		warn "Recurrances are at: ".join("\n\t", @dates),"\n";
	}
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
sub _get_next_occurance
{
    my $self = shift;        # My object
    my $pat  = shift;

	# (ms) Throw out expired occurances
	my $now = $self->{timer}->();
	if(defined $self->{'dates'}{$pat})
	{
		while( @{$self->{'dates'}{$pat}} )
		{
			last if $self->{'dates'}{$pat}->[0] >= $now;
			shift @{$self->{'dates'}{$pat}};
		}
	}

	# If this is first time then generate some new ones including one
	# before our time to test against the log file
	if(!defined $self->{'dates'}{$pat})
	{
		@{$self->{'dates'}{$pat}} = $self->_gen_occurance($pat,1);
	}
	# Elsif close to the end of what we have
	elsif( scalar(@{$self->{'dates'}{$pat}}) < 2)
	{
		@{$self->{'dates'}{$pat}} = $self->_gen_occurance($pat);
	}
	
	return( shift(@{$self->{'dates'}{$pat}}) );
}


# Lock and unlock routines. For when we need to write a message.
use Fcntl ':flock'; # import LOCK_* constants

sub lock 
{
	my $self = shift;

	flock($self->{LDF}->{fh},LOCK_EX);

	# Make sure we are at the EOF
	seek($self->{LDF}->{fh}, 0, 2);

	warn localtime() ." $$ Locked\n" if $self->{debug};
	return;
}

sub unlock 
{
	my $self = shift;
	flock($self->{LDF}->{fh},LOCK_UN);
	warn localtime() . " $$ unLocked\n" if $self->{debug};
}

# Lock and unlock routines. For when we need to roll the logs.
#
# Note: On May 1, Dan Waldheim's good news was:
# I discovered something interesting about forked processes and locking.
# If the parent "open"s the filehandle and then forks, exclusive locks
# don't work properly between the parent and children.  Anyone can grab a
# lock while someone else thinks they have it.  To work properly the
# "open" has to be done within each process.
#
# Thanks Dan
sub lfhlock_test 
{
	my $self = shift;

	if (open(LFH, ">>$self->{lf}"))
	{
		$self->{lfh} = *LFH;
		if (flock($self->{lfh}, LOCK_EX | LOCK_NB))
		{
			warn "$$ got lock on Lock File ".$self->{lfh}."\n" if $self->{debug};
			return 1;
		}
	}
	else
	{
		$self->{_lfhlock_test_err} = "couldn't lock $self->{lf}: $!";
		$self->{lfh} = 0;
		warn "$$ couldn't get lock on Lock File\n" if $self->{debug};
		return 0;
	}
}

sub lfhlock
{
	my $self = shift;

	if (!$self->{lfh})
	{
		if (!open(LFH, ">>$self->{lf}"))
		{
			return 0;
		}
		$self->{lfh} = *LFH;
	}

	flock($self->{lfh},LOCK_EX);
}

sub lfhunlock 
{
	my $self = shift;

	if($self->{lfh})
	{
		flock($self->{lfh},LOCK_UN);
		close $self->{lfh};
		$self->{lfh} = 0;
	}
}

sub debug
{
	$_[0]->{'debug'} = $_[1];
}

__END__

=pod

=head1 NAME

Log::Dispatch::FileRotate - Log to Files that Archive/Rotate Themselves

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  use Log::Dispatch::FileRotate;

  my $file = Log::Dispatch::FileRotate->new(
      filename  => 'file1',
      min_level => 'info',
      filename  => 'Somefile.log',
      mode      => 'append' ,
      size      => 10*1024*1024,
      max       => 6);

  # or for a time based rotation

  my $file = Log::Dispatch::FileRotate->new(
      filename  => 'file1',
      min_level => 'info',
      filename  => 'Somefile.log',
      mode      => 'append' ,
      TZ        => 'AEDT',
      DatePattern => 'yyyy-dd-HH');

  $file->log( level => 'info', message => "your comment\n" );

=head1 DESCRIPTION

This module provides a simple object for logging to files under the
Log::Dispatch::* system, and automatically rotating them according to
different constraints. This is basically a Log::Dispatch::File wrapper
with additions. To that end the arguments

	name, min_level, filename and  mode

behave the same as Log::Dispatch::File. So see its man page 
(perldoc Log::Dispatch::File)

The arguments size and max specify the maximum size and maximum
number of log files created. The size defaults to 10M and the max number
of files defaults to 1. If DatePattern is not defined then we default to
working in size mode. That is, use size values for deciding when to rotate.

Once DatePattern is defined FileRotate will move into time mode. Once
this happens file rotation ignores size constraints and uses the defined
date pattern constraints.

If you setup a config file using Log::Log4perl::init_and_watch() or the
like, you can switch between modes just by commenting out the DatePattern
line.

When using DatePattern make sure TZ is defined correctly and that the TZ
you use is understood by Date::Manip. We use Date::Manip to generate our
recurrences. Bad TZ equals bad recurrences equals surprises! Read the
Date::Manip man page for more details on TZ.

DatePattern will default to a daily rotate if your entered pattern is
incorrect. You will also get a warning message.

If you have multiple writers that were started at different times you
will find each writer will try to rotate the log file at a recurrence
calculated from its start time. To sync all the writers just use a config
file and update it after starting your last writer. This will cause
Log::Dispatch::FileRotate->new() to be called by each of the writers
close to the same time, and if your recurrences aren't too close together
all should sync up just nicely.

I initially assumed a long running process but it seems people are using
this module as part of short running CGI programs. So, now we look at the
last modified time stamp of the log file and compare it to a previous
occurance of a DatePattern, on startup only. If the file stat shows
the mtime to be earlier than the previous recurrance then I rotate the
log file.

We handle multiple writers using flock().

=head1 METHODS

=head2 new(%p)

This method takes a hash of parameters.  The following options are
valid:

=over 4

=item -- name ($)

The name of the object (not the filename!).  Required.

=item -- size ($)

The maximum (or close to) size the log file can grow too.

=item -- max ($)

The maximum number of log files to create.

=item -- TZ ($)

The TimeZone time based calculations should be done in. This should match
Date::Manip's concept of timezones and of course your machines timezone.

=item -- DatePattern ($)

The DatePattern as defined above.

=item -- min_level ($)

The minimum logging level this object will accept.  See the
Log::Dispatch documentation for more information.  Required.

=item -- max_level ($)

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=item -- filename ($)

The filename to be opened for writing. This is the base name. Rotated log
files will be renamed filename.1 thru to filename.C<max>. Where max is the
paramater defined above.

=item -- mode ($)

The mode the file should be opened with.  Valid options are 'write',
'>', 'append', '>>', or the relevant constants from Fcntl.  The
default is 'write'.

=item -- autoflush ($)

Whether or not the file should be autoflushed.  This defaults to true.

=item -- callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references.  These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a
single scalar containing that modified message.  These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once.

=item -- DEBUG ($)

Turn on lots of warning messages to STDERR about what this module is
doing if set to 1. Really only useful to me.

=back

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
(in Log::Dispatch::Output).

=head1 DatePattern

As I said earlier we use Date::Manip for generating our recurrence
events. This means we can understand Date::Manip's recurrence patterns
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

A complete description of Date::Manip recurrences is beyond us here
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

Could possibly use Logfile::Rotate as well/instead.

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

The development version is on github at L<http://github.com/mschout/perl-log-dispatch-filerotate>
and may be cloned from L<git://github.com/mschout/perl-log-dispatch-filerotate.git>

=head1 BUGS

Please report any bugs or feature requests to bug-log-dispatch-filerotate@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-FileRotate

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Mark Pfeiffer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
