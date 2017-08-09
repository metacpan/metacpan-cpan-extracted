# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator;

use 5.008;
use strict;
use warnings;
use Math::Logic::Ternary::Calculator::State;
use Math::Logic::Ternary::Calculator::Session;

require Exporter;

our $VERSION     = '0.004';
our @ISA         = qw(Exporter);
our @EXPORT      = qw(tcalc);

our $DEFAULT_WORD_SIZE = 27;

sub tcalc {
    my ($size, $mode) = @_;
    if (!defined $size) {
        $size = $DEFAULT_WORD_SIZE;
    }
    if (!defined $mode) {
        $mode = 0;
    }
    if (2 < @_ || grep { defined $_ and !/^\d+\z/ } $size, $mode) {
        die "usage: tcalc [word_size [mode]]\n";
    }
    my $state   = eval {
        Math::Logic::Ternary::Calculator::State->new($size, $mode)
    };
    if (!defined $state) {
        my $msg = $@;
        $msg =~ s/ at .*? line \d+\.$//;
        die $msg;
    }
    my $session = Math::Logic::Ternary::Calculator::Session->new($state);
    $session->run;
    return;
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator - interactive ternary calculator

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::Calculator.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator;

  tcalc(81);            # run a calculator with word size 81
  tcalc;                # run a calculator with default word size

=head1 DESCRIPTION

=over 4

=item I<tcalc>

C<tcalc($word_size, $mode)> takes a word size, creates a calculator
state object with words of the given size and a session object acting on
the state object, and it runs the session interactively.  The numerical
mode parameter is optional.  It specifies an initial arithmetic mode.
Default mode is 0, meaning balanced arithmetic.

=back

=head2 Exports

The subroutine I<tcalc> is automatically exported into the namespace
of the caller.  There are no other exports.

=head1 COMPONENTS

The calculator is implemented using these modules:

=over 4

=item L<Math::Logic::Ternary::Calculator::Version>

Text constants identifying the application and its version.

=item L<Math::Logic::Ternary::Calculator::Mode>

Class for arithmetic operation mode.

=item L<Math::Logic::Ternary::Calculator::Operator>

Class for operators performing ternary computations.

=item L<Math::Logic::Ternary::Calculator::Command>

Class for general user commands.

=item L<Math::Logic::Ternary::Calculator::Parser>

Class for interactive input parsing.

=item L<Math::Logic::Ternary::Calculator::State>

Class for ternary data storage.

=item L<Math::Logic::Ternary::Calculator::Session>

Class driving ternary calculator sessions.

=item L<Math::Logic::Ternary::Calculator>

Top-Level interface providing the tcalc() function.

=back

Their dependency hierarchy is as follows:

  +-----------------------------------------------------+
  |                     Calculator                      |
  +--------+-----------------+--------------------------+
           |                 |
           |  +--------------V--------------+
           |  |           Session           |
           |  +--+-----+-----+-----+-----+--+
           |     |     |     |     |     |
  +--------V-----V--+  |     |     |  +--V--------------+
  |      State      |  |     |     |  |     Parser      |
  +--------+-----+--+  |     |     |  +--------+-----+--+
           |     |     |     |     |           |     |
           |     |     |     |  +--V-----------V--+  |
           |     |     |     |  |     Command     |  |
           |     |     |     |  +--+-----------+--+  |
           |     |     |     |     |           |     |
           |     |     |  +--V-----V--------+  |     |
           |     |     |  |    Operator     |  |     |
           |     |     |  +--+-----+--------+  |     |
           |     |     |     |     |           |     |
           |  +--V-----V-----V--+  |  +--------V-----V--+
           |  |      Mode       |  |  |     Version     |
           |  +-----------------+  |  +-----------------+
           |                       |
  +--------V-----------------------V--------------------+
  |                Math::Logic::Ternary                 |
  +-----------------------------------------------------+

=head1 SEE ALSO

=over 4

=item *

L<Math::Logic::Ternary::Calculator::Manual>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
