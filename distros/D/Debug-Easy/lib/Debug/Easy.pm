package Debug::Easy 2.21;

use strict;
# use warnings;
use constant {
    TRUE  => 1,
    FALSE => 0,
};

use Config;
use Term::ANSIColor;
use Time::HiRes qw(time);
use File::Basename qw(fileparse);

use Data::Dumper;    # Included in Perl
eval {               # Data::Dumper::Simple is preferred.  Try to load it without dying.
    require Data::Dumper::Simple;
    Data::Dumper::Simple->import();
    1;
};

use if ($Config{'useithreads'}), 'threads';

BEGIN {
    require Exporter;

    # Inherit from Exporter to export functions and variables
    our @ISA = qw(Exporter);

    # Functions and variables which are exported by default
    our @EXPORT = qw();

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw(fileparse @Levels);
} ## end BEGIN

# This can be optionally exported for whatever
our @Levels = qw( ERR WARN NOTICE INFO VERBOSE DEBUG DEBUGMAX );

# For quick level checks to speed up execution
our %LevelLogic;
for (my $count = 0; $count < scalar(@Levels); $count++) {
    $LevelLogic{ $Levels[$count] } = $count;
}

our $PARENT = $$;    # This needs to be defined at the very beginning before new
our ($SCRIPTNAME, $SCRIPTPATH, $suffix) = fileparse($0);
# our @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
# our @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

=encoding utf8

=head1 NAME

Debug::Easy - A Handy Debugging Module With Colorized Output and Formatting

=head1 SYNOPSIS

 use Debug::Easy;

 my $debug = Debug::Easy->new( 'LogLevel' => 'DEBUG', 'Color' => 1 );

'LogLevel' is the maximum level to report, and ignore the rest.  The method names correspond to their loglevels, when outputting a specific message.  This identifies to the module what type of message [...]

The following is a list, in order of level, of the logging methods:

 ERR       = Error
 WARN      = Warning
 NOTICE    = Notice
 INFO      = Information
 VERBOSE   = Special version of INFO that does not output any
             Logging headings.  Very useful for verbose modes in your
             scripts.
 DEBUG     = Level 1 Debugging messages
 DEBUGMAX  = Level 2 Debugging messages (typically more terse like dumping
               variables)

The parameter is either a string or a reference to an array of strings to output as multiple lines.

Each string can contain newlines, which will also be split into a separate line and formatted accordingly.

 $debug->ERR(        ['Error message']);
 $debug->ERROR(      ['Error message']);

 $debug->WARN(       ['Warning message']);
 $debug->WARNING(    ['Warning message']);

 $debug->NOTICE(     ['Notice message']);
 $debug->INFO(       ['Information and VERBOSE mode message']);
 $debug->INFORMATION(['Information and VERBOSE mode message']);

 $debug->DEBUG(      ['Level 1 Debug message']);
 $debug->DEBUGMAX(   ['Level 2 (terse) Debug message']);

 my @messages = (
    'First Message',
    'Second Message',
    "Third Message First Line\nThird Message Second Line",
    \%hash_reference
 );

 $debug->INFO([\@messages]);

=head1 DESCRIPTION

This module makes it easy to add debugging features to your code, Without having to re-invent the wheel.  It uses STDERR and ANSI color formatted text output, as well as indented and multiline text fo [...]

Benchmarking is automatic, to make it easy to spot bottlenecks in code.  It automatically stamps from where it was called, and makes debug coding so much easier, without having to include the location [...]

It also allows multiple output levels from errors only, to warnings, to notices, to verbose information, to full on debug output.  All of this fully controllable by the coder.

Generally all you need are the defaults and you are ready to go.

=head1 B<EXPORTABLE VARIABLES>

=head2 B<@Levels>

 A simple list of all the acceptable debug levels to pass as "LogLevel" in the {new} method.  Not normally needed for coding, more for reference.  Only exported if requested.

