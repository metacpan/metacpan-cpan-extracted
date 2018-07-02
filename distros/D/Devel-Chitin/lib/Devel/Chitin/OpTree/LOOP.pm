package Devel::Chitin::OpTree::LOOP;
use base 'Devel::Chitin::OpTree::LISTOP';

our $VERSION = '0.16';

use strict;
use warnings;

sub pp_enterloop { '' } # handled inside pp_leaveloop

sub nextop {
    my $self = shift;
    $self->_obj_for_op($self->op->nextop);
}

sub redoop {
    my $self = shift;
    $self->_obj_for_op($self->op->redoop);
}

sub lastop {
    my $self = shift;
    $self->_obj_for_op($self->op->lastop);
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::LOOP - Deparser class for loop OPs

=head1 DESCRIPTION

This package contains methods to deparse LOOPs (enterloop)

=head2 Methods

=over 4

=item nextop

Returns a L<Devel::Chitin::OpTree> instance for the next pointer of this loop

=item redoop

Returns a L<Devel::Chitin::OpTree> instance for the redo pointer of this loop

=item last

Returns a L<Devel::Chitin::OpTree> instance for the last pointer of this loop

=back

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
