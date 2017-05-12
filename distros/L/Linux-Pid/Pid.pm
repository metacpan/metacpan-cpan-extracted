package Linux::Pid;

use strict;
use warnings;

our $VERSION = 0.04;
require XSLoader;
XSLoader::load('Linux::Pid', $VERSION);

sub import {
    shift;
    my $p = caller;
    for my $symbol (@_) {
	if ($symbol eq 'getpid' or $symbol eq 'getppid') {
	    no strict 'refs';
	    *{$p."::".$symbol} = \&{$symbol};
	} else {
	    require Carp;
	    Carp::croak("Unrecognized symbol $symbol");
	}
    }
}

1;

__END__

=head1 NAME

Linux::Pid - Get the native PID and the PPID on Linux

=head1 SYNOPSIS

    use Linux::Pid;
    print Linux::Pid::getpid(), "\t", Linux::Pid::getppid(), "\n";

    use Linux::Pid qw(getpid getppid);
    print getpid(), "\t", getppid(), "\n";

=head1 DESCRIPTION

Why should one use a module to get the PID and the PPID of a process
where there are the C<$$> variable and the C<getppid()> builtin ? (Not
mentioning the equivalent C<POSIX::getpid()> and C<POSIX::getppid()>
functions.)

In fact, this is useful on Linux, with multithreaded programs. Linux' C
library, using the linux thread model, returns different values of the
PID and the PPID from different threads. (Other thread models such as
NPTL don't have the same behaviour). This module forces perl to call the
underlying C functions C<getpid()> and C<getppid()>.

=head1 AUTHOR

Copyright (c) 2002-2007 Rafael Garcia-Suarez. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