=cut

sub DESTROY {    # We spit out one last message before we die, the total execute time.
    my $self  = shift;
    my $bench = (! $self->{'COLOR'})
        ? sprintf('%06.2f', (time - $self->{'MASTERSTART'}))
        : colored(['bright_cyan'], sprintf('%06.2f', (time - $self->{'MASTERSTART'})));
    my $name  = $SCRIPTNAME;
    $name .= ' [child]' if ($PARENT ne $$);
    unless ($self->{'COLOR'}) {
        $self->DEBUG(["$bench ---- $name complete ----"]);
    } else {
        $self->DEBUG([$bench . ' ' . colored(['black on_white'], "---- $name complete ----")]);
    }
} ## end sub DESTROY

=head1 B<METHODS>

=head2 B<new>

* The parameter names are case insensitive as of Version 0.04.

=over 4

=item B<LogLevel> [level]

This adjusts the global log level of the Debug object.  It requires a string.

=back

=over 8

B<ERR> (default)

 This level shows only error messages and all other messages are not shown.

B<WARN>

 This level shows error and warning messages.  All other messages are not shown.

B<NOTICE>

 This level shows error, warning, and notice messages.  All other messages are not shown.

B<INFO>

 This level shows error, warning, notice, and information messages.  Only debug level messages are not shown.

B<VERBOSE>

 This level can be used as a way to do "Verbose" output for your scripts.  It ouputs INFO level messages without logging headers and on STDOUT instead of STDERR.

B<DEBUG>

 This level shows error, warning, notice, information, and level 1 debugging messages.  Level 2 Debug messages are not shown.

B<DEBUGMAX>

 This level shows all messages up to level 2 debugging messages.

 NOTE:  It has been asked "Why have two debugging levels?"  Well, I have had many times where I would like to see what a script is doing without it showing what I consider garbage overhead it may gene [...]

=back

=over 4

=item B<Color> [boolean] (Not case sensitive)

B<0>, B<Off>, or B<False> (Off)

  This turns off colored output.  Everything is plain text only.

B<1>, B<On>, or B<True> (On - Default)

  This turns on colored output.  This makes it easier to spot all of the different types of messages throughout a sea of debug output.  You can read the output with "less", and see color, by using it' [...]

=back

=over 4

=item B<Prefix> [pattern]

This is global

A string that is parsed into the output prefix.

DEFAULT:  '%Date% %Time% %Benchmark% %Loglevel%[%Subroutine%][%Lastline%] '

 %Date%       = Date (Uses format of "DateStamp" below)
 %Time%       = Time (Uses format of "TimeStamp" below)
 %Epoch%      = Epoch (Unix epoch)
 %Benchmark%  = Benchmark - The time it took between the last benchmark display
                of this loglevel.  If in an INFO level message, it benchmarks
                the time until the next INFO level message.  The same rule is
                true for all loglevels.
 %Loglevel%   = Log Level
 %Lines%      = Line Numbers of all nested calls
 %Module%     = Module and subroutine of call (can be a lot of stuff!)
 %Subroutine% = Just the last subroutine
 %Lastline%   = Just the last line number
 %PID%        = Process ID
 %date%       = Just Date (typically used internally only, use %Date%)
 %time%       = Just time (typically used internally only, use %Time%)
 %epoch%      = Unix epoch (typically used internally only, use %Epoch%)
 %Filename%   = Script Filename (parsed $0)
 %Fork%       = Running in parent or child?
     P = Parent
     C = Child
 %Thread%     = Running in Parent or Thread
     P   = Parent
     T## = Thread # = Thread ID

=item B<[loglevel]-Prefix> [pattern]

You can define a prefix for a specific log level.

 ERR-Prefix
 WARN-Prefix
 NOTICE-Prefix
 INFO-Prefix
 DEBUG-Prefix
 DEBUGMAX-Prefix

If one of these are not defined, then the global value is used.

