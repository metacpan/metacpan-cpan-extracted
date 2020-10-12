package File::Valet;
use 5.010;
use strict;
use warnings;
use Config;   # Provides OS-portable means of determining platform type
use POSIX;
use File::Basename qw(fileparse);
use File::Copy;
use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    $VERSION = '1.08';
    @EXPORT = @EXPORT_OK = qw(rd_f wr_f ap_f find_home find_temp find_bin lockafile unlockafile unlock_all_the_files);
}

our $OK     = 'OK'; # one of "OK", "WARNING" or "ERROR", reflecting most recently performed operation
our $ERROR  = '';   # short invariant description of error, or empty string if none
our $ERRNO  = '';   # variant description of error (such as $!), or empty string if none
our $ERRNUM =  0;   # numerical variant description of error (such as $!), or empty string if none, undocumented, only used for unit tests
our %LOCKS_HASH;    # keys on lockfile to bind count, for supporting nested locks.

# File::Copy::move() almost doest the right thing, just needs syscopy() as failover instead of copy().
# This _rename() function more or less duplicates the needed functionality of File::Copy::_move's logic after the rename,
# but uses syscopy() and captures failures in $OK, $ERROR, $ERRNO, $ERRNUM.
sub _rename {
    my ($from, $to) = @_;

    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
    return 'OK' if (rename ($from, $to));

    my $result = File::Copy::syscopy($from, $to);
    unless ($result) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'File::Copy::syscopy failed', $!, 0+$!);
        return undef;
    }

    my @st = stat($from);
    unless (@st) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'after-copy stat failed', $!, 0+$!);
        return undef;
    }

    my ($atime, $mtime) = (@st)[8,9];
    unless (utime($atime, $mtime, $to)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'after-copy utime failed', $!, 0+$!);
        return undef;
    }

    unless (unlink($from)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'after-copy unlink failed', $!, 0+$!);
        return undef;
    }
    return 'OK';
}

sub rename_vms {
    my ($fn, $dest) = @_;
    if (!defined($fn) || ($fn eq '')) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'no filename supplied', -1, 0);
        return undef;
    }
    if (!defined($dest) || ($dest eq '')) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'no destination directory supplied', -1, 0);
        return undef;
    }
    my $dest_fn = $fn;
    if (!-d $dest) {
        ($dest, $dest_fn) = fileparse($dest);
    }
    if (!-e $dest) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'destination directory does not exist', -1, 0);
        return undef;
    }
    if (!-d _) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'destination directory is not a directory', -1, 0);
        return undef;
    }
    if (!-w _) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'destination directory is not writable', -1, 0);
        return undef;
    }

    if (!-e "$dest/$dest_fn") {
        # degenerate case; just rename it.
        return _rename($fn, "$dest/$dest_fn");
    }

    my $i = 1;
    $i++ while(-e "$dest/$dest_fn.$i");
    return _rename($fn, "$dest/$dest_fn.$i");
}

sub rd_f {
    my ($fn) = @_;
    my ($fh, $buf);
    if (!defined($fn) || ($fn eq '')) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'no filename supplied', -1, 0);
        return undef;
    }
    $! = 0;
    unless (open($fh, '< :raw', $fn)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', "cannot open for reading", $!, 0+$!);
        return undef;
    }
    binmode($fh);
    my $file_size = -s $fn;
    if (defined $file_size && $file_size == 0) {
        $buf = '';
    }
    elsif (defined $file_size) {
        my $n_bytes = sysread($fh, $buf, $file_size);
        if (!defined($n_bytes)) {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'read failed', $!, 0+$!);
            return undef;
        }
        elsif ($n_bytes != $file_size) {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'read underflow', $!, 0+$!);
            return undef;
        }
    }
    else {
        my $res = sysread($fh, $buf, 0xFFFFFFFF);
        if (!defined $res) {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'read failed', $!, 0+$!);
            return undef;
        }
    }
    my $res = close($fh);
    unless ($res) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'close failed', $!, 0+$!);
        return undef;
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
    return $buf;
}

