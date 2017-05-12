package File::Tail::Dir;

use Moose;
use Moose::Util::TypeConstraints;

use File::ChangeNotify;
use File::Spec;
use File::Temp qw/tempdir/;
use Cwd qw/abs_path/;
use YAML::Any qw/DumpFile LoadFile/;
use POSIX;
use Config;
use Time::HiRes qw/time/;

our $VERSION = '0.16';

my @sig_names = map { split /\s+/ } $Config{sig_name};
my @sig_nums = map { split /\s+/ } $Config{sig_num};
my %signals;
for (my $i = 0; $i < @sig_names; $i++) {
    $signals{$sig_names[$i]} = $sig_nums[$i];
}
enum 'SIGNAME', [ keys %signals ];

my @watcher_opts = qw/directories filter exclude follow_symlinks sleep_interval/;
has 'watcher' => (
    is => 'ro',
    isa => 'File::ChangeNotify::Watcher',
    handles => \@watcher_opts,
    );
has 'statefilename' => ( 
    is => 'rw', 
    isa => 'Str', 
    default => '.filetaildirstate',
    );
has 'watchdog_signal_name' => ( 
    is => 'ro', 
    isa => 'SIGNAME', 
    default => sub { $^O =~ m/MSWin/ ? 'INT' : 'USR1' },
    );
has 'autostate' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );
has 'autostate_delay' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    );
has 'no_init' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    );
has 'processor' => (
    is => 'rw', 
    isa => 'CodeRef', 
    predicate => 'has_processor',
    );
has 'running' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    );
has 'max_age' => (
    is => 'ro',
    isa => 'Int',
    default => 3600,
    );
has 'max_lines' => (
    is => 'ro',
    isa => 'Int',
    default => 10000,
    );
has '_last_filehandle_check' => (
    is => 'rw',
    isa => 'Num',
    default => sub { time() },
    );
has '_state' => (
    is => 'ro', 
    isa => 'HashRef', 
    writer => '_set_state',
    default => sub { {} },
    );
# Store of filehandles against filenames
has '_filehandles' => (
    is => 'ro', 
    isa => 'HashRef', 
    writer => '_set_filehandles', 
    default => sub { {} },
    );

# private directory, used to trigger exit from watcher loop for auto state save
has 'private_dir' => (
    is => 'ro',
    isa => 'Str',
    );

# PID of child watchdog process
has '_child_pid' => (
    is => 'rw',
    );

# list of temporary directories to clean up on exit
my %cleanup_dirs;
my %cleanup_pids;
my $_dotfile = '.filetaildirwatchdog';


around 'BUILDARGS' => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{directories} ||= [ '.' ];
    my %watcher_opts;
    for ( @watcher_opts ) {
	$watcher_opts{$_} = delete $args->{$_} if exists $args->{$_};
    }
    if (! $args->{watcher} && $args->{autostate} && $args->{autostate_delay}) {
        # need to add a private directory to watch
        $args->{private_dir} ||= tempdir(CLEANUP => 0);
        push(@{$watcher_opts{directories}}, $args->{private_dir});
        push(@{$cleanup_dirs{$$} ||= []}, $args->{private_dir});
        # Add watchdog file to filter
        if (defined $watcher_opts{filter}) {
            $watcher_opts{filter} = qr/^\Q$_dotfile\E$|$watcher_opts{filter}/;
        }
    }
    $args->{watcher} ||= File::ChangeNotify->instantiate_watcher(%watcher_opts);

    return $args;
};

my @instances;
my $signal_handlers_installed = 0;

sub install_signal_handlers {
    for (qw/HUP INT QUIT TERM/) {
	next unless defined $signals{$_};
	$SIG{$_} = \&_save_and_exit;
    }
    $signal_handlers_installed = 1;
}

sub uninstall_signal_handlers {
    for (qw/HUP INT QUIT TERM/) {
	delete $SIG{$_};
    }
    $signal_handlers_installed = 0;
}

sub BUILD {
    push(@instances, shift) if $signal_handlers_installed;
}

sub _save_and_exit {
    while (my $self  = shift(@instances)) {
	$self->save_state if $self->running;
    }
    cleanup_processes();
    exit();
}

sub cleanup_processes {
    for my $pid (@{$cleanup_pids{$$} || []}) {
        kill SIGTERM, $pid;
    }
    for my $dir (@{$cleanup_dirs{$$} || []}) {
        unlink File::Spec->catfile($dir, $_dotfile);
        rmdir $dir;
    }
}