=item B<TimeStamp> [pattern]

(See Log::Fast for specifics on these)

I suggest you just use Prefix above, but here it is anyway.

Make this an empty string to turn it off, otherwise:

=back

=over 8

B<%T>

 Formats the timestamp as HH:MM:SS.  This is the default for the timestamp.

B<%S>

 Formats the timestamp as seconds.milliseconds.  Normally not needed, as the benchmark is more helpful.

B<%T %S>

 Combines both of the above.  Normally this is just too much, but here if you really want it.

=back

=over 4

=item B<DateStamp> [pattern]

I suggest you just use Prefix above, but here it is anyway.

Make this an empty string to turn it off, otherwise:

=back

=over 8

B<%D>

 Formats the datestamp as YYYY-MM-DD.  It is the default, and the only option.

=back

=over 4

=item B<FileHandle>

 File handle to write log messages.

=item B<ANSILevel>

 Contains a hash reference describing the various colored debug level labels

 The default definition (using Term::ANSIColor) is as follows:

=back

=over 8

  'ANSILevel' => {
     'ERR'      => colored(['white on_red'],        '[ ERROR  ]'),
     'WARN'     => colored(['black on_yellow'],     '[WARNING ]'),
     'NOTICE'   => colored(['yellow'],              '[ NOTICE ]'),
     'INFO'     => colored(['black on_white'],      '[ INFO   ]'),
     'DEBUG'    => colored(['bold green'],          '[ DEBUG  ]'),
     'DEBUGMAX' => colored(['bold black on_green'], '[DEBUGMAX]'),
  }

=back

=cut