sub wr_f {
    my ($fn, $buf) = @_;
    my $fh;
    if (!defined($fn) || ($fn eq '')) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'no filename supplied', -1, 0);
        return undef;
    }
    $! = 0;
    unless (open($fh, '> :raw', $fn)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', "cannot open for writing", $!, 0+$!);
        return undef;
    }
    binmode($fh);
    my $res = syswrite($fh, $buf);
    unless (defined $res) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'write error', $!, 0+$!);
        return undef;
    }
    $res = close($fh);
    unless ($res) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'close failed', $!, 0+$!);
        return undef;
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
    return 'OK';
}

sub ap_f {
    my ($fn, $buf) = @_;
    my $fh;
    if (!defined($fn) || ($fn eq '')) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'no filename supplied', -1, 0);
        return undef;
    }
    $! = 0;
    unless (open($fh, '>> :raw', $fn)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', "cannot open for appending", $!, 0+$!);
        return undef;
    }
    binmode($fh);
    my $res = syswrite($fh, $buf);
    unless (defined $res) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'write error', $!, 0+$!);
        return undef;
    }
    $res = close($fh);
    unless ($res) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'close failed', $!, 0+$!);
        return undef;
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
    return 'OK';
}

sub detect_windows {
    return ($^O eq 'MSWin32' || $Config{'osname'} =~ /windows/i || $Config{'osname'} =~ /winserver/i || $Config{'osname'} =~ /microsoft/i) ? 1 : 0;
}

sub find_home {
    for my $d (@_) {
        return $d if (defined $d && -d $d && -w _);
    }

    my $is_windows = detect_windows;
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);

    my $env_home = $ENV{HOME};
    return $env_home if (defined $env_home && -d $env_home);

    my $username = $ENV{USER} // $ENV{USERNAME};
    if ($is_windows) {
        my $home_drive = $ENV{HOMEDRIVE} // 'C:';
        my $home_path  = $ENV{HOMEPATH};
        if (defined $home_path) {
            $env_home = $home_drive . $home_path;
        }
        elsif (defined $username) {
            $env_home = $home_drive . '\\Users\\' . $username;
        }
        return $env_home if (defined $env_home && -d $env_home);
    } else {
        my @row = getpwuid($<);
        if (@row >= 9) {
          my $home_dir = $row[7];
          return $home_dir if (defined $home_dir && -d $home_dir);
        }
        return '/root' if (-d '/root' && -w '/root');
    }

    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'cannot find home directory', $is_windows, 1);
    return undef;
}

sub find_temp {
    my $is_windows = detect_windows;
    my $dir_sep_tok = '/';
    my $home_dir = find_home;

    push(@_, $ENV{TEMPDIR}) if (defined($ENV{TEMPDIR}));
    push(@_, $ENV{TEMP})    if (defined($ENV{TEMP}));
    push(@_, $ENV{TMP})     if (defined($ENV{TMP}));  # set in Windows sometimes

    if ($is_windows) {
        $dir_sep_tok = '\\';
        push(@_, 'C:\\Windows\\Temp');
        push(@_, 'D:\\Windows\\Temp');
        foreach my $vol (qw(C D E F G W X Y Z)) {
            push(@_, "$vol:\\Temp");
        }
    }
    # might be CygWin, so adding these regardless of OS:
    push(@_, qw (/var/tmp /tmp));

    push(@_, map {join($dir_sep_tok,("$home_dir",$_))} qw(.tmp .temp tmp temp), $home_dir) if (defined($home_dir));
    push(@_, map {join($dir_sep_tok,("$ENV{PWD}", $_))} qw(.tmp .temp tmp temp), $ENV{PWD} ) if (defined($ENV{PWD} ));
    push(@_, '/dev/shm') unless ($is_windows); # Lowest priority, since this is typically a ramdisk.
    foreach my $d (@_) {
        next unless (-d $d);
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
        return $d if (-w _);
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'no appropriate temporary directory found', '', 0);
    return undef;
}

