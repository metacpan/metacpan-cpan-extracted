#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::lib::SUBR;
# ABSTRACT: subroutines extension
$Language::Befunge::lib::SUBR::VERSION = '5.000';
use Language::Befunge::Vector;

sub new { return bless {}, shift; }

sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    $ip->extdata('SUBR', 0);
}

sub C {
    my ($self, $interp) = @_;
    my $ip    = $interp->get_curip;
    my $count = $ip->spop;
    my $to    = $ip->spop_vec;

    # set new position
    my $is_rel = $ip->extdata('SUBR') // 0;
    my $from   = $ip->get_position;
    $to       += $ip->get_storage if $is_rel;
    $ip->set_position($to);

    # new delta is (1, 0, ...)
    my $old = $ip->get_delta;
    my $new = Language::Befunge::Vector->new_zeroes( $to->get_dims );
    $new->set_component(0,1);
    $ip->set_delta($new);

    # mess with stack
    my @stack = $ip->spop_mult($count);
    $ip->spush_vec( $from );
    $ip->spush_vec( $old );
    $ip->spush_args( @stack );
}

sub J {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # compute where to jump
    my $is_rel = $ip->extdata('SUBR') // 0;
    my $vec    = $ip->spop_vec;
    $vec += $ip->get_storage if $is_rel;

    # new delta is (1, 0, ...)
    my $delta = Language::Befunge::Vector->new_zeroes( $vec->get_dims );
    $delta->set_component(0,1);
    $ip->set_delta( $delta );

    # set new position
    $ip->set_position($vec);
}

sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;
    $ip->extdata('SUBR', 1);
}

sub R {
    my ($self, $interp) = @_;
    my $ip    = $interp->get_curip;
    my $count = $ip->spop;

    # mess with stack
    my @stack = $ip->spop_mult($count);
    my $delta = $ip->spop_vec;
    my $pos   = $ip->spop_vec;
    $ip->spush_args( @stack );

    # set new position
    $ip->set_position($pos);
    $ip->set_delta($delta);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::SUBR - subroutines extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The SUBR fingerprint (0x53554252) allows to use subroutines within befunge.

=head1 FUNCTIONS

=head2 new

Create a new SUBR instance.

=head2 Subroutines

=over 4

=item J( $vector )

Pop a C<$vector> from the stack, and jump inconditionally to this location. The
velocity will be forced to (1,0) (or the equivalent for other dimensions).

=item ($from, $velocity, @stack) = C( $vector, $count )

Call a subroutine. In details, pop a C<$count> and a C<$vector> from the stack.
Then pop C<$count> elements from the stack, push current position, current
velocity and the C<$count> elements popped back on the stack. Then jump to the
C<$vector> address with a velocity of (1,0) (or the equivalent for other
dimensions). This function is supposed to be called in conjunction with C<R>.

=item (@stack) = R($from, $velocity, @stack, $count)

Return from subroutine (supposed to be called after a call to C<C>). Pop a
C<$count> from the stack, then C<$count> elements from the stack. Pop then 2
vectors, and push back the C<$count> elements on the stack. Then restore the
velocity from the first vector popped, and jump back to address it went from
(the second vector popped).

=back

=head2 Address mode

Function C<C> and C<J> pop a vector from the stack to jump to this address.
However, the vector popped can be either absolute or relative to the storage
offset. Default mode is absolute addressing, but one can switch with the
following functions:

=over 4

=item A()

Switch in absolute mode.

=item O()

Switch in relative mode.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#SUBR>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