sub new {
    my $class = shift;
    my ($filename, $dir, $suffix) = fileparse($0);
    my $tm   = time;
    my $self = {
        'LogLevel'           => 'ERR',                                                                    # Default is errors only
        'Type'               => 'fh',                                                                     # Default is a filehandle
        'Path'               => '/var/log',                                                               # Default path should type be unix
        'FileHandle'         => \*STDERR,                                                                 # Default filehandle is STDERR
        'MasterStart'        => $tm,
        'ANY_LastStamp'      => $tm,                                                                      # Initialize main benchmark
        'ERR_LastStamp'      => $tm,                                                                      # Initialize the ERR benchmark
        'WARN_LastStamp'     => $tm,                                                                      # Initialize the WARN benchmark
        'INFO_LastStamp'     => $tm,                                                                      # Initialize the INFO benchmark
        'NOTICE_LastStamp'   => $tm,                                                                      # Initialize the NOTICE benchmark
        'DEBUG_LastStamp'    => $tm,                                                                      # Initialize the DEBUG benchmark
        'DEBUGMAX_LastStamp' => $tm,                                                                      # Initialize the DEBUGMAX benchmark
        'Color'              => TRUE,                                                                     # Default to colorized output
        'DateStamp'          => colored(['yellow'], '%date%'),
        'TimeStamp'          => colored(['yellow'], '%time%'),
        'Epoch'              => colored(['cyan'],   '%epoch%'),
        'Padding'            => -20,                                                                      # Default padding is 20 spaces
        'Lines-Padding'      => -2,
        'Subroutine-Padding' =>  0,
        'Line-Padding'       =>  0,
        'PARENT'             => $$,
        'Prefix'             => '%Date% %Time% %Benchmark% %Loglevel%[%Subroutine%][%Lastline%] ',
        'DEBUGMAX-Prefix'    => '%Date% %Time% %Benchmark% %Loglevel%[%Module%][%Lines%] ',
        'Filename'           => '[' . colored(['magenta'], $filename) . ']',
#        'TIMEZONE'           => DateTime::TimeZone->new(name => 'local'),
#        'DATETIME'           => DateTime->now('time_zone' => DateTime::TimeZone->new(name => 'local')),
        'ANSILevel'          => {
            'ERR'      => colored(['white on_red'],        '[ ERROR  ]'),
            'WARN'     => colored(['black on_yellow'],     '[WARNING ]'),
            'NOTICE'   => colored(['yellow'],              '[ NOTICE ]'),
            'INFO'     => colored(['black on_white'],      '[  INFO  ]'),
            'DEBUG'    => colored(['bold green'],          '[ DEBUG  ]'),
            'DEBUGMAX' => colored(['bold black on_green'], '[DEBUGMAX]'),
        },
    };

    # This pretty much makes all hash keys uppercase
    my @Keys = (keys %{$self});    # Hash is redefined on the fly, so get the list before
    foreach my $Key (@Keys) {
        my $upper = uc($Key);
        if ($Key ne $upper) {
            $self->{$upper} = $self->{$Key};

            # This fixes a documentation error for past versions
            if ($upper eq 'LOGLEVEL') {
                $self->{$upper} = 'ERR' if ($self->{$upper} =~ /^ERROR$/i);
                $self->{$upper} = uc($self->{$upper});                        # Make loglevels case insensitive
            }
            delete($self->{$Key});                                            # Get rid of the bad key
        } elsif ($Key eq 'LOGLEVEL') {    # Make loglevels case insensitive
            $self->{$upper} = uc($self->{$upper});
        }
    } ## end foreach my $Key (@Keys)
    {                                     # This makes sure the user overrides actually override
        my %params = (@_);
        foreach my $Key (keys %params) {
            $self->{ uc($Key) } = $params{$Key};
        }
    }

    # Cache numeric log level value for quick comparisons
    $self->{'LOGLEVEL_VALUE'} = $LevelLogic{ $self->{'LOGLEVEL'} };

    # Cache thread support check for hot path
    my $use_threads = ($Config{'useithreads'} && eval { require threads; 1 }) ? 1 : 0;
    $self->{'USE_THREADS'} = $use_threads;

    # This instructs the ANSIColor library to turn off coloring,
    # if the Color attribute is set to zero.
    unless ($self->{'COLOR'}) {
#        local $ENV{'ANSI_COLORS_DISABLED'} = TRUE; # Only this module should be set

        # If COLOR is FALSE, then clear color data from ANSILEVEL, as these were
        # defined before color was turned off.
        $self->{'ANSILEVEL'} = {
            'ERR'      => '[ ERROR  ]',
            'WARN'     => '[WARNING ]',
            'NOTICE'   => '[ NOTICE ]',
            'INFO'     => '[  INFO  ]',
            'DEBUG'    => '[ DEBUG  ]',
            'DEBUGMAX' => '[DEBUGMAX]',
        };
        $self->{'DATESTAMP'} = '%date%';
        $self->{'TIMESTAMP'} = '%time%';
        $self->{'EPOCH'}     = '%epoch%';
        $self->{'FILENAME'}  = '[' . $filename . ']'; # Ensure filename without color
    }

    foreach my $lvl (@Levels) {
        $self->{"$lvl-PREFIX"} = $self->{'PREFIX'} unless (exists($self->{"$lvl-PREFIX"}) && defined($self->{"$lvl-PREFIX"}));
    }

    # Precompute static prefix templates per level to minimize per-line substitutions.
    # We will leave dynamic tokens (%date%, %time%, %epoch%, %Benchmark%) for runtime.
    $self->{'_PREFIX_TEMPLATES'} = {};
    foreach my $lvl (@Levels) {
        my $tmpl = $self->{"$lvl-PREFIX"} . ''; # copy
        my $forked   = ($PARENT ne $$) ? 'C' : 'P';
        my $threaded = 'PT-';
        if ($self->{'USE_THREADS'}) {
            my $tid = threads->can('tid') ? threads->tid() : 0;
            $threaded = ($tid && $tid > 0) ? sprintf('T%02d', $tid) : 'PT-';
        }

        # Static substitutions
        $tmpl =~ s/\%PID\%/$$/gi;
        $tmpl =~ s/\%Loglevel\%/$self->{'ANSILEVEL'}->{$lvl}/gi;
        $tmpl =~ s/\%Filename\%/$self->{'FILENAME'}/gi;
        $tmpl =~ s/\%Fork\%/$forked/gi;
        $tmpl =~ s/\%Thread\%/$threaded/gi;

        # Leave dynamic tokens for runtime:
        # %Lines%, %Lastline%, %Subroutine%, %Module% (caller-dependent)
        # %Date%, %Time%, %Epoch% (colorized stamp placeholders)
        # %date%, %time%, %epoch% (raw values)
        # %Benchmark%

        $self->{'_PREFIX_TEMPLATES'}->{$lvl} = $tmpl;
    }

    my $fh = $self->{'FILEHANDLE'};

    # Signal the script has started (and logger initialized)
    my $name = $SCRIPTNAME;
    $name .= ' [child]' if ($PARENT ne $$);
    my $string = (! $self->{'COLOR'}) ? "----- $name begin -----" : colored(['black on_white'], "----- $name begin -----");
    print $fh sprintf('   %.02f%s %s%s', 0, $self->{'ANSILEVEL'}->{'DEBUG'}, $string, " (To View in 'less', use it's '-r' switch)"), "\n" if ($self->{'LOGLEVEL'} !~ /ERR/);

    bless($self, $class);
    return ($self);
} ## end sub new

