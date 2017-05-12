package Devel::Chitin::OpTree::COP;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.10';

use strict;
use warnings;

sub pp_nextstate {
    my $self = shift;

    my @package_and_label;

    my $cur_cop = $self->_get_cur_cop;
    if ($cur_cop and !$self->is_null and $self->op->stashpv ne $cur_cop->op->stashpv) {
        push @package_and_label, 'package ' . $self->op->stashpv . ';';
    }

    if (!$self->is_null and my $label = $self->op->label) {
        push @package_and_label, "$label:";
    }

    $self->_set_cur_cop if (!$cur_cop or !$self->is_null);

    join(";\n", @package_and_label);
}
*pp_dbstate = \&pp_nextstate;
*pp_setstate = \&pp_nextstate;

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::COP - Deparser class for control OPs

=head1 DESCRIPTION

This package contains methods to deparse COPs (nextstate, dbstate)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
