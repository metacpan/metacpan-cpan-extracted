package Dir::Flock;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use File::Temp;
use Fcntl ':flock';
use Data::Dumper;    # when debugging is on
use base 'Exporter';

our $VERSION = '0.08_01';
my %TMPFILE;
my %LOCK;
our @EXPORT_OK = qw(getDir lock lock_ex lock_sh unlock lockobj lockobj_ex
                    lockobj_sh sync sync_ex sync_sh);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our $errstr;

# configuration that may be updated by user
our $LOCKFILE_STUB = "dir-flock-";
our $PAUSE_LENGTH = 0.001;          # seconds
our $HEARTBEAT_CHECK = 30;          # seconds
our $_DEBUG = $ENV{DEBUG} || $ENV{DIR_FLOCK_DEBUG} || 0;

sub getDir {
    my ($rootdir,$persist) = @_;
    if (-f $rootdir && ! -d $rootdir) {
        require Cwd;
        require File::Basename;
        $rootdir = File::Basename::dirname(Cwd::abs_path($rootdir));
    }
    my $tmpdir = File::Temp::tempdir(
        TEMPLATE => "dflock-XXXXXX",
        DIR => $rootdir, CLEANUP => !$persist );
    $tmpdir;
}


### core functions

sub lock { goto &lock_ex }

sub lock_ex {
    my ($dir, $timeout) = @_;
    $errstr = "";
    return if !_validate_dir($dir);
    my $P = $_DEBUG && _pid();
    my ($filename,$now) = _create_tempfile( $dir, "excl" );
    my $last_check = $now;
    my $expire = $now + ($timeout || 0);
    $TMPFILE{ $filename } = _pid();
    while (_oldest_file($dir) ne $filename) {
	unlink $filename;
	delete $TMPFILE{$filename};
        $P && print STDERR "$P $filename not the oldest file...\n";
        if (defined($timeout) && Time::HiRes::time > $expire) {
            $errstr = "timeout waiting for exclusive lock for '$dir'";
            $P && print STDERR "$P timeout waiting for lock\n";
            return;
        }
        Time::HiRes::sleep 0.3 + 2 * rand() * $PAUSE_LENGTH;
        if (Time::HiRes::time > $last_check + $HEARTBEAT_CHECK) {
            $P && print STDERR "$P check heartbeat of lock holder\n";
            _ping_oldest_file($dir);
            $last_check = Time::HiRes::time;
        }
	($filename,$now) = _create_tempfile( $dir, "excl" );
	$TMPFILE{ $filename } = _pid();
    }
    $P && print STDERR "$P lock successful to $filename\n";
    $LOCK{$dir}{_pid()} = $filename;
    1;
}

sub lock_sh {
    my ($dir, $timeout) = @_;
    $errstr = "";
    return if !_validate_dir($dir);
    my $P = $_DEBUG && _pid();
    my ($filename,$now) = _create_tempfile( $dir, "shared" );
    my $last_check = $now;
    my $expire = $now + ($timeout || 0);
    $TMPFILE{ $filename } = _pid();
    while (_oldest_file($dir) =~ /_excl_/) {
	unlink $filename;
	delete $TMPFILE{$filename};
        $P && print STDERR "$P $filename not the oldest file...\n";
        if (defined($timeout) && Time::HiRes::time > $expire) {
            $errstr = "timeout waiting for exclusive lock for '$dir'";
            $P && print STDERR "$P timeout waiting for lock\n";
            return;
        }
        Time::HiRes::sleep 0.3 + 2 * rand() * $PAUSE_LENGTH;
        if (Time::HiRes::time > $last_check + $HEARTBEAT_CHECK) {
            $P && print STDERR "$P check heartbeat of lock holder\n";
            _ping_oldest_file($dir);
            $last_check = Time::HiRes::time;
        }
	($filename,$now) = _create_tempfile( $dir, "shared" );
	$TMPFILE{ $filename } = _pid();
    }
    $P && print STDERR "$P lock successful to $filename\n";
    $LOCK{$dir}{_pid()} = $filename;
    1;
}

### flock semantics