=head2 debug

NOTE:  This is a legacy method for backwards compatibility.  Please use the direct methods instead.

The parameters must be passed in the order given

=over 4

=item B<LEVEL>

 The log level with which this message is to be triggered

=item B<MESSAGE(S)>

 A string or a reference to a list of strings to output line by line.

=back

=cut

sub debug {
    my $self  = shift;
    my $level = uc(shift);
    my $msgs  = shift;

    if ($level !~ /ERR.*|WARN.*|NOTICE|INFO.*|DEBUG/i) {    # Compatibility with older versions.
        $level = uc($msgs);                                 # It tosses the legacy __LINE__ argument
        $msgs  = shift;
    }
    $level =~ s/(OR|ING|RMATION)$//;                        # Strip off the excess

    # A much quicker bypass when the log level is below what is needed
    # This minimizes the execution overhead for log levels not active.
    return if ($self->{'LOGLEVEL_VALUE'} < $LevelLogic{$level});

    my @messages;
    if (ref($msgs) eq 'SCALAR' || ref($msgs) eq '') {
        push(@messages, $msgs);
    } elsif (ref($msgs) eq 'ARRAY') {
        @messages = @{$msgs};
    } else {
        push(@messages, Dumper($msgs));
    }
    my ($sname, $cline, $nested, $subroutine, $thisBench, $thisBench2, $sline, $short) = ('', '', '', '', '', '', '', '');
    # Set up dumper variables for friendly output

    local $Data::Dumper::Terse         = TRUE;
    local $Data::Dumper::Indent        = TRUE;
    local $Data::Dumper::Useqq         = TRUE;
    local $Data::Dumper::Deparse       = TRUE;
    local $Data::Dumper::Quotekeys     = TRUE;
    local $Data::Dumper::Trailingcomma = TRUE;
    local $Data::Dumper::Sortkeys      = TRUE;
    local $Data::Dumper::Purity        = TRUE;

    # Figure out the proper caller tree and line number ladder
    # But only if it's part of the effective level prefix, else don't waste time.
    my $effective_prefix = $self->{ $level . '-PREFIX' } || $self->{'PREFIX'};
    if ($effective_prefix =~ /\%(Subroutine|Module|Lines|Lastline)\%/i) {    # %P = Subroutine, %l = Line number(s)
        my $package = '';
        my $count   = 1;
        my $nest    = 0;
        while (my @array = caller($count)) {
            if ($array[3] !~ /Debug::Easy/) {
                $package = $array[0];
                my $subroutine = $array[3];
                $subroutine =~ s/^$package\:\://;
                $sname      =~ s/$subroutine//;
                if ($sname eq '') {
                    $sname = ($subroutine ne '') ? $subroutine : $package;
                    $cline = $array[2];
                } else {
                    $sname = $subroutine . '::' . $sname;
                    $cline = $array[2] . '/' . $cline;
                }
                if ($count == 2) {
                    $short = $array[3];
                    $sline = $array[2];
                }
                $nest++;
            } ## end if ($array[3] !~ /Debug::Easy/)
            $count++;
        } ## end while (my @array = caller...)
        if ($package ne '') {
            $sname  = $package . '::' . $sname;
            $nested = ' ' x $nest if ($nest);
        } else {
            my @array = caller(1);
            $cline = $array[2];
            if (!defined($cline) || $cline eq '') {
                @array = caller(0);
                $cline = $array[2];
            }
            $sname = 'main';
            $sline = $cline;
            $short = $sname;
        } ## end else [ if ($package ne '') ]
        $subroutine                   = ($sname ne '') ? $sname : 'main';
        $self->{'PADDING'}            = 0 - length($subroutine) if (length($subroutine) > abs($self->{'PADDING'}));
        $self->{'LINES-PADDING'}      = 0 - length($cline)      if (length($cline) > abs($self->{'LINES-PADDING'}));
        $self->{'SUBROUTINE-PADDING'} = 0 - length($short)      if (length($short) > abs($self->{'SUBROUTINE-PADDING'}));
        $self->{'LINE-PADDING'}       = 0 - length($sline)      if (length($sline) > abs($self->{'LINE-PADDING'}));
        $cline                        = sprintf('%' . $self->{'LINES-PADDING'} . 's', $cline);
        $subroutine                   = (! $self->{'COLOR'}) ? sprintf('%' . $self->{'PADDING'} . 's', $subroutine) : colored(['bold cyan'], sprintf('%' . $self->{'PADDING'} . 's', $subroutine));
        $sline                        = sprintf('%' . $self->{'LINE-PADDING'} . 's', $sline);
        $short                        = (! $self->{'COLOR'}) ? sprintf('%' . $self->{'SUBROUTINE-PADDING'} . 's', $short) : colored(['bold cyan'], sprintf('%' . $self->{'SUBROUTINE-PADDING'} . 's', $short));
    } ## end if ($effective_prefix ...)

    # Figure out the benchmarks, but only if it is in the prefix
    if ($effective_prefix =~ /\%Benchmark\%/i) {

        # For multiline output, only output the bench data on the first line.  Use padded spaces for the rest.
        $thisBench  = sprintf('%7s', sprintf(' %.02f', time - $self->{'ANY_LASTSTAMP'}));
        $thisBench2 = ' ' x length($thisBench);
    } ## end if ($effective_prefix ...)
    my $first = TRUE;                # Set the first line flag.

    # Buffer lines to reduce syscalls for multi-line messages
    my $buffer = '';

    foreach my $msg (@messages) {    # Loop through each line of output and format accordingly.
        if (ref($msg) ne '') {
            $msg = Dumper($msg);
        }
        if ($msg =~ /\n/s) {         # If the line contains newlines, then it too must be split into multiple lines.
            my @message = split(/\n/, $msg);
            foreach my $line (@message) {    # Loop through the split lines and format accordingly.
                $buffer .= $self->_format_line($level, $nested, $line, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $short);
                $buffer .= "\n";
                $first = FALSE;              # Clear the first line flag.
            }
        } else {    # This line does not contain newlines.  Treat it as a single line.
            $buffer .= $self->_format_line($level, $nested, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $short);
            $buffer .= "\n";
        }
        $first = FALSE;    # Clear the first line flag.
    } ## end foreach my $msg (@messages)

    my $fh = $self->{'FILEHANDLE'};
    if ($level eq 'INFO' && $self->{'LOGLEVEL'} eq 'VERBOSE') {    # Trap verbose flag and temporarily drop the prefix.
        # For verbose, we need to print messages without prefixes.
        # Extract lines and print only message contents.
        foreach my $msg (@messages) {
            if (ref($msg) ne '') {
                $msg = Dumper($msg);
            }
            if ($msg =~ /\n/s) {
                my @message = split(/\n/, $msg);
                foreach my $line (@message) {
                    print $fh "$line\n";
                }
            } else {
                print $fh "$msg\n";
            }
        }
    } elsif ($level eq 'DEBUGMAX') {                               # Special version of DEBUG.  Extremely verbose debugging and quite noisy
        if ($self->{'LOGLEVEL'} eq 'DEBUGMAX') {
            print $fh $buffer;
        }
    } else {
        print $fh $buffer;
    }

    $self->{'ANY_LASTSTAMP'} = time;
    $self->{ $level . '_LASTSTAMP' } = time;
} ## end sub debug

