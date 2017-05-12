# NAME

IPC::Pipeline - Create a shell-like pipeline of many running commands

# SYNOPSIS

    use IPC::Pipeline;

    my @pids = pipeline( my $first_child_in, my $last_child_out, my $err,
        [qw(filter1 args)],
        sub { filter2(); return 0 },
        [qw(filter3 args)],
        ...
        [qw(commandN args)]
    );

    ... do stuff ...

    my %statuses = map {
        waitpid($_, 0);
        $_ => ($? >> 8);
    } @pids;

# DESCRIPTION

__IPC::Pipeline__ exports a single function `pipeline()`.

Similar in calling convention to [IPC::Open3](https://metacpan.org/pod/IPC::Open3), `pipeline()` spawns N children,
connecting the first child to the `$first_child_in` handle, the final child to
`$last_child_out`, and each child to a shared standard error handle, `$err`.
Each subsequent filter specified causes a new process to be `fork()`ed.  Each
process is linked to the last with a file descriptor pair created by `pipe()`,
using `dup2()` to chain each process' standard input to the last standard output.

__IPC::Pipeline__ does not work on __MSWin32__, but it works on __cygwin__.

## FEATURES

__IPC::Pipeline__ accepts external commands to be executed in the form of ARRAY
references containing the command name and each argument, as well as CODE
references that are executed within their own processes as well, each as
independent parts of a pipeline.

### ARRAY REFS

When a filter is passed in the form of an ARRAY containing an external system
command, each such item is executed in its own subprocess in the following
manner.

    exec(@$filter) or die("Cannot exec(): $!");

### CODE REFS

When a filter is passed in the form of a CODE ref, each such item is executed in
its own subprocess in the following way.

    exit $filter->();

## BEHAVIOR

If fileglobs or numeric file descriptors are passed in any of the three
positional parameters, then they will be duplicated onto the file handles
allocated as a result of the process pipelining.  Otherwise, simple scalar
assignment will be performed.

Like [IPC::Open3](https://metacpan.org/pod/IPC::Open3), `pipeline()` returns immediately after spawning the process
chain, though differing slightly in that the IDs of each process is returned
in order of specification in a list when called in array context.  When called
in scalar context, an ARRAY reference of the process IDs will be returned.

Also like [IPC::Open3](https://metacpan.org/pod/IPC::Open3), one may use `select()` to multiplex reading and writing
to each of the handles returned by `pipeline()`, preferably with non-buffered
[sysread()](https://metacpan.org/pod/perlfunc#sysread) and [syswrite()](https://metacpan.org/pod/perlfunc#syswrite) calls.  Using
this to handle reading standard output and error from the children is ideal, as
blocking and buffering considerations are alleviated.

## CAVEATS

If any child process dies prematurely, or any of the piped file handles are
closed for any reason, the calling process inherits the kernel behavior of
receiving a `SIGPIPE`, which requires the installation of a signal handler for
appropriate recovery.

Unlike [IPC::Open3](https://metacpan.org/pod/IPC::Open3), __IPC::Pipeline__ will NOT redirect child process stderr to
stdout if no file handle for stderr is specified.  As of version 0.6, the caller
will always need to handle standard error, to prevent any children from
blocking; it would make little sense to pass one process' standard error as an
input to the next process.

# EXAMPLE ONE - OUTPUT ONLY

The following example implements a quick and dirty, but relatively sane tar and
gzip solution.  For proper error handling from any of the children, use `select()`
to multiplex the output and error streams.

    use IPC::Pipeline;

    my @paths = qw(/some /random /locations);

    open(my $err, '<', '/dev/null');

    my @pids = pipeline(my ($in, $out), $err,
        [qw(tar pcf -), @paths],
        ['gzip']
    );

    open(my $fh, '>', 'file.tar.gz');
    close $in;

    while (my $len = sysread($out, my $buf, 512)) {
        syswrite($fh, $buf, $len);
    }

    close $fh;
    close $out;

    #
    # We may need to wait for the children to die in some extraordinary
    # circumstances.
    #
    foreach my $pid (@pids) {
        waitpid($pid, 1);
    }

# EXAMPLE TWO - INPUT AND OUTPUT

The following solution implements a true I/O stream filter as provided by any
Unix-style shell.

    use IPC::Pipeline;

    open(my $err, '<', '/dev/null');

    my @pids = pipeline(my ($in, $out), $err,
        [qw(tr A-Ma-mN-Zn-z N-Zn-zA-Ma-m)],
        [qw(cut -d), ':', qw(-f 2)]
    );

    my @records = qw(
        foo:bar:baz
        eins:zwei:drei
        cats:dogs:rabbits
    );

    foreach my $record (@records) {
        print $in $record ."\n";
    }

    close $in;

    while (my $len = sysread($out, my $buf, 512)) {
        syswrite(STDOUT, $buf, $len);
    }

    close $out;

    foreach my $pid (@pids) {
        waitpid($pid, 1);
    }

# EXAMPLE THREE - MIXING COMMANDS AND CODEREFS

The following solution demonstrates the ability of IPC::Pipeline to execute CODE
references in the midst of a pipeline.

    use IPC::Pipeline;

    open(my $err, '<', '/dev/null');

    my @pids = pipeline(my ($in, $out), $err,
        sub { print 'cats'; return 0 },
        [qw(tr acst lbhe)]
    );

    close $in;

    while (my $line = readline($out)) {
        chomp $line;
        print "Got '$line'\n";
    }

    close $out;

# SEE ALSO

- [IPC::Open3](https://metacpan.org/pod/IPC::Open3)
- [IPC::Run](https://metacpan.org/pod/IPC::Run), for a Swiss Army knife of Unix I/O gizmos

    It should be mentioned that mst's [IO::Pipeline](https://metacpan.org/pod/IO::Pipeline) has very little in common with
    __IPC::Pipeline__.

# AUTHOR

Written by Xan Tronix <xan@cpan.org>

# COPYRIGHT

Copyright (c) 2014, cPanel, Inc.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See the LICENSE file for further details.
