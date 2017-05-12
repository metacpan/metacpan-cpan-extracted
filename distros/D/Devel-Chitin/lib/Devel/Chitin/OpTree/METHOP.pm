package Devel::Chitin::OpTree::METHOP;
use base 'Devel::Chitin::OpTree::UNOP';

our $VERSION = '0.10';

use strict;
use warnings;

sub pp_method_named {
    my $self = shift;

    my $sv = $self->op->meth_sv;
    $sv = $self->_padval_sv($self->op->targ) unless $$sv;  # happens in thread-enabled perls

    $sv->PV;
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::METHOP - Deparser class for method OPs

=head1 DESCRIPTION

This package contains methods to deparse METHOPs (method_named)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