# Internal: format a single line for logging (without printing)
sub _format_line {
    my ($self, $level, $padding, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $shortsub) = @_;

    # Build prefix based on precomputed template and runtime substitutions
    my $tmpl = $self->{'_PREFIX_TEMPLATES'}->{$level};
    $tmpl = $self->{"$level-PREFIX"} . '' unless defined $tmpl; # Fallback safety

    # Clone template since we mutate
    my $prefix = $tmpl . '';

    # Apply caller-derived fields only if present in the effective level prefix
    if ($prefix =~ /\%Lines\%/i)     { $prefix =~ s/\%Lines\%/$cline/gi; }
    if ($prefix =~ /\%Lastline\%/i)  { $prefix =~ s/\%Lastline\%/$sline/gi; }
    if ($prefix =~ /\%Subroutine\%/i){ $prefix =~ s/\%Subroutine\%/$shortsub/gi; }
    if ($prefix =~ /\%Module\%/i)    { $prefix =~ s/\%Module\%/$subroutine/gi; }

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
#    my $timezone = $self->{'TIMEZONE'} || DateTime::TimeZone->new(name => 'local');
#    my $dt       = $self->{'DATETIME'};
#    my $Date     = sprintf('%02d %03s %03s, %04d', $mday, $months[$mon], $days[$wday], (1900 + $year));
    my $Date     = sprintf('%02d/%02d/%04d', $mday, ($mon + 1), (1900 + $year));
    my $Time     = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
    my $epoch    = time;

    # Apply dynamic tokens
    if ($first) {
        $prefix =~ s/\%Benchmark\%/$thisBench/gi;
    } else {
        $prefix =~ s/\%Benchmark\%/$thisBench2/gi;
    }
    $prefix =~ s/\%Date\%/$self->{'DATESTAMP'}/gi;
    $prefix =~ s/\%Time\%/$self->{'TIMESTAMP'}/gi;
    $prefix =~ s/\%Epoch\%/$self->{'EPOCH'}/gi;
    $prefix =~ s/\%date\%/$Date/gi;
    $prefix =~ s/\%time\%/$Time/gi;
    $prefix =~ s/\%epoch\%/$epoch/gi;

    return "$prefix$padding$msg";
}