sub flock {
    my ($dir, $op) = @_;
    my $timeout = undef;
    if ($op & LOCK_NB) {
        $timeout = 0;
    }
    if ($op & LOCK_EX) {
        return lock_ex($dir,$timeout);
    }
    if ($op & LOCK_SH) {
        return lock_sh($dir,$timeout);
    }
    if ($op & LOCK_UN) {
        return unlock($dir);
    }
    $errstr = "invalid flock operation '$op'";
    carp "Dir::Flock::flock: invalid operation";
    return;
}

sub unlock {
    my ($dir) = @_;
    if (!defined $LOCK{$dir}) {
        return if __inGD();
        $errstr = "lock for '$dir' not held by " . _pid()
            . " nor any proc";
        carp "Dir::Flock::unlock: $errstr";
        return;
    }
    my $filename = delete $LOCK{$dir}{_pid()};
    if (!defined($filename)) {
        return if __inGD();
        $errstr = "lock for '$dir' not held by " . _pid();
        carp "Dir::Flock::unlock: $errstr";
        return;
    }
    $_DEBUG && print STDERR _pid()," unlocking $filename\n";
    if (! -f $filename) {
        return if __inGD();
        $errstr = "lock file '$filename' is missing";
        carp "Dir::Flock::unlock: lock file is missing ",
            %{$LOCK{$dir}};
        return;
    }
    my $z = unlink($filename);
    if ($z) {
	$_DEBUG && print STDERR _pid()," deleted $filename\n";
	$_DEBUG && print STDERR "$dir contains:\n",join(" ",glob("$dir/*")),"\n";
	delete $TMPFILE{$filename};
	return $z;
    }
    return if __inGD();
    $errstr = "unlink called failed on file '$filename'";
    carp "Dir::Flock::unlock: failed to unlink lock file ",
	"'$filename'";
    return;   # this could be bad
}

### scope semantics

sub lockobj { goto &lockobj_ex }

sub lockobj_ex {
    my ($dir, $timeout) = @_;
    my $ok = lock_ex($dir,$timeout);
    return if !$ok;
    return bless \$dir, 'Dir::Flock::SyncObject2';
}

sub lockobj_sh {
    my ($dir, $timeout) = @_;
    my $ok = lock_sh($dir,$timeout);
    return if !$ok;
    return bless \$dir, 'Dir::Flock::SyncObject2';
}

sub Dir::Flock::SyncObject2::DESTROY {
    my $self = shift;
    my $dir = $$self;
    my $ok = unlock($dir);
    if (!$ok && !__inGD()) {
        # $errstr set in unlock
        carp "unlock: failed for dir '$dir' as sync object went out of scope";
    }
    return;
}

### block semantics

sub sync (&$;$) { goto &sync_ex }

sub sync_ex (&$;$) {
    my ($code, $dir, $timeout) = @_;
    if (!lock_ex($dir,$timeout)) {
        # $errstr set in lock_ex
        return;
    }
    my @r;
    if (wantarray) {
        @r = eval { $code->() };
    } else {
        $r[0] = eval { $code->() };
    }
    unlock($dir);
    if ($@) {
        $errstr = "error from sync_ex BLOCK: $@";
        die $@;
    }
    wantarray ? @r : $r[0];
}

sub sync_sh (&$;$) {
    my ($code, $dir, $timeout) = @_;
    if (!lock_sh($dir,$timeout)) {
        # $errstr set in lock_sh
        return;
    }
    my @r;
    if (wantarray) {
        @r = eval { $code->() };
    } else {
        $r[0] = eval { $code->() };
    }
    unlock($dir);
    if ($@){
        $errstr = "error from sync_sh BLOCK: $@";
        die $@;
    }
    wantarray ? @r : $r[0];
}

### utilities

sub _host {
    $ENV{HOSTNAME} || ($^O eq 'MSWin32' && $ENV{COMPUTERNAME})
	|| "localhost";
}

sub _pid {
    my $host = _host();
    join("_", $host, $$, $INC{"threads.pm"} ? threads->tid : ());
}