END {
    _save_and_exit();
}

# recurse through all given directories
sub _recurse {
    my $self = shift;
    my $fn = shift;

    my $follow = $self->follow_symlinks;
    my $filter = $self->filter;
    my $updir = File::Spec->updir;
    my $curdir = File::Spec->curdir;
    my $dirfilter = sub { $_ ne $updir && $_ ne $curdir };
    for my $dir (@{$self->directories}) {
	$self->_recurse_sub($fn, $dir, $dirfilter, $follow, $filter, {});
    }
}

sub _recurse_sub {
    my ($self, $fn, $dir, $dirfilter, $follow, $filter, $visited) = @_;

    opendir my $dh, $dir or do { warn "Failed to open directory $dir: $!"; next; };
    my @files = grep { &$dirfilter } readdir($dh);
    closedir($dh);
    for my $file (@files) {
	my $filename = abs_path(File::Spec->catfile($dir, $file));
	if (! $self->_excluded($filename) && ! defined $visited->{$filename}) {
	    if ($follow) {
		while (-l $filename && ! $visited->{$filename}++) {
		    $filename = abs_path(readlink $filename);
		}
	    }
	    $visited->{$filename}++;
	    if (-f $filename && $file =~ m/$filter/ ) {
		$fn->($filename);
	    }
	    elsif (-d $filename ) {
		$self->_recurse_sub($fn, $filename, $dirfilter, $follow, $filter, $visited);
	    }
	}
    }
}

sub _excluded {
    my $self = shift;
    my $path = shift;

    foreach my $excluded ( @{ $self->exclude } ) {
        if ( ref $excluded && ref $excluded eq 'Regexp' ) {
            return 1 if $path =~ /$excluded/;
        }
        else {
            return 1 if $path eq $excluded;
        }
    }
    return;
}

sub _load_inode_list {
    my ($self, $filename) = @_;

    if (! $self->{inode_list}) {
	$self->_recurse(sub {
	    my $filename = shift;
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
		$self->{inode_list}->{$ino} = $filename if defined $ino;
			});
    }
}

sub _clear_inode_list {
    my $self = shift;
    delete $self->{inode_list};
}

sub _check_inode_data {
    my ($self, $filename, $pos, $now) = @_;

    my $state = $self->_state;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
    return if defined($ino) && (exists $state->{$filename}) && $state->{$filename}->{inode} == $ino;

    my $oldrec = delete $state->{$filename};
    if ($oldrec) {
	$self->_remove_filehandle($filename);
    }

	
    if (defined $ino) {
	# does information on newly found inode exist?
	for my $f (keys %$state) {
	    if ($state->{$f}{inode} == $ino) {
		$state->{$filename} = delete $state->{$f};
		$self->_remove_filehandle($f);
		last;
	    }
	}
	# otherwise create new record
	if (! exists $state->{$filename} && -e $filename) {
	    $state->{$filename} = { inode => $ino, pos => ($pos || 0), changed => $now };
	}
    }
    # fix oldrec if we have data on the old inode
    if ($oldrec) {
	$self->_load_inode_list();
	if (my $newfile = $self->{inode_list}{$oldrec->{inode}}) {
	    $self->_check_inode_data($newfile, $oldrec->{pos}, $now);
	}
    }
}


sub _load_state {
    my $self = shift;
    my $statefilename = $self->statefilename;

    my $do_init = $self->no_init ? 0 : 1;

    $self->_set_state(LoadFile($statefilename)) if $do_init && -f $statefilename;
    my $state = $self->_state;

    my $now = time();
    $self->_recurse(
	sub {
	    my $filename = shift;
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
	    if (defined $ino) {
		if ($do_init) {
		    if (exists($state->{$filename}) && $size >= $state->{$filename}->{pos}) {
			# send delta
			$self->_process_event($filename, $now) if $size > $state->{$filename}->{pos};
		    }
		    else {
			# file is new or has shrunk, send initial content
			$state->{$filename} = { inode => $ino, pos => 0, changed => $now };
			$self->_process_event($filename, $now) if $size > 0;
		    }
		}
		else {
		    $state->{$filename} = { inode => $ino, pos => $size, changed => $now }; 
		}
	    }
	});

    return $state;
}