sub _send_to_logger {    # Legacy path: retained for backward compatibility but routed via _format_line
    my ($self, $level, $padding, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $shortsub) = @_;

    my $fh = $self->{'FILEHANDLE'};
    if ($level eq 'INFO' && $self->{'LOGLEVEL'} eq 'VERBOSE') {    # Trap verbose flag and temporarily drop the prefix.
        print $fh "$msg\n";
    } elsif ($level eq 'DEBUGMAX') {                               # Special version of DEBUG.  Extremely verbose debugging and quite noisy
        if ($self->{'LOGLEVEL'} eq 'DEBUGMAX') {
            my $line = $self->_format_line($level, $padding, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $shortsub);
            print $fh "$line\n";
        }
    } else {
        my $line = $self->_format_line($level, $padding, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $shortsub);
        print $fh "$line\n";
    }
} ## end sub _send_to_logger

=head2 B<ERR> or B<ERROR>

Sends ERROR level debugging output to the log.  Errors are always shown.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub ERR {
    my $self = shift;
    $self->debug('ERR', @_);
}

sub ERROR {
    my $self = shift;
    $self->debug('ERR', @_);
}

=head2 B<WARN> or B<WARNING>

If the log level is WARN or above, then these warnings are logged.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub WARN {
    my $self = shift;
    $self->debug('WARN', @_);
}

