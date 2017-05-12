package Log::ProgramInfo;

=head1 NAME

Log::ProgramInfo - log global info from a perl programs.

=head1 VERSION

Version 0.1.13

=cut

our $VERSION = '0.1.13';

use feature qw(say);
use Data::Dumper;
use FindBin;
use Time::HiRes qw(time);
use DateTime;
use DateTime::Duration;
use Carp qw(carp croak cluck);
use Fcntl qw(:flock);
use Config;
use Digest::SHA;


=head1 SYNOPSIS

        use Log::ProgramInfo qw(
            [ -logname LOGNAME                 ]
            [ -logdir  LOGDIR                  ]
            [ -logext  LOGEXT                  ]
            [ -logdate none|date|time|datetime ]
            [ -stdout                          ]
            [ -suppress                        ]
            [ -log     $log4perl_log           ]
            );

        # main program does lots of stuff...
        exit 0;

    After the program has run, this module will automatically
    log information about this run into a log file and/or to a
    log object.  It will list such things as:
      - program
        - name
        - version
      - command line arguments
      - version of perl
      - modules loaded
        - source code location
        - Version
      - run time

    If a -log parameter is provided, it should be a log object that provides
    an info method (i.e. a Log4Perl object is likely).  The info will be sent
    sent to this log in addition to writing it to a log file.  This logging
    is not affected by the -suppress attribute - use that if you don't want a
    file log written too.

    Warning, the log parser will have to be modified if you need to parse this
    info out of a log4perl log - there is extra text in the lines (and any
    other logging from the program) which will need to be pruned.

    The log is appended to the file whose name is determined by:
        LOGDIR/LOGDATE-LOGNAME.LOGEXT
    where
        LOGDIR        defaults to . (the current directory when the program terminates)
        LOGDATE       defaults to the date that the program was started
        LOGNAME       defaults to the basename of the program
        LOGEXT        defaults to ".programinfo"

    The -ARG specifiers in the "import" list can be used to over-ride these defaults.  Specifying:

    -logname LOGNAME  will use LOGNAME instead of the program name
    -logdir  LOGDIR   will use LOGDIR instead of the current directory
                        - if it is a relative path, it will be based on the
                              current directory at termination of execution
    -logext  EXT      will add .EXT to the log filename
    -logext  .EXT     will add .EXT to the log filename
    -logext  ""       will add no extension to the log filename
    -logdate STRING
                      will specify the LOGDATE portion of the filename.  The STRING can be:
                  none      LOGNAME (and no dash)
                  date      YYYYMMDD-LOGNAME   (this is the default)
                  time      HHMMSS-LOGNAME
                  datetime  YYYYMMDDHHMMSS-LOGNAME

    -stdout           will cause the log to be sent to stdout instead of a file
    -suppress         will suppress logging (unless environment variable
                              LOGPROGRAMINFO_SUPPRESS is explcitly set to 0 or null)

                              Normally, neither -suppress nor -stdout will be set in the
                              use statement, and the environment variables can then be
                              used to disable the logging completely or to send it to
                              stdout instead of to the selected file.

                              For some programs, however, it may be desired to not normally
                              provide any logging.  Specifying -suppress will accomplish
                              this.  In such a case, setting the environment variable
                              LOGPROGRAMINFO_SUPPRESS=0 will over-ride that choice, causing
                              the log to be written (as specified by the other options
                              and environment variables).

    Environment variables can over-ride these parameters:
        LOGPROGRAMINFO_SUPPRESS=x  boolean suppresses all logging if true
        LOGPROGRAMINFO_STDOUT=x    boolean sets -stdout
        LOGPROGRAMINFO_DIR=DIR     string  sets the target directory name
        LOGPROGRAMINFO_NAME=NAME   string  sets the target filename LOGNAME
        LOGPROGRAMINFO_EXT=EXT     string  sets the target extension
        LOGPROGRAMINFO_DATE=DATE   string  sets the target filename LOGDATE selector

        (there is no environment variable for setting the log attribute, that
        can only be done within the program)

    Adding extra loggable information:
        If you want to add your own classes of loggable info, there are a
        few restrictions.

        You define a logging extension routine using:

            Log::ProgramInfo::add_extra_logger( \&my_logger );

        Your logger routine should be defined as:

            sub my_logger {
                my $write_entry = shift;
                $write_entry->( $key1, $value );
                $write_entry->( $key1, $key2, $value );
            }

        The $write_entry function passed to my_logger must be called with
        2 or 3 arguments.  The leading arguments are major (and minor if
        desired) keys, the final one is the value for the key(s).

        Try to keep the first key to 7 characters, and the second to 8 to
        keep the log readable by humans.  (It will be parseable even if you
        use longer keys.)

		Help improve the world!  If you are writing additional classes of
		info loggers, please consider whether they are truly unique to your
		own environment.  If there is a chance that they would be useful to
		other environments, please be encouraged to send your logger to be
		included into Log::ProgramInfo as either a standard default logger
		or as an available optional logger.

    Parsing the log file:
        The log file is designed to be easily parsed.

        A log always starts with a line beginning with 8 hash marks in column
        one (########) plus some identifying info.

        The value lines are of the form:

        key     : value
        key1    : key2    : value

        The first key is extended to at least 7 characters with blanks, the
        second key (if any) is extended to at least 8 characters.  There is
        always a separator of (space(colon)(space) between a key and the
        following field.  (A key can be provided with leading spaces for making
        the log more readable by humans - the readlog function in the test suite
        will remove such spaces.)

        Two subroutines are available to do this parsing for you:

            my $firstonly = 0;
            @logs = readlog( $filepath    [, $acceptsub] [, $firstonly] );
            @logs = parselog( $filehandle [, $acceptsub] [, $firstonly] );

            $logs = readlog( $filepath    [, $acceptsub ], 1 );
            $logs = parselog( $filehandle [, $acceptsub ] ,1 );

        The first parameter to each is either a string pathname (for readlog)
        or an already opened readable file handle (for parselog).

        If a subroutine reference arg $acceptsub is provided, each log that is
        read will be passed to that sub reference.  If the acceptsub returns
        true the log is retained, otherwise it is discarded.  If a trailing
        (non-sub-ref) value is provided, it selects whether only the first
        (acceptable) log found will be returned as a single hash reference, or
        whether all of the (accepted) logs in the file will be returned as a
        list of hash references.`

        The hash reference for each accepted log contains the key/value (or
        key1 => { key2/value pairs }) from that log.

        Whenever a key (or key1/key2 pair) is seen multiple times, the value
        is an array ref instead of a scalar.  This only happens with the
        MODULE pairs (MODULE/NAME, MODULE/LOC, MODULE/VERSION), and the INC
        key.  (User-provided keys are not currently permitted to use the same
        key set multiple times.)

=cut

# preserve command line info
my @args      = @ARGV;
my $progbase;
my $starttime;

my %option;

my %valid_dates;

my %_omap;
my %env_options;

my $kill_caught;

my ($uid, $gid);
my %cache;
my %modkeys = ( NAME => 1, VERSION => 1, LOC => 1, SUM => 1 );

sub readlog {
    my $file = shift;
    open my $fh, '<', $file or die "Cannot open $file: $!";
    return parselog( $fh, @_ );
}

sub parselog {
    my $fh = shift;
    my $accept;
    $accept = shift if ref($_[0]) eq 'CODE';
    my $firstonly = shift;
    my @logs;
    while (my $log = parse1log( $fh )) {
        next if $accept && ! $accept->($log);
        return $log if $firstonly;
        push @logs, $log;
    }
    return @logs;
}

sub parse1log {
    my $fh = shift;
    my $log;
    while (my $line = <$fh>) {
        return $log if $line =~ /^$/;
        next if $line =~ /^########/;
        chomp $line;
        $log ||= {};
        my @keys = split ': ', $line;
        s/^\s*// for @keys;
        s/\s*$// for @keys;
        die "Unexpected syntax in log line: $line\n" unless scalar(@keys) >= 2;
        my $val = pop @keys;
        my $key = shift @keys;
        if (scalar(@keys) == 0) {
            if ($key eq 'INC') {
                my $list = $log->{$key} ||= [];
                push @$list, $val;
            }
            else {
                die "repeated key: {$key} : line {$line}" if exists $log->{$key};
                $log->{$key} = $val;
            }
        }
        else {
            my $key2 = shift @keys;
            die "invalid nested key: {" . join( '}{', $key, $key2, @keys, $val ) . "}"
                if scalar(@keys);
            if ($key eq 'MODULE') {
                die "Unknown MODULE key ($key2)" unless $modkeys{$key2};
                my $list = $log->{$key}{$key2} ||= [];
                push @$list, $val;
            }
            else {
                die "repeated key: {$key} {$key2}" if exists $log->{$key}{$key2};
                $log->{$key}{$key2} = $val;
            }
        }
    }
    return $log;
}

my @extra_loggers = ();

sub add_extra_logger {
    for my $logger (@_) {
        croak "arg to extra_loggers is not a code ref: " . Dumper($logger)
            unless ref $logger eq 'CODE';
        push @extra_loggers, $logger;
    }
}

sub groupmap {
    my $list = shift;
    my @res;
    my %unique;
    push @res, ($cache{$_} //= getgrgid $_) for grep { ! $unique{$_}++ } split ' ', $list;
    my $g1 = shift @res;
    return join( '+', $g1, join( ',', @res ) );
}

BEGIN {
    $progbase        = $FindBin::Script;
    $starttime       = DateTime->from_epoch(epoch => time);
    $valid_dates{$_} = 1 for qw( date time datetime none );
    $uid             = getpwuid $<;
    my $euid         = getpwuid $>;
    $gid             = groupmap $(;
    my $egid         = groupmap $);
    $uid             = "$euid($uid)"   if $uid ne $euid;
    $gid             = "$egid // $gid" if $egid ne $gid;

    %option = (
        suppress  => 0,
        stdout    => 0,
        logdir    => ".",
        logdate   => "date",
        logname   => $progbase,
        logext    => ".programinfo",
        log       => undef,
    );

    %_omap = (
        LOGPROGRAMINFO_SUPPRESS => 'suppress',
        LOGPROGRAMINFO_STDOUT   => 'stdout',
        LOGPROGRAMINFO_DIR      => 'logdir',
        LOGPROGRAMINFO_DATE     => 'logdate',
        LOGPROGRAMINFO_NAME     => 'logname',
        LOGPROGRAMINFO_EXT      => 'logext',
    );

    while( my($k,$v) = each %_omap ) {
        $env_options{$v} = $ENV{$k} if exists $ENV{$k};
    }
    $SIG{HUP}  = \&catch_sig;
    $SIG{INT}  = \&catch_sig;
    $SIG{PIPE} = \&catch_sig;
    $SIG{TERM} = \&catch_sig;
    $SIG{USR1} = \&catch_sig;
    $SIG{USR2} = \&catch_sig;
}

sub import {
    my $mod = shift;

    while (scalar(@_)) {
        if ($_[0] =~ /^-(logname|logdir|logext|logdate)$/) {
            my $key = $1;
            croak "Option to Log::ProgramInfo requires a value: $_[0]" if scalar(@_) == 1;
            shift;
            my $val = shift;
            $option{$key} = $val;
        }
        elsif ($_[0] =~ /^-(stdout|suppress)$/) {
            my $key = $1;
            shift;
            $option{$key} = 1;
        }
        else {
            last;
        }
    }

    croak "Unknown option to Log::ProgramInfo: $_[0]" if (@_ and $_[0] =~ /^-/);
    croak "Import arguments not supported from Log::ProgramInfo: " . join( ',', @_ ) if @_;
    croak "Unknown logdate option: $option{logdate}"
        unless exists $valid_dates{ $option{logdate} };

    say STDERR "resolved option hash: ", Dumper(\%option) if $ENV{DUMP_LOG_IMPORTS};
}

END {
    my $exit_status = $?;
    local $?;    # protect program exit code from END actions
    finish_log($exit_status);
}

sub catch_sig {
    my $signame = shift;
    local $?;    # protect program exit code from END actions
    finish_log("Killed with signal: $signame");
}

my $logfh;
my $log;

sub log_entry {
    my $msg;
	my @vals = @_;
    for (@vals) {
	    $_ = 'NO_VALUE_FOUND' unless length($_);
	    s/\t/<TAB>/g;
        s/\n/<NL>/g;
    }
    if (@vals == 2 ) {
        $msg = sprintf "%-7s : %s", @vals;
    } elsif (@vals == 3 ) {
        $msg = sprintf "%-7s : %-8s : %s", @vals;
    } else {
        my $msg = "log_entry needs 2 or 3 arguments, got "
            . scalar(@vals);
        $msg .= ': (' . join( '), (', @vals ) . ')' if @vals;
        cluck $msg;
    }
    _log_entry( $msg );
}

sub _log_entry {
    my $msg = shift;
    say $logfh $msg if $logfh;
    $log->info( $msg ) if $log;
}

sub finish_log {
    return if $kill_caught++; # only write log once - first kill, or termination
    my $exit_status = shift;
	# pull ENV var over-rides
	while (my ($k, $v) = each %env_options) {
		$option{$k} = $v;
	}
    if (!$option{suppress} || $option{log}) {
        my $endtime;
        $log = $option{log};
        unless ($option{suppress}) {
            $endtime = DateTime->from_epoch(epoch => time);

            if ($option{stdout}) {
                open $logfh, ">>&STDOUT";
            }
            else {
                my $dopt = $option{logdate};
                my $date =
                    ( "none" eq $dopt )   ? ''
                    : ( "date" eq $dopt ) ? $starttime->ymd('')
                    : ( "time" eq $dopt ) ? $starttime->hms('')

                    # : ("datetime" eq $dopt) # validated, so must be 'datetime '
                    : ( $starttime->ymd('') . $starttime->hms('') );
                $date .= '-' if $date;
                $option{logext} = ".$option{logext}" if $option{logext} =~ m(^[^.]);
                my $log_path = "$option{logdir}/$date$option{logname}$option{logext}";
                open( $logfh, ">>", $log_path )
                    or carp "cannot open log file $log_path: $!";
                say STDERR "Appending log info to $log_path";
                my $lock_cnt = 0;
                while (1) {
                    flock $logfh, LOCK_EX and last;
                    croak "$0 [$$]: flock failed on $log_path: $!" if $lock_cnt > 30;
                    say STDERR "Waiting for lock on $log_path" unless $lock_cnt++;
                    print STDERR ".";
                    sleep(2);
                }
                say "" if $lock_cnt;
                seek $logfh, 2, 0; # make sure we're still at the end now that it is locked
            }

        }
        _log_entry( join( ' ', "########", $uid, '(', $gid, ') :', $progbase, @args ) );

        my $mod = show_modules();
        for my $key ( sort keys %$mod ) {
            my ( $ver, $loc ) = @{ $mod->{$key} };
            log_entry( MODULE => NAME    => $key );
            log_entry( MODULE => VERSION => $ver );
            log_entry( MODULE => LOC     => $loc );
			if (open my $fd, '<', $loc) {
				my $sum = Digest::SHA->new(256);
				$sum->addfile( $fd );
				log_entry( MODULE => SUM => $sum->hexdigest );
			}
        }
        for my $inc (@INC) {
            log_entry( INC => $inc );
        }

        log_entry( UNAME => $_->[1], do { my $out = qx( uname $_->[0] ); chomp $out; $out } )
            for (
            [ -s => "System" ],
            [ -n => "Name" ],
            [ -r => "OSRel" ],
            [ -v => "OSVer" ],
            [ -m => "Machine" ]
        );
        my $numproc = 0;
        my $procid  = 'PROC0';
        if (open my $cpuinfo, '<', '/proc/cpuinfo') {
            for (<$cpuinfo>) {
                chomp;
                next if /^\s*$/;
                my ($k, $v) = split /\s*:\s*/, $_, 2;
                if ($k eq 'processor') {
                    $procid = "PROC$numproc";
                    ++$numproc;
                }
                else {
                    log_entry( $procid, $k, $v ) if $v =~ /\S/;
                }
            }
            log_entry( PROCs, $numproc );
        }
        log_entry( PERL    => $^X );
        log_entry( PERLVer => $] );
		if (open my $fd, '<', $^X) {
			my $sum = Digest::SHA->new(256);
			$sum->addfile( $fd );
			log_entry( PERLSUM => $sum->hexdigest );
		}
        log_entry( libc    => $Config{libc} );
		if (open my $fd, '<', $Config{libc}) {
			my $sum = Digest::SHA->new(256);
			$sum->addfile( $fd );
			log_entry( libcSUM => $sum->hexdigest );
		}
        log_entry( User    => $uid );
        log_entry( Group   => $gid );
        my $progdir = $FindBin::Bin;
        log_entry( ProgDir => $progdir );
        log_entry( Program => $progbase );
        log_entry( Version => ( $::VERSION // "(No VERSION)" ) );
		if (open my $fd, '<', "$progdir/$progbase") {
			my $sum = Digest::SHA->new(256);
			$sum->addfile( $fd );
			log_entry( ProgSUM => $sum->hexdigest );
		}
        log_entry( Args    => scalar(@args) );
        my $acnt = 0;
        log_entry( "  arg" => sprintf("%8d", ++$acnt), $args[$acnt-1] ) for @args;
        log_entry( Start   => $starttime->datetime() . "." . sprintf( "%03d", $starttime->millisecond ) );
        log_entry( End     => $endtime->datetime()   . "." . sprintf( "%03d", $endtime->millisecond ) );
        my $dur = $endtime->subtract_datetime_absolute($starttime);
        log_entry( Elapsed => $dur->delta_seconds . "." .
                                    sprintf( "%03d", $dur->delta_nanoseconds/1_000_000) );
        log_entry( EndStat => $exit_status );

        $_->(sub { log_entry( @_ ) }) for @extra_loggers;

        _log_entry ""; # blank line to separate any appended later log

        close $logfh if $logfh;
    }
}

# Print version and loading path information for modules
sub show_modules {
    my $module_infos = {};

    # %INC looks like this:
    # {
    #    ...
    #    "Data/Dump.pm"
    #        => "/whatever/perl/lib/site_perl/5.18.1/Data/Dump.pm",
    #    ...
    # }
    # So let's convert it to this:
    # {
    #    ...
    #    "Data::Dump"
    #        => [ "1.4.2",
    #             "/whatever/perl/lib/site_perl/5.18.1/Data/Dump.pm",
    #           ],
    #    ...
    # }
    foreach my $module_inc_name ( keys(%INC) ) {
        my $real_name = $module_inc_name;
        $real_name =~ s|/|::|g;
        $real_name =~ s|\.pm$||;

        my $version = eval { $real_name->VERSION }
            // eval { ${"${real_name}::VERSION"} }
            // 'unknown';
        # stringify, in case it is a weird format
        # - I don't think the 'invalid' alternative can be hit, but safer to have it in
        $version = eval { $version . ''  } // 'invalid';

        $module_infos->{$real_name} = [ $version, $INC{$module_inc_name} ];
    }

    return $module_infos;
}

1;
