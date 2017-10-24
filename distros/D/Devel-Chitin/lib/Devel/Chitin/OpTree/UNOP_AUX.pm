package Devel::Chitin::OpTree::UNOP_AUX;
use base 'Devel::Chitin::OpTree::UNOP';

our $VERSION = '0.11';

use strict;
use warnings;

my @open_bracket = qw( [ { );
my @close_bracket = qw( ] } );

my %hash_actions = map { $_ => 1 }
                    ( B::MDEREF_HV_pop_rv2hv_helem, B::MDEREF_HV_gvsv_vivify_rv2hv_helem,
                      B::MDEREF_HV_padsv_vivify_rv2hv_helem, B::MDEREF_HV_vivify_rv2hv_helem,
                      B::MDEREF_HV_padhv_helem, B::MDEREF_HV_gvhv_helem );
sub pp_multideref {
    my $self = shift;

    my @aux_list = $self->op->aux_list($self->cv);

    my $deparsed = '';
    while(@aux_list) {
        my $aux = shift @aux_list;
        while (($aux & B::MDEREF_ACTION_MASK) != B::MDEREF_reload) {

            my $action = $aux & B::MDEREF_ACTION_MASK;
            my $is_hash = $hash_actions{$action} || 0;

            if ($action == B::MDEREF_AV_padav_aelem
                or $action == B::MDEREF_HV_padhv_helem
            ) {
                $deparsed .= '$' . substr( $self->_padname_sv( shift @aux_list )->PVX, 1);

            } elsif ($action == B::MDEREF_HV_gvhv_helem
                     or $action == B::MDEREF_AV_gvav_aelem
            ) {
                $deparsed .= '$' . $self->_gv_name(shift @aux_list);

            } elsif ($action == B::MDEREF_HV_padsv_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_padsv_vivify_rv2av_aelem
            ) {
                $deparsed .= $self->_padname_sv( shift @aux_list )->PVX . '->';

            } elsif ($action == B::MDEREF_HV_gvsv_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_gvsv_vivify_rv2av_aelem
            ) {
                $deparsed .= '$' . $self->_gv_name(shift @aux_list) . '->';

            } elsif ($action == B::MDEREF_HV_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_vivify_rv2av_aelem
            ) {
                $deparsed .= '->';
            }


            $deparsed .= $open_bracket[$is_hash];

            my $index = $aux & B::MDEREF_INDEX_MASK;
            if ($index == B::MDEREF_INDEX_padsv) {
                $deparsed .= $self->_padname_sv(shift @aux_list)->PV;

            } elsif ($index == B::MDEREF_INDEX_const) {
                my $sv = shift(@aux_list);
                $deparsed .= $is_hash
                                ? $self->_quote_sv($sv)
                                : $sv;
            }

            $deparsed .= $close_bracket[$is_hash];

        } continue {
            $aux >>= B::MDEREF_SHIFT;
        }
    }

    $deparsed;
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::UNOP_AUX - Deparser class for unary OPs with auxillary data

=head1 DESCRIPTION

This package contains methods to deparse UNOP_AUXs (multideref)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
