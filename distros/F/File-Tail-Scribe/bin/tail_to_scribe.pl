#! /usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Tail::Scribe;
use POSIX ();
use FindBin ();
use File::Basename ();
use File::Spec::Functions;
use Pod::Usage;
use Sys::Hostname;
use YAML::Any;
use Proc::ProcessTable;

my $script = File::Basename::basename($0);
my $SELF = catfile $FindBin::Bin, $script;
my @saved_argv = @ARGV;

my $sigset = POSIX::SigSet->new();
my $hup = POSIX::SigAction->new('sigHUP_handler',
				   $sigset,
				   &POSIX::SA_NODEFER);
POSIX::sigaction(&POSIX::SIGHUP, $hup);
my $term = POSIX::SigAction->new('sigTERM_handler',
				 $sigset,
				 &POSIX::SA_NODEFER);
POSIX::sigaction(&POSIX::SIGTERM, $term);
POSIX::sigaction(&POSIX::SIGINT, $term);
POSIX::sigaction(&POSIX::SIGQUIT, $term);

my @cat_re;
my %args = (
    config => '/etc/tail_to_scribe.conf',
    dirs => [ '/var/log/httpd' ],
    filter => '[._]log$',
    'exclude-dir' => [],
    'exclude-re' => [],
    'follow-symlinks' => 0,
    'sleep-interval' => 2,
    host => 'localhost',
    port => 1463,
    level => 'info',
    'retry-plan-a' => 'buffer',
    'retry-plan-b' => 'discard',
    'retry-buffer-size' => 100000,
    'retry-count' => 100,
    'retry-delay' => 10,
    'state-file-name' => '.tailtoscribe',
    'no-init' => 0,
);

GetOptions(\%args,
	   'category=s',
	   'config=s',
	   'dirs=s{1,}',
	   'excluded-dir=s{1,}',
	   'excluded-re=s{1,}',
	   'follow-symlinks',
	   'sleep-interval=i',
	   'filter=s',
	   'port=i',
	   'host=s',
	   'level=s',
	   'no-init',
	   'retry-plan-a=s',
	   'retry-plan-b=s',
	   'retry-buffer-size=i',
	   'retry-count=i',
	   'retry-delay=i',
	   'state-file-name=s',
	   'debug:s',
	   'daemon',
	   'pidfile=s',
	   "help|?",
           ) or pod2usage(-exitval => 2, -verbose => 0);

pod2usage(-exitval => 0, -verbose => 2) if $args{'help'};


my $dbg_file;
my $debug;
if (defined $args{debug}) {
    $debug++;
    if ($args{debug}) {
	open($dbg_file, '>', $args{debug}) or die "Failed to open debug file $args{debug}: $!";
    }
    else {
	$dbg_file = \*STDERR;
    }
    select($dbg_file);
    $| = 1;
}

my @excludes = @{$args{'exclude-dir'}};
push(@excludes, map { qr/$_/ } @{$args{'exclude-re'}});

my $hostname = hostname();
my $msg_filter = sub {
    my $self = shift;
    my $filename = shift;
    my $line = shift;
    $filename =~ s{^.*/}{};		      # remove leading dirs
    $filename =~ s{(?:[._-]access)?[._-][^._-]*$}{}; # remove extension
    $filename ||= 'default';                  # in case everything gets removed

    return ('info', 'httpd', "$hostname\t$filename\t$line");
};

if ( -f $args{config} ) {
    eval `cat $args{config}`;
    die "Failed to load \"$args{config}\": $@" if $@;
}

check_pid($args{pidfile}) if $args{pidfile};

if ($args{daemon}) {
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    POSIX::setsid() or die "Can't start a new session: $!";
    open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";
}

write_pid($args{pidfile}) if $args{pidfile};

END {
    cleanup_pid($args{pidfile});
}

if ($debug) {
    print "Command line arguments\n " . Dump(\%args) . "===\n";
}

my $log = File::Tail::Scribe->new(
    directories => $args{dirs},
    filter => qr/$args{filter}/,
    exclude => \@excludes,
    follow_symlinks => $args{'follow-symlinks'},
    sleep_interval => $args{'sleep-interval'},
    scribe_options => {
	name       => 'scribe',
	min_level  => $args{level},
	host       => $args{host},
	port       => $args{port},
	default_category => $args{category},
	retry_plan_a => $args{'retry-plan-a'},
	retry_plan_b => $args{'retry-plan-b'},
	retry_buffer_size => $args{'retry-buffer-size'},
	retry_count => $args{'retry-count'},
	retry_delay => $args{'retry-delay'},
    },
    msg_filter => $msg_filter,
    default_level => $args{level},
    statefilename => $args{'state-file-name'},
    no_init => $args{'no-init'},
    );

$log->watch_files();

sub sigHUP_handler {
    $log->save_state();
    exec($SELF, @saved_argv) or die "Couldn't restart: $!\n";
}

sub sigTERM_handler {
    $log->save_state();
    cleanup_pid($args{pidfile});
    exit();
}

sub read_pid {
    my $pidfile = shift;
    open my $fh, '<', $pidfile or return;
    my $pid = <$fh>;
    close($fh);
    chomp $pid if $pid;
    return $pid;
}

sub write_pid {
    my $pidfile = shift;
    open my $fh, '>', $pidfile or die "Failed to open $pidfile for writing: $!";
    print $fh "$$\n";
    close($fh);
}