sub find_bin {
    return find_bin_win32 (@_) if ($Config::Config{osname} =~ /MSWin/);
    my ($bin_name, @bin_dirs) = @_;
    my $home_dir = find_home;
    push(@bin_dirs, split(/\:/, $ENV{PATH})) if (defined($ENV{PATH}));
    push(@bin_dirs, "$home_dir/bin") if (defined($home_dir));
    push(@bin_dirs, ('/usr/local/sbin', '/usr/local/bin', '/sbin', '/bin', '/usr/sbin', '/usr/bin'));
    my %been_there = ();
    foreach my $d (@bin_dirs) {
        next if (defined($been_there{$d}));
        $been_there{$d} = 1;
        my $f = "$d/$bin_name";
        next unless (-x $f);
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
        return $f;
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'no executable found', '', 0);
    return undef;
}

sub find_bin_win32 {
    my ($bin_name, @bin_dirs) = @_;
    push(@bin_dirs, split(/\;/, $ENV{PATH})) if (defined($ENV{PATH}));
    push(@bin_dirs, ('C:\\WINDOWS\\system32', 'C:\\WINDOWS'));
    my %been_there = ();
    foreach my $d (@bin_dirs) {
        next if (defined($been_there{$d}));
        $been_there{$d} = 1;
        my $f = "$d\\$bin_name";
        next unless (-x $f);
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
        return $f;
    }
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'no executable found', '', 0);
    return undef;
}

# returns 1 on great success, 0 on miserable failure
sub lockafile {
    my ($f, %opt) = @_;
    $opt{nsec}  = 30 unless (defined($opt{nsec})  && int($opt{nsec}) > 0);  # Number of seconds we expect to have the file locked.  If we hold the lock for longer than this, other processes are welcome to kill us and take the lock themselves.
    $opt{msg}   = "programmer is lame" unless (defined($opt{msg})   && $opt{msg} ne '');  # Helpful message for the human to understand wtf this lock is about
    $opt{limit} = 30 unless (defined($opt{limit}) && int($opt{limit}) > 0); # Number of seconds caller is willing to wait for a lock before failing out.
    $opt{sleep_duration} = 0.25 unless (defined($opt{sleep_duration}) && $opt{sleep_duration} > 0.0);
    my $lockfile_name = $opt{lockfile_name} || "$f.lock";
    my $tm_start = time();
    my $lockfile_fh;

    # TODO - This is fast and simple, but fails to handle expired lockfiles and extending lockfile durations.
    if ($LOCKS_HASH{$f}) {
        $LOCKS_HASH{$f}++;
        return 1;
    }

    while (!sysopen($lockfile_fh, $lockfile_name, &O_RDWR | &O_CREAT | &O_EXCL)) {
        if (-e $lockfile_name) {
            # re-scanning after every sleep(), because it could expire while we are sleeping and someone else might grab it while we are sleeping.
            my $mtime = (stat(_))[9];
            my $txt   = File::Valet::rd_f($lockfile_name);

            if (!defined($txt)) {  # handling potential race condition or naughty unreadable lockfile
                if ((time() - $tm_start) > $opt{limit}) {
                    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('WARNING', 'lockfile racy or unreadable', $lockfile_name, 0);
                    return 0;
                }
                select(undef, undef, undef, $opt{sleep_duration});
                next;
            }

            chomp($txt);
            if ($txt =~ /^\d+\t/) {
                my ($pid, $lock_duration, $message, $whence) = split(/\t/, $txt);
                $lock_duration = 30 unless (defined($lock_duration));
                my $locking_process_still_lives = kill(0, $pid);
                # TODO - Potential race condition; another process might acquire the expired lock after this second stat() and before unlink().
                # Perhaps use senate?  Slow in filesystem, but could use shm on systems which support SysV shared memory.
                unlink($lockfile_name) if ((time() > $mtime + $lock_duration) || ($locking_process_still_lives < 1));
            }
        }

        if ((time() - $tm_start) > $opt{limit}) {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);  # Not an error; simply unable to acquire lock within specified duration
            return 0;
        }

        select(undef, undef, undef, $opt{sleep_duration});
    }
    my $msg = sprintf("\%d\t\%d\t%s\t%s\n", $$, $opt{nsec}, $opt{msg}, $0);    # populating lockfile with information about locking process
    syswrite($lockfile_fh, $msg);
    close($lockfile_fh);
    $LOCKS_HASH{$f} = 1;
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);
    return 1;
}

