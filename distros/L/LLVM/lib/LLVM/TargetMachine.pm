package LLVM::TargetMachine;
{
  $LLVM::TargetMachine::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::TargetMachine - LLVM target machine class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::TargetMachine> can be used to generate assembly or object files.

=head1 METHODS

=head2 create( $target, $triple, $cpu, $features )

Create a new C<LLVM::TargetMachine> given a L<LLVM::Target>, a string
representing the platform's triple (e.g. 'x86_64-linux-gnu'), a string
representing a CPU (e,g, 'athlon') and a list of CPU features.

To see what CPUs and features are supported for given target, run, from the
command-line:

    llvm-as < /dev/null | llc -march=xyz -mcpu=help

replacing C<xyz> with the desired target (e.g. 'x86-64').

=head2 emit( $machine, $mod, $file, $to_object )

Emit an object (if C<$to_object> is true) or ASM file for the given
L<LLVM::Module> to C<$file>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::TargetMachine