sub check_pid {
    my $pidfile = shift;
    my $pid = read_pid($pidfile) or return;
    my $t = Proc::ProcessTable->new();
    for my $p ( @{$t->table} ) {
	if ($p->pid == $pid && $p->cmndline =~ m/tail_to_scribe/) {
	    die "tail_to_scribe is already running, PID $pid, pidfile $pidfile\n";
	}
    }
}

sub cleanup_pid {
    my $pidfile = shift;
    if ($pidfile && (my $pid = read_pid($pidfile)) ) {
	unlink $pidfile if $pid == $$;
    }
}

__END__

=head1 NAME

tail_to_scribe.pl - Tail files and send to a Scribe logging system.


=head1 SYNOPSIS

  tail_to_scribe.pl [ --config=CONFIG_FILE ]
                    [ --daemon ]
                    [ --dirs DIR1 [DIR2 ...] ]
                    [ --excluded-dir XDIR1 [XDIR2 ...] ]
                    [ --excluded-re REGEXP1 [REGEXP2 ...] ]
                    [ --filter=REGEXP ]
                    [ --follow-symlinks ]
                    [ --no-init ]
                    [ --state-file-name=FILE ]
                    [ --sleep-interval=SECS ]
                    [ --port=PORT ] [ --host=HOST ]
                    [ --level=LEVEL ] [ --category=CATEGORY ]

=head1 DESCRIPTION

tail_to_scribe.pl monitors files in a given directory (or set of directories),
such as Apache log files in /var/log/httpd, and as the log files are written to,
takes the changes and sends them to a running instance of the Scribe logging
system.

=head1 OPTIONS

=head2 --daemon

Run in the background.

=head2 --dirs DIR1 [DIR2 ...]

The list of directories in which to monitor files for changes.  Defaults to /var/log/httpd.

=head2 --excluded-dir XDIR1 [XDIR2 ...]

A list of directories to exclude from monitoring. These must be full filesystem paths.  Defaults to empty (no exclusions).

=head2 --excluded-re REGEXP1 [REGEXP2 ...]

A list of exclude regular expressions; any directory paths that match will be excluded from monitoring.  Defaults to empty (no exclusions).

=head2 --filter=REGEXP

A file filter regular expression; only filenames that match will be monitored.  Defaults to '[._]log$' (files ending in .log or _log).  Set to '.*' to include all files.

=head2 --follow-symlinks

If set, follow symbolic links in the filesystem.

=head2 --no-init

If set, any existing state file will be ignored, and only changes from the
current file state will be sent.  Without --no-init, on the first run (before
any state file is created), any existing content in the monitored files will be
sent as well as changes (which could be a large amount of data if you have big
files).

=head2 --state-file-name=FILE

Name of file in which to store state between runs.  Defaults to '.tailtoscribe' in the working directory.

=head2 --sleep-interval=SECS

Where a kernel-based file change notification system is not available, this
specifies the number of seconds between scans for file changes.

B<To minimise CPU usage, installing L<Linux::Inotify2> is highly recommended.>

=head2 Scribe Options

=over 4

=item --host, --port

Host and port of Scribe server.  Defaults to localhost, port 1463.

=item --category=CATEGORY

Default Scribe logging category.  Defaults to 'httpd'.

=item --level=LEVEL

Default log level.  Defaults to 'info'.  May be set to any valid
L<Log::Dispatch> level (debug, info, notice, warning, error, critical, alert,
emergency).

=item --retry-plan-a=MODE, --retry-plan-b=MODE, --retry-buffer-size=SIZE, --retry-count=COUNT, --retry-delay=DELAY

See L<Log::Dispatch::Scribe> for full description of these options.

=back

=head2 --pidfile=FILE

Write process ID to file FILE.  tail_to_scribe.pl will use this file to check if
an instance is already running, and refuse to start if the PID in this file
corresponds to another tail_to_scribe.pl process.  Checks are skipped if no
pidfile is given.

=head2 --debug, --debug=FILE

Enable debugging to standard error or to file.

=head2 --config=CONFIG_FILE

Specify the location of the configuration file (an included perl script).
Defaults to /etc/tail_to_scribe.conf.  A typical configuration file might
look like this:

  # Set my arg values
  my %localargs = (
      dirs => [ '/var/log/httpd' ],
      filter => 'access[._]log$',
      'exclude-dir' => [ '/var/log/httpd/fastcgi' ],
      'state-file-name' => '/var/log/httpd/.tailtoscribe',
  );

  # Copy into args to override defaults
  $args{$_} = $localargs{$_} for keys %localargs;

  1; # Must return a true value

In addition to all of the options available on the command line, a custom
message filter may also be included, e.g.

  $msg_filter = sub {
    my ($self, $filename, $line) = @_;

    return ('info', 'httpd', "$filename\t$line");
  };

See L<File::Tail::Scribe/msg_filter> for more details on the msg_filter.

=head1 SIGNALS

HUP signal causes tail_to_scribe.pl to restart.  TERM/QUIT/INT cause it to save state and exit.

=head1 SEE ALSO

=over 4

=item * L<File::Tail::Scribe>

=item * L<File::Tail::Dir>

=item * L<http://notes.jschutz.net/109/perl/perl-client-for-facebooks-scribe-logging-software>

=item * L<http://github.com/facebook/scribe/>

=item * L<Log::Dispatch::Scribe>

=back

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>  L<notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-tail-scribe at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Tail-Scribe>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Tail::Scribe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Tail-Scribe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Tail-Scribe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Tail-Scribe>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Tail-Scribe/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