sub unlockafile {
    my ($f, %opt) = @_;
    my $lockfile_fh;
    my $dgram;
    my $lockfile_name = $opt{lockfile_name} || "$f.lock";
    ($OK, $ERROR, $ERRNO, $ERRNUM) = ('OK', '', '', 0);

    # TODO - This is fast and simple, but fails to handle expired lockfiles
    if ($LOCKS_HASH{$f}) {
        $LOCKS_HASH{$f}--;
        return 1 if ($LOCKS_HASH{$f} > 0);
    }
    $! = 0;
    unless (sysopen($lockfile_fh, $lockfile_name, &O_RDONLY)) {
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'open failure', $!, 0+$!);
        return 0;
    }
    unless(my $result = sysread($lockfile_fh, $dgram, 4095)) {
        if (defined($result)) {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'read zero bytes from lockfile', '', 0+$!);
        } else {
            ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'read error', $!, 0+$!);
        }
        return 0;
    }
    chomp($dgram);
    my ($lpid, $nsec, $msg, $whence) = split(/\t/, $dgram);
    close($lockfile_fh);
    $LOCKS_HASH{$f} = 0;
    if (defined($lpid) && ($lpid ne $$)) {
        # oops! not ours anymore
        ($OK, $ERROR, $ERRNO, $ERRNUM) = ('ERROR', 'lost lock', $dgram, 0+$!);
        return 0;
    }
    unlink($lockfile_name);
    return 1;
}

sub unlock_all_the_files {
    # Best effort only .. eh, make that "some effort only".
    # That might still be overly charitable.
    # Truth be told, you're only using this function if you can't be assed to fix the bugs in your own code,
    # which relieves me somewhat of any moral imperative.
    my $n_locks = 0;
    my $n_files = 0;
    my $n_errors = 0;
    foreach my $f (keys %LOCKS_HASH) {
        next unless ($LOCKS_HASH{$f});
        $n_locks += $LOCKS_HASH{$f};
        $LOCKS_HASH{$f} = 0;
        unlockafile($f);
        $n_errors++ unless ($OK eq 'OK');
        $n_files++;
    }
    return ($n_errors, $n_locks, $n_files);
}

1;

=head1 NAME

File::Valet - Utilities for file slurping, locking, and finding.