sub _create_tempfile {
    my ($dir,$type) = @_;
    $type ||= "excl";
    my $now = Time::HiRes::time;
    my $file = sprintf "$dir/%s_%s_%s_%s", $LOCKFILE_STUB,
	$now, $type, _pid();
    open my $fh, ">>", $file;
    return ($file,$now);
}

sub _oldest_file {
    my ($dir, $excl) = @_;
    my $dh;
    _refresh_dir($dir);  # is this necessary? is this sufficient?
    my @f1 = sort glob("$dir/$LOCKFILE_STUB*");
    if ($excl) {
        @f1 = grep /_excl_/, @f1;
    }
    @f1 > 0 && $f1[0];
}

sub _ping_oldest_file {
    my ($dir,$excl) = @_;
    my $file = _oldest_file($dir,$excl);
    return unless $file;
    my $file0 = $file;
    $file0 =~ s/.*$LOCKFILE_STUB.//;
    my ($time, $type, $host, $pid, $tid) = split /_/, $file0;
    $pid =~ s/\D+$//;
    $_DEBUG && print STDERR _pid(), ": ping  host=$host pid=$pid tid=$tid\n";
    $_DEBUG && print STDERR "$dir holds:\n", join(" ",glob("$dir/*")),"\n";
    my $status;


    # TODO: what if $tid is defined? How do you signal a thread
    # and how do you signal or terminate a remote thread?
    
    if ($host eq _host() || $host eq 'localhost') {
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
        warn "Dir::Flock: lock holder that created $file appears dead\n";
        unlink $file;
    }
}

sub _refresh_dir {
    # https://stackoverflow.com/a/30630912
    # "Within a given process, calling opendir and closedir on the
    #  parent directory of a file invalidates the NFS cache."
    my $dir = shift;
    my $dh;
    if (opendir $dh, $dir) {
	closedir $dh;
    } else {
	warn "_refresh_dir: failed to open handle to dir '$dir'";
    }
    return;
}

sub _validate_dir {
    my $dir = shift;
    if (! -d $dir) {
        $errstr = "lock dir '$dir' is not a directory";
        carp "Dir::Flock::lock: $errstr";
        return;
    }
    if (! -r $dir && -w $dir && -x $dir) {
        $errstr = "lock dir '$dir' is not an accessible directory";
        carp "Dir::Flock::lock: $errstr";
        return;
    }
    _refresh_dir($dir);
    1;
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
    my $p = _pid();
    no warnings 'redefine';
    *DB::DB = sub {};
    *__inGD = sub () { 1 };
    unlink grep{ $TMPFILE{$_} eq $p } keys %TMPFILE;
}

1;

=head1 NAME

Dir::Flock - advisory locking of a dedicated directory



=head1 VERSION

0.08_01



=head1 SYNOPSIS

    use Dir::Flock;
    my $dir = Dir::Flock::getDir("/home/mob/projects/foo");
    my $success = Dir::Flock::lock($dir);
    # ... synchronized code
    $success = Dir::Flock::unlock($dir);

    # flock semantics
    use Fcntl ':flock';
    $success = Dir::Flock::flock($dir, LOCK_EX | LOCK_NB);
    ...
    Dir::Flock::flock($dir, LOCK_UN);

    # mutex/scoping semantics
    {
        my $lock = Dir::Flock::lockobj($dir);
        ... synchronized code ...
    }   # lock released when $lock goes out of scope

    # code ref semantics
    Dir::Flock::sync {
        ... synchronized code ...
    }, $dir



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
node maintains a cache that includes file contents and file metadata.
When a system call wants to check whether a lock exists on a file, 
the filesystem driver might inspect the cached file rather than 
the file on the server, and it might miss an action taken by another 
node to lock a file.

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

=head2 Semantics

This module offers several different semantics for advisory
locking of a directory.

=head3 functional semantics

The core L<Dir::Flock::lock|/"lock"> and
L<Dir::Flock::unlock|/"unlock"> functions begin and end advisory
locking on a directory. All of the other semantics are implemented in
terms of these functions.

    $ok = Dir::Flock::lock( "/some/path" );
    $ok = Dir::Flock::lock( "/some/path", $timeout );
    $ok = Dir::Flock::unlock( "/some/path" );

