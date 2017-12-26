package Devel::Chitin::OpTree::PADOP;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.13';

use strict;
use warnings;

sub pp_gv {
    my $self = shift;
    my $gv = $self->_padval_sv($self->op->padix);
    $self->_gv_name( $gv );
}
*pp_gvsv = \&pp_gv;

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::PADOP - Deparser class for pad OPs

=head1 DESCRIPTION

This package contains methods to deparse PADOPs (gv, gvsv)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
