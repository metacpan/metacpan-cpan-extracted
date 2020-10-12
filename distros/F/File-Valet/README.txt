NAME
    File::Valet - Utilities for file slurping, locking, and finding.

SYNOPSIS
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

        # Find the most likely home directory:
        my $home = find_home();

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

DESCRIPTION
    File::Valet contains a selection of easy-to-use subroutines for
    manipulating files and file content. Some effort has been made to
    establish cross-platform portability, and to make their behavior as
    unsurprising as possible.

FUNCTIONS
    The following functions are available through this module for use in
    other applications. In keeping with the intent of minimizing user
    keystrokes, all of these functions are exported into the calling
    namespace.

    rd_f
         my $string = rd_f($filename);

        "rd_f()" is similar to the well-known "Slurp::to_scalar()", in that
        it reads the entire contents of the named file and returns it as a
        string. Its principle differences are a slightly shorter name and
        the insertion of diagnostic information into $File::Valet::OK,
        $File::Valet::ERROR, $File::Valet::ERRNO when the operation failed
        to complete.

        The return value is either the contents of the file as a string of
        bytes (an empty string if the file had no contents), or undef on any
        error.

    wr_f
         my $success = wr_f($filename, $string);

        "wr_f()" is conceptually the opposite of "rd_f()", in that it
        overwrites the named file's contents with the given string of bytes.

        If the specified file does not exist, "wr_f()" will attempt to
        create it.

        Returns 1 on success, or 0 on any failure, and sets
        $File::Valet::OK, $File::Valet::ERROR, $File::Valet::ERRNO
        appropriately.

    ap_f
         my $success = ap_f($filename, $string);

        "ap_f()" is similar to "wr_f()", differing in that the specified
        string of bytes is appended to the end of the file, rather than
        overwriting it.

        If the specified file does not exist, "ap_f()" will attempt to
        create it.

        Returns 1 on success, or 0 on any failure, and sets
        $File::Valet::OK, $File::Valet::ERROR, $File::Valet::ERRNO
        appropriately.

    find_home
         my $path = find_home;
         my $path = find_temp("/var/home", "/tmp/home");

        "find_home()" performs a best-effort search for the effective user's
        home, returning a path-string or undef if none is found.

        If arguments are provided, it will return the first argument for
        which there is a directory for which the user has write permissions.

        if $ENV{HOME} is set, "find_home()" will check there for a writable
        directory after checking any arguments.

        Some effort has been made to make it cross-platform.

    find_temp
         my $path = find_temp();
         my $path = find_temp("/home/tmp", "/usr/tmp", ...);

        Intended for easy cross-platform programming, "find_temp()" checks
        in a number of likely, common filesystem locations for a valid
        directory for temporary files. It returns the first directory it
        finds for which the user has write permissions, or undef if none is
        found.

        If parameters are passed to "find_temp()", it will check those
        locations first.

        If $ENV{TEMPDIR}, $ENV{TEMP} or $ENV{TMP} are defined, "find_temp()"
        will check those locations after checking the locations provided as
        parameters.

        "find_temp()" is Windows-savvy enough to check such locations as
        "C:\Windows\Temp", but might try to open locations on
        network-mounted drives if it is unable to find a local alternative.

    find_bin
         my $pathname = find_bin("ls");
         my $pathname = find_bin("ls", "/home/ttk/bin", "/opt/bin", ...);

        Another function intended for easy cross-platform programming,
        "find_bin()" will first check all of the directories in $ENV{PATH}
        (if defined), and then in number of other likely, common locations,
        for an executable file whose name matches the first parameter. It
        will return the full absolute pathname of the executable file on
        success, or undef on failure.

        "find_bin()" is Windows-savvy, albeit does not search Windows
        systems as extensively as others.

        If directory paths are given as additional parameters, "find_bin()"
        will check those locations first.

        "find_bin()" is smart enough to only check any given directory once,
        even if it appears in the parameter list as well as in $ENV{PATH},
        or appears multiple times in either.

        "find_bin()" also sets $File::Valet::OK, $File::Valet::ERROR,
        $File::Valet::ERRNO appropriately.

    lockafile
         my $success = lockafile("/tmp/foo", %options);
         my $success = lockafile("/tmp/foo",
             limit => 2.0,  # keep retrying for 2.0 seconds before giving up
             msg   => 'in-channel update',  # helpful message for troubleshooting
             nsec  => 0.5,  # we expect to hold the lock for less than 0.5 seconds
         );

        "lockafile()" applies an advisory lock on the named file, and
        attempts to be somewhat clever about it, automatically invalidating
        existing locks set by processes which no longer exist. or set a very
        long time ago.

        If the file is already locked by another process, "lockafile()" will
        linger and attempt to acquire the lock when the owner of the lock
        releases the file. This linger time defaults to thirty seconds, and
        may be overridden with the "limit" parameter.

        The advisory lock takes the form of a file, which may be manually
        deleted to remove the lock, or may be inspected to learn something
        about the process which created the lock. To facilitate this, a
        message may be embedded in the lock file describing the reason the
        file is being locked. It defaults to "programmer is lazy", and may
        be set by passing the "msg" parameter.

        Advisory locks will be respected by other invocations of
        "lockafile()" for up to some time before being assumed stale and
        forceably removed. This period may be increased by passing the
        "nsec" parameter (which becomes embedded in the lockfile).

        "lockafile()" attempts to manage nested advisory locks via
        %File::Valet::LOCKS_HASH. "lockafile()" will keep track of which
        files the caller has locked, and how many times. Thus if the caller
        locks the same file two or more times, and unlocks it an equal
        number of times, the lock file will only be created on the first
        invocation of "lockafile()", and removed only on the last invocation
        of "unlockafile()". See FURTHER DEVELOPMENT for caveats regarding
        this.

        Returns 1 on success, or 0 on any failure, and sets
        $File::Valet::OK, $File::Valet::ERROR, $File::Valet::ERRNO
        appropriately.

    unlockafile
         my $success = unlockafile("/tmp/foo", %options);

        "unlockafile()" reverses the action of "lockafile()", removing an
        advisory lock on a file (or reducing the count of locks on a
        multiply-locked file).

        "unlockafile()" will fail if invoked on a file which is not locked,
        or has been locked by a different process.

        "unlockafile()" returns 1 on success, and 0 on any failure, and sets
        $File::Valet::OK, $File::Valet::ERROR, $File::Valet::ERRNO
        appropriately.

    unlock_all_the_files
        "unlock_all_the_files()" is a convenience wrapper for walking
        %File::Valet::LOCKS_HASH and safely removing all lockfiles.

        If your code has bugs which cause it to leave lockfiles behind, then
        calling "unlock_all_the_files()" before exiting will help prevent
        that.

        Really, though, you should fix your bugs.

        Returns three values: A count of errors returned by "unlockafile()",
        a count of locks removed, and a count of lock files removed.

        The number of locks can differ from the number of lock files when
        locks are nested. A file which is locked twice counts as two locks
        but has only one lock file.

    LOCKFILE FORMAT
        The lockfiles contain useful bits of information which help
        "lockafile" figure out if it should override someone else's lock,
        and is also useful for gaining insight about the system's behavior,
        for troubleshooting purposes.

        Its fields are tab-delimited, and the file terminates with a
        newline. They appear in this order:

            * Process identifier of the process which created the lockfile (per "$$"),
            * The number of seconds the lock should be considered valid (per "nsec" parameter),
            * The helpful message provided by the programmer (per "msg" parameter),
            * The name of the program which created the lockfile (per "$0")

        Example:

            "4873\t2.0\tThe programmer is lame\t/opt/simon/bin/simond\n"

        These fields may change in future versions of this module.

    FURTHER DEVELOPMENT
        A recursive descent function similar to File::Find
        <https://metacpan.org/pod/File::Find> is planned, since "File::Find"
        is pretty horrible and unusable.

        The "lockafile()" implementation goes through considerable effort to
        avoid race conditions, but there is still a very short danger window
        where an overridden lock might get double-clobbered. If a contended
        lock expires just when two or more other processes call
        "lockafile()" on it, it is possible for one process to unlink the
        lock file, the other process to create a new lock file, and then the
        first process to overwrite that lock file with its own lock file,
        leaving both processes under the impression they have acquired the
        lock. Future implementations may remedy this. In the meantime the
        possibility can be avoided by setting a sufficiently large "nsec"
        value when acquiring a lock that it will not expire before the
        owning process is ready to release it.

        The nested lock management "lockafile()" and "unlockafile()"
        implement is flawed, in that the lock on the file is only valid for
        as long specified by the first invocation of "lockafile()". Thus if
        a file is locked for 3 seconds, and then subsequently locked for 30
        seconds, other processes contending for the locked file will
        forceably acquire the lock after 3 seconds after the first lock, not
        30 seconds after the second lock. Future implementations may
        overwrite the lockfile to reflect the parameters of subsequent
        (nested) locks.

        The file-slurping functions handle data explicitly as bytes and
        never as codepoints. This is intentional and unlikely to change. If
        codepoint handling (utf-8, utf-16, etc) is desired, see
        File::Slurper <https://metacpan.org/pod/File::Slurper>.

    SEE ALSO
        File::Slurper <https://metacpan.org/pod/File::Slurper> is considered
        the likely successor to "File::Slurp" for CPAN's primary
        file-slurping implementation, with proper handling of
        multibyte-encoded characters (which is broken
        <http://blogs.perl.org/users/leon_timmermans/2015/08/fileslurp-is-br
        oken-and-wrong.html> in "File::Slurp"). If "File::Slurper"
        implemented an appending method, the slurp functions would likely be
        absent from "File::Valet". Until then, "File::Valet"'s slurping
        functions provide a simple, robust alternative.

        Path::Tiny <https://metacpan.org/pod/Path::Tiny> - a different style
        for file handling, which some people might prefer.

        File::Temp <https://metacpan.org/pod/File::Temp> - returns name and
        handle of a temporary file.

        File::SearchPath <https://metacpan.org/pod/File::SearchPath> -
        searches an environment path for a file.

        Lock::File <https://metacpan.org/pod/Lock::File> - file locker with
        an automatic out-of-scope unlocking mechanism.

        NL::File::Lock <https://metacpan.org/pod/NL::File::Lock> - file
        locker with timeout, but no lock expiration.

        File::Lock::Multi <https://metacpan.org/pod/File::Lock::Multi> -
        file locker with support for nested locks.

        File::TinyLock <https://metacpan.org/pod/File::TinyLock> - a very
        easy to use file locker.

AUTHOR
    TTK Ciar

LICENSE
    You can use and distribute this module under the same terms as Perl
    itself.