# state is a list of (inode, pos) for each filename
# inode is used to check when files are moved
# pos records the current position in the file up to which data has been sent
sub save_state {
    my $self = shift;

    my $state = $self->_state;

    # remove expired information
    for my $filename (keys %{$state}) {
	$self->_check_inode_data($filename, undef, time());
	delete $state->{$filename} unless -f $filename;
    }
    DumpFile($self->statefilename, $state) or warn "Failed to open " . $self->statefilename . " for writing: $!";
    $self->_clear_inode_list();
}


sub _update_state {
    my ($self, $filename, $event_t) = @_;

    my $state = $self->_state->{$filename};
    $state->{pos} = tell($self->_filehandles->{$filename});
    $state->{changed} = $event_t;
    
}

sub _get_filehandle {
    my ($self, $filename) = @_;

    my $filehandles = $self->_filehandles;
    if (-f $filename && ! $filehandles->{$filename}) {
	open( $filehandles->{$filename}, '<:bytes', $filename) or do {
	    warn "Failed to open $filename for reading: $!";
	    return;
	};
	if ($self->_state->{$filename}{pos}) {
	    seek($filehandles->{$filename}, $self->_state->{$filename}{pos}, 0);
	}
    }
    return $filehandles->{$filename};
}

sub _remove_filehandle {
    my ($self, $filename) = @_;

    if (my $fh = delete $self->_filehandles->{$filename}) {
	close($fh);
    }
}

sub _check_filehandles {
    my ($self, $now) = @_;

    return if $self->_last_filehandle_check + $self->max_age > $now;

    my $age = $self->max_age;
    my $filehandles = $self->_filehandles;
    my $state = $self->_state;
    for my $filename (keys %$filehandles) {
	if (! exists($state->{$filename}) || $state->{$filename}{changed} + $age < $now) {
	    $self->_remove_filehandle($filename);
	}
    }
    $self->_last_filehandle_check($now);
}
	    
sub process {
    my ($self, $filename, $lines) = @_;

    if ($self->has_processor) {
	$self->processor->($filename, $lines);
    }
    else {
	print "------ $filename -------\n" . join("", @$lines) . "--------\n";
    }
}

sub _process_event {
    my ($self, $filename, $event_t) = @_;

    # accommodate non-standard EOL, but not block reads
    my $eol = ref($/) ? "\n" : $/;
    my $eollen = length($eol);

    if (my $fh = $self->_get_filehandle($filename)) {
        while (1) {
            my @lines;
            while (my $line = <$fh>) {
                push(@lines, $line);
                last if @lines > $self->max_lines;
            }
            if (@lines) {
                # backtrack to last complete line if necessary
                my $partial = 0;
                if ((my $ch = substr($lines[-1], length($lines[-1]) - $eollen, $eollen)) ne $eol) {
                    seek($fh, -length($lines[-1]), 1);
                    pop @lines;
                    $partial++;
                }
                $self->process($filename, \@lines) if @lines;
                last if $partial;
            }
            else {
                last;
            }
        }
	$self->_update_state($filename, $event_t);
    }

}

sub watch_files {
    my $self = shift;
    my $opts = shift;

    my $state = $self->_load_state;
    my $dirty_state = 0;
    my $last_state_save = 0;
    my $watcher = $self->watcher;
    $self->running(1);

    my $watchdog_file = $self->_start_watchdog();

    while ( $self->running && (my @events = $watcher->wait_for_events()) ) { 
	my $event_t = time();
#	print "Got " . (scalar @events) . " events\n";
	for my $e (@events) {
#	    print "Event: " . $e->type . " on " . $e->path . "\n";
#            print "Watchdog file is $watchdog_file\n";
	    my $filename = abs_path($e->path);
            if (! $watchdog_file || $filename ne $watchdog_file) {
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);

                if (defined($ino) && (! (defined $state->{$filename}) || $state->{$filename}{inode} != $ino)) {
                    # new or moved file
                    $self->_check_inode_data($filename, undef, $event_t);
                }
                $self->_process_event($filename, $event_t);
                $dirty_state++;
            }
	}
	$self->_check_filehandles($event_t);

        if ($self->autostate && $last_state_save + $self->autostate_delay <= time()) {
            $self->_feed_watchdog();
            $self->save_state();
            $last_state_save = time();
            $dirty_state = 0;
        }
        else {
            $self->_clear_inode_list();
        }
    }
    $self->save_state();
    $self->_stop_watchdog();
}

