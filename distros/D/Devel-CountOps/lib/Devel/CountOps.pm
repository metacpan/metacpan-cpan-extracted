package Devel::CountOps;

use strict;
use warnings;

our $VERSION = '0.01';

use DynaLoader ();
our @ISA = qw(DynaLoader);

bootstrap Devel::CountOps $VERSION;

sub import {
    eval 'END { print STDERR "${^_OPCODES_RUN} opcodes run\n" }'
}

1;

__END__

=head1 NAME

Devel::CountOps - precise timing for Perl 5 code

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    perl -MDevel::CountOps foo.pl

    #or

    use Devel::CountOps ();
    my $a = ${^_OPCODES_RUN};
    code();
    say(${^_OPCODES_RUN} - $a);

=head1 DESCRIPTION

This module allows you to very simply measure the number of ops dispatched
in the execution of Perl code.  While not perfectly correlated with time, it
has the advantage of being infinitely precise - it will come up the same value
every time, and can measure changes too small to show up in timings.

The current counter is presented as a magical scalar ${^_OPCODES_RUN}, which,
like all control variables, is forced to always be in main so it need not be
imported.  If Devel::CountOps is default-imported, it installs an END handler
which prints the opcode count.

=head1 AUTHOR

Stefan O'Rear <stefanor@cox.net>

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut