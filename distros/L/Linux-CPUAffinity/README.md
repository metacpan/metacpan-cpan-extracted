# NAME

Linux::CPUAffinity - set and get a process's CPU affinity mask

# SYNOPSIS

    use Linux::CPUAffinity;

    # get affinity of this process
    my $cpus = Linux::CPUAffinity->get(0); # eg: [0, 1, 2, 3]
    # other process
    my $cpus = Linux::CPUAffinity->get($pid);

    # set affinity of this process
    Linux::CPUAffinity->set(0 => [0,1]);
    # other process
    Linux::CPUAffinity->set($pid => [0]);

    # utility method to get processors
    my $num = Linux::CPUAffinity->num_processors();

# DESCRIPTION

Linux::CPUAffinity is a wrapper module for Linux system call sched\_getaffinity(2) and sched\_setaffinity(2).

This module is only available on GNU/Linux.

# METHODS

- $cpus = $class->get($pid)

    Get the CPU affinity mask of the process.

- $class->set($pid, $cpus :ArrayRef\[Int\])

    Set the CPU affinity mask of the process.

- $num = $class->num\_processors()

    Get the number of processors currently online (available).

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

# SEE ALSO

[Sys::CpuAffinity](https://metacpan.org/pod/Sys::CpuAffinity)