# starts another process which will touch private_dir to trigger an
# exit from the wait_for_events() loop.
sub _start_watchdog {
    my $self = shift;

    return unless $self->autostate && $self->autostate_delay;
    my $delay = $self->autostate_delay;
    my $filename = _touch(File::Spec->catfile($self->private_dir, $_dotfile));
    $self->{_sig_no} = $signals{$self->watchdog_signal_name};

    my $pid = fork();
    if (! defined $pid) {
        die "Fork failed: $!";
    }
    elsif ($pid) {
        # parent
        $self->_child_pid($pid);
        push(@{$cleanup_pids{$$} ||= []}, $pid);
        return $filename;
    }

    # child

    $0 = '(watchdog) ' . $0;
    uninstall_signal_handlers();

    # restart timer on USR1, which parent uses to signal that state has been saved
    $SIG{$self->watchdog_signal_name} = sub {
        alarm $delay;
    };

    $SIG{ALRM} = sub {
	_touch($filename);
        alarm $delay;
    };

    alarm $delay;

    while (1) {
        select undef, undef, undef, 1000;
    }
}

# touch and return absolute filename 
# (Windows abs_path requires file to exist, rt.cpan.org #80457)
sub _touch {
    my $filename = shift;
    open my $fh, '>', $filename or die "Failed to open $filename: $!";
    print $fh time();
    close($fh);
    return abs_path($filename);
}

sub _stop_watchdog {
    shift->_kill_watchdog;
}

sub _kill_watchdog {
    my $self = shift;

    if (my $pid = $self->_child_pid) {
        kill SIGTERM, $pid;
    }
}

