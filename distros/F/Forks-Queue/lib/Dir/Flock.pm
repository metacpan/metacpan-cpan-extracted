package Dir::Flock;
use strict;
use warnings;
use Carp;
use File::Temp;
use Time::HiRes 1.92;
use Fcntl ':flock';
use Data::Dumper;

our $VERSION = '0.01';
my @TMPFILE;
my %LOCK;

# configuration that may be updated by user
our $LOCKFILE_STUB = "dir-flock-";
our $PAUSE_LENGTH = 0.5;            # seconds
our $HEARTBEAT_CHECK = 30;          # seconds
our $TEMPFILE_XLENGTH = 12;

our $_DEBUG = $ENV{DEBUG} || $ENV{DIR_FLOCK_DEBUG} || 0;

sub _set_errno {
    my $mnemonic = shift;
    if (exists $!{$mnemonic}) {
        $! = 0;
        $!++ until $!{$mnemonic} || $! > 1024;
    } else {
        $! = 127;
    }
}

sub _pid {
    my $host = $ENV{HOSTNAME} || "localhost";
    join("_", $host, $$, $INC{"threads.pm"} ? threads->tid : ());
}

sub flock {
    my ($dir, $op) = @_;
    my $timeout = undef;
    if ($op & LOCK_NB) {
        $timeout = 0;
    }
    if ($op & LOCK_EX) {
        return Dir::Flock::lock($dir,$timeout);
    }
    if ($op & LOCK_UN) {
        return unlock($dir);
    }
    carp "Dir::Flock::flock: invalid operation";
    _set_errno("EINVAL");
    return;
}

sub lock {
    my ($dir, $timeout) = @_;
    if (! -d $dir) {
        carp "Dir::Flock::lock: '$dir' not a directory";
        _set_errno("ENOTDIR");
        return;
    }
    if (! -r $dir && -w $dir && -x $dir) {
        carp "Dir::Flock::lock: '$dir' not an accessible directory";
        _set_errno("ENOENT");
        return;
    }
    my $P = _pid();
    my $now = Time::HiRes::time;
    my $last_check = $now;
    my $expire = $now + ($timeout || 0);
    my $lockdata = [ $P, $now ];
    my $filename = _create_tempfile( $dir );
    _write_lock_data($lockdata, "$dir/$filename");
    while (_oldest_file($dir) ne $filename) {
        $_DEBUG && print STDERR "$P $filename not the oldest file...\n";
        if (defined($timeout) && Time::HiRes::time > $expire) {
            $_DEBUG && print STDERR "$P timeout waiting for lock\n";
            unlink "$dir/$filename";
            return;
        }
        Time::HiRes::sleep $PAUSE_LENGTH;
        if (Time::HiRes::time > $last_check + $HEARTBEAT_CHECK) {
            $_DEBUG && print STDERR "$P checking for heartbeat of lock holder\n";
            _ping_oldest_file($dir);
            $last_check = Time::HiRes::time;
        }
    }
    $_DEBUG && print STDERR "$P lock successful to $filename\n";
    $LOCK{$dir} = [ _pid(), $filename ];
    push @TMPFILE, "$dir/$filename";
    1;
}

sub _create_token {
    my ($n) = @_;
    my @bag = ('a'..'z', '0'..'9');
    my $token = join("", map { $bag[rand(@bag)] } 0..$n);
    $_DEBUG && print STDERR _pid()," created token: $token\n";
    $token;
}

sub _create_tempfile {
    my $dir = shift;
    my $file = $LOCKFILE_STUB . "_" . _pid() . _create_token($TEMPFILE_XLENGTH);
    return $file;
}

sub getDir {
    my $rootdir = shift;
    if (-f $rootdir && ! -d $rootdir) {
        require Cwd;
        require File::Basename;
        $rootdir = File::Basename::dirname(Cwd::abs_path($rootdir));
    }
    my $tmpdir = File::Temp::tempdir( DIR => $rootdir, CLEANUP => 1 );
    $tmpdir;
}

