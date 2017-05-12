#
# This file is part of Language::Befunge::Vector::XS.
# Copyright (c) 2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Vector::XS;

use strict;
use warnings;

use overload
	'='   => \&copy,
	'+'   => \&_add,
	'-'   => \&_substract,
	'neg' => \&_invert,
	'+='  => \&_add_inplace,
	'-='  => \&_substract_inplace,
	'<=>' => \&_compare,
	'eq'  => \&_compare_string,
	'""'  => \&as_string;

our $VERSION = '1.1.1';

require XSLoader;
XSLoader::load('Language::Befunge::Vector::XS', $VERSION);

# Preloaded methods go here.

sub as_string {
    my $self = shift;
    local $" = ',';
    return "(@$self)";
}

#
# my $bool = $v->_compare($string);
# my $bool = $v eq $string;
#
# Check whether the vector stringifies to $string.
#
sub _compare_string {
    my ($self, $str) = @_;
    return $self->as_string eq $str;
}


1;
__END__

=head1 NAME

Language::Befunge::Vector::XS - Language::Befunge::Vector rewritten for speed



=head1 DESCRIPTION

The C<Language::Befunge> module makes heavy use of n-dims vectors,
mapped to the C<Language::Befunge::Vector> class. This allows to
abstract the funge dimension while still keeping the same code for the
operations.

However, such an heavy usage does have some impact on the performances.
Therefore, this modules is basically a rewrite of LBV in XS. If
installed, then LBV will automagically load it and replace its own
functions with the XS ones.



=head1 METHODS

This module implements exactly the same api as LBV. Please refer to this
module for more information on the following methods:

=over 4

=item new()

=item new_zeroes()

=item copy()

=item as_string()

=item get_dims()

=item get_component()

=item get_all_components()

=item clear()

=item set_component()

=item bounds_check()

=item rasterize()

=item standard mathematical operations

=item inplace mathematical operations

=item comparison operations

=back


=head1 SEE ALSO

L<Language::Befunge::Vector>


=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