=head3 flock semantics

The function L<Dir::Flock::flock|/"flock"> emulates the Perl
L<flock|perlfunc/"flock"> builtin, accepting the same arguments
for the operation argument.

    use Fcntl ':flock';
    $ok = Dir::Flock::flock( "/some/path", LOCK_EX );
    ...
    $ok = Dir::Flock::flock( "/some/path", LOCK_UN );

=head3 scope-oriented semantics

The L<Dir::Flock::lockobj|/"lockobj"> function returns an
object representing a directory lock. The lock is released
when the object goes out of scope.

    {
        my $lock = Dir::Flock::lockobj( "/some/path" );
        ...
    }   # $lock out of scope, lock released

=head3 BLOCK semantics

The L<Dir::Flock::sync|/"sync"> accepts a block of code or other
code reference, to be executed with an advisory lock on a
directory.

    Dir::Flock::sync {
       ... synchronized code ...
    } "/some/path";


=head1 FUNCTIONS

Most functions return a false value and set the package variable
C<$Dir::Flock::errstr> if they are unsuccessful.


=head2 lock

=head2 lock_ex

=head2 $success = Dir::Flock::lock( $directory [, $timeout ] )

=head2 $success = Dir::Flock::lock_ex( $directory [, $timeout ] )

Attempts to obtain an I<exclusive> lock on the given directory. While
the directory is locked, the C<lock> or C<lock_sh> call on the
same directory from
other processes or threads will block until the directory is unlocked
(see L<"unlock">). Returns true if the lock was successfully acquired.

If an optional C<$timeout> argument is provided, the function will
try for at least C<$timeout> seconds to acquire the lock, and return
a false value if it is not successful in that time. Use a timeout of
zero to make a "non-blocking" exclusive lock request.


=head2 lock_sh

=head2 $success = Dir::Flock::lock_sh( $directory [, $timeout ] )

Attempts to obtain a I<shared> lock on the given directory.
While there are shared locks on a directory, other calls to C<lock_sh>
may also receive a shared lock on the directory but calls to
C<lock>/C<lock_ex> on the directory will block until all
shared locks are removed.

If an optional C<$timeout> argument is provided, the function will
try for at least C<$timeout> seconds to acquire the lock, and
return a false value if it is not successful in that time.
Use a timeout of zero to make a "non-blocking" shared lock request.


=head2 unlock

=head2 $success = Dir::Flock::unlock( $directory )

Releases the exclusive or shared lock on the given directory held
by this process. Returns a false value if the current process did
not possess the lock on the directory.


=head2 getDir

=head2 $tmp_directory = Dir::Flock::getDir( $root [,$persist] )

Creates a temporary and empty directory in a subdirectory of C<$root>
that is suitable for use as a synchronization directory. The directory
will automatically be cleaned up when the process that called this
function exits (unless a true value is provided for the optional
C<$persist> argument).

If the input to C<getDir> is a filename rather than a directory name,
a new subdirectory will be created in the directory where the file
is located.


=head2 flock

=head2 $success = Dir::Flock::flock( $dir, $op )

Acquires and releases advisory locks on the given directory
with the same semantics as the Perl builtin
L<flock|perlfunc/"flock"> function. 



=head2 lockobj

=head2 lockobj_ex

=head2 $lock = Dir::Flock::lockobj( $dir [, $timeout] );

=head2 $lock = Dir::Flock::lockobj_ex( $dir [, $timeout] );

Attempts to acquire an exclusive advisory lock for the given
directory. On success, returns a handle to the directory lock
with the feature that the lock will be released when the handle
goes out of scope. This allows you to use this module with
syntax such as

    {
        my $lock = Dir::Flock::lockobj( "/some/path" );
        ... synchronized code ...
    }
    # $lock out of scope, so directory lock released
    ... unsynchronized code ...

Optional C<$timeout> argument causes the function to block
for a maximum of C<$timeout> seconds attempting to acquire
the lock. If C<$timeout> is not provided or is C<undef>,
the function will block indefinitely while waiting for the
lock.