sub _oldest_file {
    my ($dir) = @_;
    my $dh;
    Time::HiRes::sleep 0.001;
    opendir $dh, $dir;
    my @f1 = grep /^$LOCKFILE_STUB/, readdir $dh;
    closedir $dh;
    my @f = map {
        my @s = Time::HiRes::stat("$dir/$_");
        [ $_, $s[9] ]
    } @f1;

    # the defined() check is necessary in case file disappears between
    # the time it is readdir'd and the time it is stat'd.
    my @F = sort { $a->[1] <=> $b->[1] || $a->[0] cmp $b->[0] }
            grep(defined $_->[1], @f);
    $_DEBUG && print STDERR _pid()," Files:", Dumper(\@F),"\n";
    @F && $F[0][0];
}

sub _ping_oldest_file {
    my $dir = shift;
    my $file = _oldest_file($dir);
    return unless $file;
    open my $fh, "<", "$dir/$file" or return;
    my @data = <$fh>;
    close $fh;
    my $status;
    my ($host,$pid,$tid) = split /_/, $data[0];
    $_DEBUG && print STDERR _pid(), ": ping  host=$host pid=$pid tid=$tid\n";
    if ($host eq $ENV{HOSTNAME} || $host eq 'localhost') {
        # TODO: more robust way to inspect process on local machine.
        #     kill 'ZERO',...  can mislead for a number of reasons, such as
        #     if the process is owned by a different user.
        $status = kill 'ZERO', $pid;
        $_DEBUG && print STDERR _pid(), " local kill ZERO => $pid: $status\n";
    } else {
        # TODO: need a more robust way to inspect a process on a remote machine
        my $c1 = system("ssh $host kill -0 $pid");
        $status = ($c1 == 0);
        $_DEBUG && print STDERR _pid(),
                             " remote kill ZERO => $host:$pid: $status\n";
    }
    if (! $status) {
        warn "Dir::Flock: lock holder that created $dir/$file appears dead\n";
        unlink("$dir/$file");
    }
}

sub _write_lock_data {
    my ($data, $filename) = @_;
    open my $fh, ">", $filename;
    print $fh $data->[0], "\n";    # process/thread identifier
    print $fh $data->[1], "\n";    # file creation time
    close $fh;
}

sub unlock {
    my ($dir) = @_;
    if (!defined $LOCK{$dir}) {
        !__inGD() && carp "Dir::Flock::unlock: lock not held by ",
                               _pid()," or any proc";
        return;
    }
    if ($LOCK{$dir}[0] ne _pid()) {
        !__inGD() && carp "Dir::Flock::unlock: lock not held by ",_pid();
        return;
    }
    $_DEBUG && print STDERR _pid()," unlocking $dir/$LOCK{$dir}[1]\n";
    if (! -f "$dir/$LOCK{$dir}[1]") {
        !__inGD() && carp "Dir::Flock::unlock: lock file is missing ",
            Dumper($LOCK{$dir});
        return;
    }
    my $z = unlink("$dir/$LOCK{$dir}[1]");
    delete $LOCK{$dir};
    if (! $z) {
        !__inGD() && carp "Dir::Flock::unlock: failed to unlink lock file ",
            Dumper($LOCK{$dir});
        return;   # this could be bad
    }
    $z;
}

BEGIN {
    if (defined(${^GLOBAL_PHASE})) {
        eval 'sub __inGD(){%{^GLOBAL_PHASE} eq q{DESTRUCT} && __END()};1'
    } else {
        require B;
        eval 'sub __inGD(){${B::main_cv()}==0 && __END()};1'
    }
}

END {
    no warnings 'redefine';
    *DB::DB = sub {};
    *__inGD = sub () { 1 };
    unlink @TMPFILE;
}

1;

=head1 NAME

