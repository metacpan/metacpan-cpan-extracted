package Devel::Chitin::OpTree::SVOP;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.20';

use strict;
use warnings;

sub pp_const {
    my $self = shift;
    my %params = @_;

    my $sv = $self->op->sv;

    $sv = $self->_padval_sv($self->op->targ) unless $$sv;  # happens in thread-enabled perls

    if ($sv->FLAGS & B::SVs_RMG) {
        # It's a version object
        for (my $mg = $sv->MAGIC; $mg; $mg = $mg->MOREMAGIC) {
            return $mg->PTR if $mg->TYPE eq 'V';
        }

    } elsif ($sv->FLAGS & B::SVf_POK) {
        return $self->_quote_sv($sv, %params);
    } elsif ($sv->FLAGS & B::SVf_NOK) {
        return $sv->NV;
    } elsif ($sv->FLAGS & B::SVf_IOK) {
        return $sv->int_value;
    } elsif ($sv->isa('B::SPECIAL')) {
        '<???pp_const B::SPECIAL ' .  $B::specialsv_name[$$sv] . '>';

    } else {
        die "Don't know how to get the value of a const from $sv";
    }
}
*pp_method_named = \&pp_const;

sub pp_gv {
    my $self = shift;
    # An 'our' varaible or subroutine
    $self->_gv_name($self->op->gv);
}
*pp_gvsv = \&pp_gv;

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::SVOP - Deparser class for SV-related OPs

=head1 DESCRIPTION

This package contains methods to deparse SVOPs (const, method_named, etc)

=head2 Methods

=over 4

=item last

Returns a L<Devel::Chitin::OpTree> instance for the second child of this node

=back

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