=head1 SYNOPSIS

    use File::Valet;

    # Simple slurp and unslurp with rd_f, wr_f, ap_f:

    my $text = rd_f('some/file.txt');
    die "slurp failure: $File::Valet::ERROR ($File::Valet::ERRNO)" unless ($File::Valet::OK eq 'OK');
    # or, equivalently:
    die "slurp failure: $File::Valet::ERROR ($File::Valet::ERRNO)" unless (defined($text));

    # Contents written will be same as that of "some/file.txt",
    # plus two lines appended at the end:

    wr_f('another/file.txt', $text);
    ap_f('another/file.txt', "Oh, and another thing:\n");
    ap_f('another/file.txt', "STOP BREATHING IN MY CUP\n");

    # Find a place suited to temporary files:
    my $tmp = find_temp();  # Likely /var/tmp or /tmp or C:\Windows\Temp

    # Find the full pathname of an executable:
    my $shell = find_bin('sh');  # Likely /bin/sh

    # Use a lockfile for exclusive access to a shared resource:
    lockafile("$tmp/shared.txt") or die "cannot obtain lock: $File::Valet::ERROR ($File::Valet::ERRNO)";
    my $text = rd_f("$tmp/shared.txt");
    unlockafile("$tmp/shared.txt") or die "unlock error: $File::Valet::ERROR ($File::Valet::ERRNO)";

    # Nested file locking:
    lockafile("shared.txt") or die "cannot obtain first lock";
    my $text = rd_f("$tmp/shared.txt");
    ...
    lockafile("shared.txt") or die "cannot obtain second lock";
    ap_f("$tmp/shared.txt", $data);
    unlockafile("$tmp/shared.txt");
    ...
    unlockafile("$tmp/shared.txt");

    # Your code has bugs, resulting in leaving lockfiles behind, but
    # instead of debugging you'd rather just remove all your locks:
    my ($n_errors, $n_locks, $n_files) = unlock_all_the_files();

=head1 DESCRIPTION

B<File::Valet> contains a selection of easy-to-use subroutines for manipulating files and file content.  Some effort has been made to establish cross-platform portability, and to make their behavior as unsurprising as possible.

=head1 FUNCTIONS

The following functions are available through this module for use in other applications.  In keeping with the intent of minimizing user keystrokes, all of these functions are exported into the calling namespace.

=over 4

=item B<rd_f>

 my $string = rd_f($filename);

C<rd_f()> is similar to the well-known C<Slurp::to_scalar()>, in that it reads the entire contents of the named file and returns it as a string.  Its principle differences are a slightly shorter name and the insertion of diagnostic information into C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> when the operation failed to complete.

The return value is either the contents of the file B<as a string of bytes> (an empty string if the file had no contents), or undef on any error.

=item B<wr_f>

 my $success = wr_f($filename, $string);

C<wr_f()> is conceptually the opposite of C<rd_f()>, in that it overwrites the named file's contents with the given B<string of bytes>.

If the specified file does not exist, C<wr_f()> will attempt to create it.

Returns 1 on success, or 0 on any failure, and sets C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> appropriately.

=item B<ap_f>

 my $success = ap_f($filename, $string);

C<ap_f()> is similar to C<wr_f()>, differing in that the specified B<string of bytes> is appended to the end of the file, rather than overwriting it.

If the specified file does not exist, C<ap_f()> will attempt to create it.

Returns 1 on success, or 0 on any failure, and sets C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> appropriately.

=item B<find_home>

 my $path = find_home;
 my $path = find_temp("/var/home", "/tmp/home");

C<find_home()> performs a best-effort search for the effective user's home, returning a path-string or undef if none is found.

If arguments are provided, it will return the first argument for which there is a directory for which the user has write permissions.

if C<$ENV{HOME}> is set, C<find_home()> will check there for a writable directory after checking any arguments.

Some effort has been made to make it cross-platform.

=item B<find_temp>

 my $path = find_temp();
 my $path = find_temp("/home/tmp", "/usr/tmp", ...);

Intended for easy cross-platform programming, C<find_temp()> checks in a number of likely, common filesystem locations for a valid directory for temporary files.  It returns the first directory it finds for which the user has write permissions, or undef if none is found.

If parameters are passed to C<find_temp()>, it will check those locations first.

If C<$ENV{TEMPDIR}>, C<$ENV{TEMP}> or C<$ENV{TMP}> are defined, C<find_temp()> will check those locations after checking the locations provided as parameters.

C<find_temp()> is Windows-savvy enough to check such locations as "C:\Windows\Temp", but might try to open locations on network-mounted drives if it is unable to find a local alternative.