Dir::Flock - advisory locking of a dedicated directory

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Dir::Flock;
    my $dir = Dir::Flock::getDir("/home/mob/projects/foo");
    my $success = Dir::Flock::lock($dir);
    # ... synchronized code
    $success = Dir::Flock::unlock($dir);

=head1 DESCRIPTION

C<Dir::Flock> implements advisory locking of a directory.
The use case is to execute synchronized code (code that should
only be executed by one process or thread at a time) or provide
exclusive access to a file or other resource. C<Dir::Flock> has
more overhead than some of the other synchronization techniques
available to Perl programmers, but it might be the only technique
that works on NFS (Networked File System).

=head2 Algorithm

File locking is difficult on NFS because, as I understand it, each
node maintains its own cache of filesystem contents. When a system
call checks whether a lock exists on a file, the filesystem driver
might just inspect the cached file rather than the file on the
server, and it might miss an action taken by another node to lock
a file.

The cache is not used, again, as I understand it, when the filesystem
driver reads a directory. If advisory locking is accomplished through
reading the contents of a directory, it will not be affected by NFS's
caching behavior.

To acquire a lock in a directory, this module writes a small file
into the directory. Then it checks if this new file is the "oldest"
file in the directory. If it is the oldest file, then the process
has acquired the lock. If there is already an older file in the
directory, than that file specifies what process has a lock on the
directory, and we have to wait and try again later. To unlock the
directory, the module simply deletes the file in the directory
that represents its lock.

=head1 FUNCTIONS

=head2 lock

=head2 $success = Dir::Flock::lock( $directory [, $timeout ] )

Attempts to obtain an exclusive lock on the given directory. While
the directory is locked, the C<lock> call on the same directory from
other processes or threads will block until the directory is unlocked
(see L<"unlock">). Returns true if the lock was successfully acquired.

If an optional C<$timeout> argument is provided, the function will
try for at least C<$timeout> seconds to acquire the lock, and return
a false value if it is not successful in that time. Use a timeout of
zero to make a "non-blocking" lock request.

=head2 unlock

=head2 $success = Dir::Flock::unlock( $directory )

Releases the exclusive lock on the given directory held by this
process. Returns a false value if the current process did not
possess the lock on the directory.

=head2 getDir

=head2 $tmp_directory = getDir( $root )

Creates a temporary and empty directory in a subdirectory of C<$root>
that is suitable for use as a synchronization object. The directory
will automatically be cleaned up when the process that called this
function exits.

=head2 flock

=head2 $success = flock( $dir, $op )

If you prefer the semantics of L<perlfunc/"flock">, the C<flock>
function from this package provides them in terms of the L<"lock">
and L<"unlock"> functions. Shared locks are not supported in
this version.

=head1 LIMITATIONS

Requires a version of L<Time::HiRes> with the C<stat> function,
namely v1.92 or better (though later versions seem to have some
fixes related to the stat function). Requires operating system
support for subsecond file timestamp (output
C<&Time::HiRes::d_hires_stat> and look for a positive value to
indicate that your system has such support) and filesystem
support (FAT is not likely to work).





=cut

=begin TODO    

Shared (non-exclusive) locks

    The lock directory will hold "shared" files and "exclusive" files.
    For an exclusive lock, write an exclusive file but erase it and retry
        if there is an older shared or exclusive file
    For a shared lock, write a shared file but erase and retry if there
        is an older exclusive file


Directory lock object that unlocks when it goes out of scope

    {
        my $lock = Dir::Flock::lockobj($dir);
    }

Block semantics

    Dir::Flock::sync $directory BLOCK
    Dir::Flock::sync_ex $directory BLOCK
    Dir::Flock::sync_sh $directory BLOCK

Enhancements to the lock file

    e.g., lock file specification is:
        1024 char header with host, process, thread, start time information
        additional lines with timestamps of when the process was verified
            to be alive
    then to check a process that holds the lock, you seek to 1024 in the
        lock file, read a line, and see if the process needs to be checked
        again

=end TODO