sub _feed_watchdog {
    my $self = shift;

    if (my $pid = $self->_child_pid) {
        kill $self->{_sig_no}, $pid;
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;


1;

__END__

=head1 NAME

File::Tail::Dir - Tail all matching files in a given set of directories

=head1 SYNOPSIS

Typical usage:

  use File::Tail::Dir;

  my $tailer = File::Tail::Dir->new(  filter => qr/.*access.*log$/,
					processor => sub { 
                                              my ($filename, $lines) = @_; 
                                              ... 
                                              },
		                     );
  $tailer->watch_files();

Or, subclass:

  package My::Tailer;
  use Moose;
  extends 'File::Tail::Dir';

  # override standard 'process' method
  sub process {
    my ($self, $filename, $lines) = @_;

      ...
    }

=head1 DESCRIPTION

Monitors and processes any lines appended to the end of one or more files in a
given list of directories, keeping state between sessions, and using kernel
notification of file change events to maximise efficiency.

A list of directories is given to monitor, and filtering/exclude expressions
allow just the files of interest to be selected for notification when lines are
appended.

This module was originally created to support lossless logging of many Apache
web server log files to a Scribe-based logging subsystem (see
L<File::Tail::Scribe>, L<Log::Dispatch::Scribe>), and hence key requirements are
to keep state, to be able to resume from the last known state between
interruptions (like server reboots), and to follow the renaming and creation of
new files during log rotation.


=head1 ALTERNATIVES

Like L<File::Tail::Multi>, L<File::Tail::App>, L<File::Tail::FAM>,
L<File::Tail>, B<File::Tail::Dir> is yet another module to tail and process one
or more files.  What B<File::Tail::Dir> provides that is different is:

=over 4

=item * Tails all matching files within a given set of directories

Apart from L<File::Tail::Multi>, the other alternatives allow monitoring of a
single file only. L<File::Tail::Multi> offers files and directories with glob
pattern expansion and filtering.  B<File::Tail::Dir> offers a list of
directories for monitoring with regular expression filtering and exclusions
based on a list of strings and/or regular expressions.

=item * Remembers state

B<File::Tail::Dir> maintains a state file, so can be stopped and started without
missing changes to files.  As it is intended to work with log files that are
periodically rotated, it will handle the situation where a file changes name
between runs.

=item * Uses kernel notification (where available) to monitor file changes

Built on Dave RolskyE<apos>s L<File::ChangeNotify>, B<File::Tail::Dir> supports
all file notification methods offered by that module.  For best performance on
Linux, it is recommended that L<Linux::Inotify2> be installed (for kernels
2.6.13 and later).  Of the similar modules listed above, only L<File::Tail::FAM>
provides event-based notification, using the older FAM kernel interface.

=back

=head1 CONSTRUCTOR

=head2 new

  $tailer = File::Tail::Dir->new(%options);

Options are as follows:

=over 4

=item File Selection Options

=over 4

=item * directories => \@paths

Spefify the directory paths that should be watched for changes.

=item * filter => qr/.../

This is an optional regular expression that will be used to check if a file is
of interest. This filter is only applied to files. By default, all files are
included.

=item * exclude => [...]

An optional list of paths to exclude. This list can contain either plain
strings or regular expressions. If you provide a string it should contain the
full filesystem path to be excluded.

The paths can be either directories or specific files. If the exclusion
matches a directory, all of its files and subdirectories are ignored.

=item * follow_symlinks => $bool

By default, symbolic links in the filesystem are ignored. Set this to true to follow them.

If symlinks are being followed, symlinks to files and directories
will be followed. Directories will be watched, and changes for
directories and files reported.

(Note that if this is set to true, the presence of circular link references may
cause problems due to a behaviour in the underlying L<File::ChangeNotify>).

=back

=item Processing Options

=over 4

=item * processor => sub { my ($filename, $lines) = @_; ... }

Specifies the callback function to process the arrayref of lines appended to the given file.

The default action is to print the lines to standard output.

=back

=item Miscellaneous Options

=over 4

=item * sleep_interval => $number

Where kernel file change event notification is not available, this argument
controls the interval between checks for file changes. The value is a number in
seconds.  The default is 2 seconds.

=item * statefilename => $filename

Sets the name of the file used to store state between sessions.  Defaults to
'.filetaildirstate' in the working directory.

=item * autostate => 1|0

Set to 1 to automatically store the state file periodically. Defaults to 0.

=item * autostate_delay => $number

If autostate is enabled, sets the minimum delay in seconds between
when the state file is automatically saved.  If set to 0, state is
saved on every file change.

=item * no_init => 1|0

If no_init is set, the initial contents of the monitored files is skipped and
only the changed contents (since creating the new File::Tail::Dir instance) is
sent.  

The default behaviour (no_init = 0) is for lossless logging, i.e. to send any
contents that has been appended to existing files since last run, and to see all
files without existing state as new files and therefore to send the whole
contents of those files before monitoring for new changes.

=item * max_age => $age_in_seconds

Maximum time in seconds to keep a filehandle open if no changes on the
filehandle have been seen.  Defaults to 3600 sec.

=item * max_lines => $number

Maximum number of lines to process from a given file at a time.  This
sets a limit on the maximum amount of memory to use, particularly in
the case of processing large files for the first time.  Defaults to
10000.

=item * watchdog_signal_name

Name of signal to use for watchdog.  Defaults to USR1 on most systems, INT on Windows.

=back

=back

=head1 METHODS

=head2 watch_files

  $tailer->watch_files()

Blocking call to watch for changes in files forever.  When a change is detected, the process() method is called.

=head2 process

This is the method invoked by watch_files() on file change, which in turn
invokes the callback function specified by the 'L<processor>' option.  If no
callback has been provided, it will print the filename and changed contents to
standard output by default.  This method may be overridden in a subclass instead of using the L<processor> option.  Its signature is:

  sub process {
     my ($self, $filename, $lines) = @_;
     ...
  }

The return value is ignored.

=head2 running

   $running = $tailer->running();  # get status
   $tailer->running(0); # exit event loop

This is set to true when the event loop in watch_files() is entered.  It can be
set to false (e.g. via a signal or in the process() method) to cause
watch_files() to return after processing the current batch of events.

Note that if running is set to false via signal, the event loop will not be
exited until a new file change event is seen.

=head2 save_state

  $tailer->save_state();

Saves internal state to file.  This is always called when
watch_files() completes normally, and is called periodically if
autostate is enabled.  However, you may wish to call it directly if
you have installed a signal handler that might not allow watch_files()
to complete.

=head2 __PACKAGE__->install_signal_handlers

    File::Tail::Dir->install_signal_handlers();

Installs default signal handlers.  Once installed, on receiving any of HUP, INT,
QUIT or TERM, all instances of File::Tail::Dir will attempt to save their state,
and then exit.

If used, this should be called before any File::Tail::Dir instance is created.

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >> L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-tail-dir at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Change-Dir>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Tail::Dir

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Tail-Dir>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Tail-Dir>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Tail-Dir>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Tail-Dir>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Tail::Dir