Returns a false value and may sets C<$Dir::Flock::errstr> if the function
times out or is otherwise unable to acquire the directory lock.

C<lockobj_ex> is an alias for C<lockobj>.


=head2 lockobj_sh

=head2 my $lock = Dir::Flock::lockobj_sh($dir [, $timeout])

Analogue to L<"lockobj_ex">. Returns a reference to a shared lock
on a directory that will be released when the reference goes
out of scope.

Returns a false value and may set C<$Dir::Flock::errstr> if the 
function times out or otherwise fails to acquire a shared lock 
on the directory.


=head2 sync

=head2 sync_ex

=head2 $result = Dir::Flock::sync CODE $dir [, $timeout]

=head2 @result = Dir::Flock::sync_ex CODE $dir [, $timeout]

Semantics for executing a block of code while there is an
advisory exclusive lock on the given directory. The code can
be evaluated in both scalar or list contexts. An optional
C<$timeout> argument will cause the function to give up and
return a false value if the lock cannot be acquired after
C<$timeout> seconds. Callers should be careful to distinguish
cases where the specified code reference returns nothing and
where the C<sync> function times out and returns nothing.
One way to distinguish these cases is to check the value of
C<$Dir::Flock::errstr>, which will generally be set if there
was an issue with the locking mechanics.

The lock is released in the event that the given C<$code>
produces a fatal error.


=head2 sync_sh

=head2 $result = Dir::Flock::sync_sh BLOCK $dir [, $timeout]

=head2 @result = Dir::Flock::sync_sh BLOCK $dir [, $timeout]

Analogue of L<"sync_ex"> but executes the code block while
there is an advisory shared lock on the given directory.


=head1 DEPENDENCIES

C<Dir::Flock> requires L<Time::HiRes> where the C<Time::HiRes::time>
function has subsection resolution.


=head1 EXPORTS

Nothing is exported from C<Dir::Flock> by default, but all of
the functions documented here may be exported by name.

Many of the core functions of C<Dir::Flock> have the same name
as Perl builtin functions or functions from other popular modules,
so users should be wary of importing functions from this module
into their working namespace.



=head1 VARIABLES

=head2 PAUSE_LENGTH

=head2 $Dir::Flock::PAUSE_LENGTH

C<$Dir::Flock::PAUSE_LENGTH> is the average number of seconds that
the module will wait after a failed attempt to acquire a lock before
attempting to acquire it again. The default value is 0.001,
which is a good setting for having a high throughput when the
synchronized operations take a short amount of time. In contexts
where the synchronized operations take a longer time, it may
be appropriate to increase this value to reduce busy-waiting CPU
utilization.

=cut

# also under VARIABLES: HEARTBEAT_CHECK

# =head1 ENVIRONMENT    =>   DIR_FLOCK_DEBUG

# =cut
    


=head1 LIMITATIONS

See L<"System requirements"> above.

The L<Dir::Flock::Mock> module can be loaded when necessary
to provide a consistent synchronization API on systems that
require C<Dir::Flock> to work properly and on systems that
don't support C<Dir::Flock>.

=cut

# =head1 SEE ALSO  L<Mail::Box::Locker::NFS>, L<File::NFSLock>.
#        L<File::SharedNFSLock>, L<IPC::ConcurrencyLimit::Lock::NFS>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dir::Flock


You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dir-Flock>

=item * E<lt>mob@cpan.orgE<gt>

With the decommissioning of http://rt.cpan.org/, 
please send bug reports and feature requests
directly to the author's email address.

=back




=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>




=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019-2020, Marty O'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut



=begin TODO

Heartbeat

    a running process should be able to update the timestamp of
    their lockfiles (either the mtime known to the filesystem or
    in the file data themselves) to let other processes (on the
    same and other hosts) know that the locking process is still
    alive. Can you do that without releasing the lock?

    Include heartbeat data in the file names?

Threads

    In  _ping_oldest_file , how to detect whether a thread is
    still alive? How to detect whether a thread on a remote
    machine is still alive?

=end TODO