sub WARNING {
    my $self = shift;
    $self->debug('WARN', @_);
}

=head2 B<NOTICE> or B<ATTENTION>

If the loglevel is NOTICE or above, then these notices are logged.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub NOTICE {
    my $self = shift;
    $self->debug('NOTICE', @_);
}

sub ATTENTION {
    my $self = shift;
    $self->debug('NOTICE', @_);
}

=head2 B<INFO> or B<INFORMATION>

If the loglevel is INFO (or VERBOSE) or above, then these information messages are displayed.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub INFO {
    my $self = shift;
    $self->debug('INFO', @_);
}

sub INFORMATION {
    my $self = shift;
    $self->debug('INFO', @_);
}

=head2 B<DEBUG>

If the Loglevel is DEBUG or above, then basic debugging messages are logged.  DEBUG is intended for basic program flow messages for easy tracing.  Best not to place variable contents in these messages [...]

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub DEBUG {
    my $self = shift;
    $self->debug('DEBUG', @_);
}

=head2 B<DEBUGMAX>

If the loglevel is DEBUGMAX, then all messages are shown, and terse debugging messages as well.  Typically DEBUGMAX is used for variable dumps and detailed data output for heavy tracing.  This is a ve [...]

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub DEBUGMAX {
    my $self = shift;
    $self->debug('DEBUGMAX', @_);
}

1;

=head1 B<CAVEATS>

Since it is possible to duplicate the object in a fork or thread, the output formatting may be mismatched between forks and threads due to the automatic padding adjustment of the subroutine name field [...]

Ways around this are to separately create a Debug::Easy object in each fork or thread, and have them log to separate files.

The "less" pager is the best for viewing log files generated by this module.  It's switch "-r" allows you to see them in all their colorful glory.

=head1 B<INSTALLATION>

To install this module, run the following commands:

 perl Makefile.PL
 make
 make test
 [sudo] make install

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 B<VERSION>

Version 2.19

=head1 B<SUPPORT>

You can find documentation for this module with the perldoc command.

C<perldoc Debug::Easy>

or if you have "man" installed, then

C<man Debug::Easy>

You can also look for information at:  L<https://github.com/richcsst/Debug-Easy>

=head1 B<AUTHOR COMMENTS>

I coded this module because it filled a gap when I was working for a major chip manufacturing company (which I coded at home on my own time).  It gave the necessary output the other coders asked for, [...]

If you have any features you wish added, or functionality improved or changed, then I welcome them, and will very likely incorporate them sooner than you think.

=head1 B<LICENSE AND COPYRIGHT>

Copyright 2013-2025 Richard Kelsch.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<https://perlfoundation.org/artistic-license-20.html>

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, [...]

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of t [...]

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent cla [...]

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A [...]

=head1 B<TOOTING MY OWN HORN>

Perl modules available on github - L<https://github.com/richcsst>

And available on CPAN:

 *  BBS::Universal
 *  Debug::Easy
 *  Graphics::Framebuffer
 *  Term::ANSIEncode
 *  BBS::Universal - A Perl based Internet BBS server

=cut

