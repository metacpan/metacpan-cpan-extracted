#
# This file is part of Language::Befunge::Storage::Generic::Vec::XS.
# Copyright (c) 2008 Mark Glines, all rights reserved.
#
# This program is licensed under the terms of the Artistic License v2.0.
# See the "LICENSE" file for details.


package Language::Befunge::Storage::Generic::Vec::XS;

use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '0.03';

use base 'Language::Befunge::Storage::Generic::Vec';
use Language::Befunge::Vector;

require XSLoader;
XSLoader::load('Language::Befunge::Storage::Generic::Vec::XS', $VERSION);

# Preloaded methods go here.

sub get_value {
    my ($self, $v) = @_;
    my ($min, $max, $nd) = @$self{qw(min max nd)};
    return 32 unless $v->bounds_check($min, $max);
    my $rv = $self->_get_value($v, $$self{torus}, $min, $max, $nd);
    return $rv;
}


sub set_value {
    my ($self, $v, $value) = @_;
    my ($min, $max, $nd) = @$self{qw(min max nd)};
    unless($v->bounds_check($min, $max)) {
        $self->expand($v);
        # min/max were overwritten by expand()
        ($min, $max) = @$self{qw(min max)};
    }
    return $self->_set_value($v, $$self{torus}, $min, $max, $nd, $value);
}


sub _offset {
    my ($self, $v, $min, $max) = @_;
    $min //= $$self{min};
    $max //= $$self{max};
    return $self->__offset($$self{nd}, $v, $min, $max);
}


sub expand {
    my ($self, $point) = @_;
    my ($omin, $omax, $nd) = @$self{qw(min max nd)};
    return if $point->bounds_check($omin, $omax);
    my ($min, $max) = ($omin->copy, $omax->copy);
    my $torus = $$self{torus};
    my $rv = $self->_expand($nd, $point->copy, $min, $max, $omin, $omax, $torus);
    $$self{torus} = $rv;
    $$self{min} = $min;
    $$self{max} = $max;
}


sub _is_xs { 1 }

1;
__END__

=head1 NAME

Language::Befunge::Storage::Generic::Vec::XS - Language::Befunge::Storage::Generic::Vec rewritten for speed



=head1 DESCRIPTION

Language::Befunge::Storage::Generic::Vec implements a linear storage model,
where a perl string is used to store a (potentially very large) integer array.
The integers are accessed from perl with vec().

Unfortunately, vec() operates on unsigned integers, which means some extra
calculations are necessary to convert between unsigned and signed integers.

If the access was done from C, using a signed integer pointer, the access
would be much faster, and the conversion would be unnecessary.


=head1 METHODS

This module implements a subset of the LBSGV API.  Please refer to that module
for more information on the methods we implement, listed as follows:

=over 4

=item get_value()

=item set_value()

=item _offset()

=item expand()

=item _is_xs()

=back


=head1 SEE ALSO

L<Language::Befunge::Storage::Generic::Vec>


=head1 AUTHOR

Mark Glines, E<lt>mark@glines.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Mark Glines, all rights reserved.

This program is licensed under the terms of the Artistic License, version 2.0.
See the "LICENSE" file for details.


=cut