=item B<find_home>

  my $path = find_home();
  my $path = find_home("/var/home/fred");

Another function intended for easy cross-platform programming, C<find_home()> will first check $ENV{HOME} on *nix or $ENV{HOMEDIRVE} and $ENV{HOMEPATH (on Windows) if defined, then in the system's passwd database, and then in a number of other likely locations, for a writable home directory for the effective user.

It will return the full absolute path of the home directory on success, or undef on failure.

=item B<find_bin>

 my $pathname = find_bin("ls");
 my $pathname = find_bin("ls", "/home/ttk/bin", "/opt/bin", ...);

Another function intended for easy cross-platform programming, C<find_bin()> will first check all of the directories in $ENV{PATH} (if defined), and then in a number of other likely, common locations, for an executable file whose name matches the first parameter.  It will return the full absolute pathname of the executable file on success, or undef on failure.

C<find_bin()> is Windows-savvy, albeit does not search Windows systems as extensively as others.

If directory paths are given as additional parameters, C<find_bin()> will check those locations first.

C<find_bin()> is smart enough to only check any given directory once, even if it appears in the parameter list as well as in $ENV{PATH}, or appears multiple times in either.

C<find_bin()> also sets C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> appropriately.

=item B<lockafile>

 my $success = lockafile("/tmp/foo", %options);
 my $success = lockafile("/tmp/foo",
     limit => 2.0,  # keep retrying for 2.0 seconds before giving up
     msg   => 'in-channel update',  # helpful message for troubleshooting
     nsec  => 0.5,  # we expect to hold the lock for less than 0.5 seconds
 );

C<lockafile()> applies an advisory lock on the named file, and attempts to be somewhat clever about it, automatically invalidating existing locks set by processes which no longer exist. or set a very long time ago.

If the file is already locked by another process, C<lockafile()> will linger and attempt to acquire the lock when the owner of the lock releases the file.  This linger time defaults to thirty seconds, and may be overridden with the C<limit> parameter.

The advisory lock takes the form of a file, which may be manually deleted to remove the lock, or may be inspected to learn something about the process which created the lock.  To facilitate this, a message may be embedded in the lock file describing the reason the file is being locked.  It defaults to "programmer is lazy", and may be set by passing the C<msg> parameter.

Advisory locks will be respected by other invocations of C<lockafile()> for up to some time before being assumed stale and forceably removed.  This period may be increased by passing the C<nsec> parameter (which becomes embedded in the lockfile).

C<lockafile()> attempts to manage nested advisory locks via C<%File::Valet::LOCKS_HASH>.  C<lockafile()> will keep track of which files the caller has locked, and how many times.  Thus if the caller locks the same file two or more times, and unlocks it an equal number of times, the lock file will only be created on the first invocation of C<lockafile()>, and removed only on the last invocation of C<unlockafile()>.  See B<FURTHER DEVELOPMENT> for caveats regarding this.

Returns 1 on success, or 0 on any failure, and sets C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> appropriately.

=item B<unlockafile>

 my $success = unlockafile("/tmp/foo", %options);

C<unlockafile()> reverses the action of C<lockafile()>, removing an advisory lock on a file (or reducing the count of locks on a multiply-locked file).

C<unlockafile()> will fail if invoked on a file which is not locked, or has been locked by a different process.

C<unlockafile()> returns 1 on success, and 0 on any failure, and sets C<$File::Valet::OK>, C<$File::Valet::ERROR>, C<$File::Valet::ERRNO> appropriately.

=item B<unlock_all_the_files>

C<unlock_all_the_files()> is a convenience wrapper for walking C<%File::Valet::LOCKS_HASH> and safely removing all lockfiles.

If your code has bugs which cause it to leave lockfiles behind, then calling C<unlock_all_the_files()> before exiting will help prevent that.

Really, though, you should fix your bugs.

Returns three values:  A count of errors returned by C<unlockafile()>, a count of locks removed, and a count of lock files removed.

The number of locks can differ from the number of lock files when locks are nested.  A file which is locked twice counts as two locks but has only one lock file.

=item B<LOCKFILE FORMAT>

The lockfiles contain useful bits of information which help C<lockafile> figure out if it should override someone else's lock, and is also useful for gaining insight about the system's behavior, for troubleshooting purposes.

Its fields are tab-delimited, and the file terminates with a newline.  They appear in this order:

    * Process identifier of the process which created the lockfile (per "$$"),
    * The number of seconds the lock should be considered valid (per "nsec" parameter),
    * The helpful message provided by the programmer (per "msg" parameter),
    * The name of the program which created the lockfile (per "$0")

Example:

    "4873\t2.0\tThe programmer is lame\t/opt/simon/bin/simond\n"

These fields may change in future versions of this module.

=item B<FURTHER DEVELOPMENT>

A recursive descent function similar to L<File::Find|https://metacpan.org/pod/File::Find> is planned, since C<File::Find> is pretty horrible and unusable.

The C<lockafile()> implementation goes through considerable effort to avoid race conditions, but there is still a very short danger window where an overridden lock might get double-clobbered.  If a contended lock expires just when two or more other processes call C<lockafile()> on it, it is possible for one process to unlink the lock file, the other process to create a new lock file, and then the first process to overwrite that lock file with its own lock file, leaving both processes under the impression they have acquired the lock.  Future implementations may remedy this.  In the meantime the possibility can be avoided by setting a sufficiently large "nsec" value when acquiring a lock that it will not expire before the owning process is ready to release it.

The nested lock management C<lockafile()> and C<unlockafile()> implement is flawed, in that the lock on the file is only valid for as long specified by the first invocation of C<lockafile()>.  Thus if a file is locked for 3 seconds, and then subsequently locked for 30 seconds, other processes contending for the locked file will forceably acquire the lock after 3 seconds after the first lock, not 30 seconds after the second lock.  Future implementations may overwrite the lockfile to reflect the parameters of subsequent (nested) locks.

The file-slurping functions handle data explicitly as B<bytes> and never as codepoints.  This is intentional and unlikely to change.  If codepoint handling (utf-8, utf-16, etc) is desired, see L<File::Slurper|https://metacpan.org/pod/File::Slurper>.

=item B<SEE ALSO>

L<File::Slurper|https://metacpan.org/pod/File::Slurper> is considered the likely successor to C<File::Slurp> for CPAN's primary file-slurping implementation, with proper handling of multibyte-encoded characters (L<which is broken|http://blogs.perl.org/users/leon_timmermans/2015/08/fileslurp-is-broken-and-wrong.html> in C<File::Slurp>).  If C<File::Slurper> implemented an appending method, the slurp functions would likely be absent from C<File::Valet>.  Until then, C<File::Valet>'s slurping functions provide a simple, robust alternative.

L<Path::Tiny|https://metacpan.org/pod/Path::Tiny> - a different style for file handling, which some people might prefer.

L<File::Temp|https://metacpan.org/pod/File::Temp> - returns name and handle of a temporary file.

L<File::SearchPath|https://metacpan.org/pod/File::SearchPath> - searches an environment path for a file.

L<Lock::File|https://metacpan.org/pod/Lock::File> - file locker with an automatic out-of-scope unlocking mechanism.

L<NL::File::Lock|https://metacpan.org/pod/NL::File::Lock> - file locker with timeout, but no lock expiration.

L<File::Lock::Multi|https://metacpan.org/pod/File::Lock::Multi> - file locker with support for nested locks.

L<File::TinyLock|https://metacpan.org/pod/File::TinyLock> - a very easy to use file locker.

L<Data::Munge|https://metacpan.org/pod/Data::Munge> - a gaggle of useful functions, including a simple slurp().

=back

=head1 AUTHOR

TTK Ciar

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.

=cut
