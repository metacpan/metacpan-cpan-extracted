package Interchange6::Currency;

=head1 NAME

Interchange6::Currency - Currency objects for Interchange 6

=head1 VERSION

0.101

=for stopwords CLDR eCommerce Mottram Shutterstock SysPete

=cut

our $VERSION = '0.101';

use Moo;
extends 'CLDR::Number::Format::Currency';

use Carp;
use Class::Load qw/load_class/;
use Math::BigFloat;
use Safe::Isa;
use Sub::Quote qw/quote_sub/;
use namespace::clean;
use overload
  '0+'  => sub { shift->value },
  '""'  => sub { shift->as_string },
  '+'   => \&_add,
  '-'   => \&_subtract,
  '*'   => \&_multiply,
  '/'   => \&_divide,
  '%'   => \&modulo,
  '<=>' => \&cmp_value,
  'cmp' => \&cmp,
  '='   => \&clone,
  ;

=head1 DESCRIPTION

Currency objects for Interchange6 Open Source eCommerce with Unicode
CLDR localization and rate conversion.

Extends L<CLDR::Number::Format::Currency> with accurate calculation functions
using L<Math::BigFloat>.

Many useful standard operators are overloaded and return currency objects
if appropriate.

Although this class was written to satisfy the specific requirements of
Interchange6 it is suitable for use as a standalone module. See L</SEE ALSO>
for other currency modules.

=head1 ATTRIBUTES

=head2 value

Value as simple decimal, e.g.: 3.45

All values are coerced into L<Math::BigFloat>.

=cut

has value => (
    is       => 'rwp',
    required => 1,
    coerce   => quote_sub(q{ $_[0]->$_isa("Math::BigFloat") ? $_[0] : Math::BigFloat->new( $_[0] ) }),
);

# check for currency objects with different currency codes and if arg
# is a currency object return its value
sub _clean_arg {
    my ( $self, $arg ) = @_;

    # uncoverable branch true
    croak "_clean_arg is a class method" unless $self->$_isa(__PACKAGE__);

    if ( $arg->$_isa(__PACKAGE__) ) {
        croak "Cannot perform calculation when currencies do not match"
          if $self->currency_code ne $arg->currency_code;
        return $arg->value;
    }
    return $arg;
}

=head2 converter_class

Defaults to L<Finance::Currency::Convert::WebserviceX>.

The class name which handles conversion to a new C<currency_code>.

The converter class can be any class that supports the following method
signature:

  sub convert {
      my ($self, $price, $from, $to) = @_;
 
      return $converted_price;
  };

In addition this module supports the following converters:

=over

=item * L<Finance::Currency::Convert::WebserviceX>

=back

=cut

has converter_class => (
    is  => 'ro',
    isa => quote_sub(q{ die "$_[0] is not a valid class name" unless ( ref(\$_[0]) eq 'SCALAR' && $_[0] =~ /^\S+$/ ) }),
    default => "Finance::Currency::Convert::WebserviceX",
);

=head2 converter

Vivified L</converter_class>.

=cut

has converter => (
    is       => 'lazy',
    isa      => quote_sub(q{ die "Not a valid converter class" unless $_[0]->$_can('convert') }),
    init_arg => undef,
);

sub _build_converter {
    my $self = shift;
    load_class( $self->converter_class );
    return $self->converter_class->new;
}

=head1 METHODS

=head2 BUILD

Sets precision for automatic rounding of L</value> to 
L<CLDR::Number::Format::Currency/maximum_fraction_digits>.

=cut

sub BUILD {
    my $self = shift;

    # force cash trigger so we can reset precision on value
    $self->cash( $self->cash );
    $self->value->precision( -$self->maximum_fraction_digits );
}

=head2 clone %new_attrs?

Returns clone of the currency object possibly with new attribute values (if
any are supplied).

=cut

sub clone {
    my ( $self, %new_attrs ) = @_;
    return __PACKAGE__->new(
        value         => $self->value,
        currency_code => $self->currency_code,
        locale        => $self->locale,
        %new_attrs,
    );
}

=head2 convert $new_corrency_code

Convert to new currency using L</converter>.

B<NOTE:> If C</convert> is called in void context then the currency object
is mutated in place. If called in list or scalar context then the original
object is not modified and a new L<Interchange6::Currency> object is returned
instead.

=cut

sub convert {
    my ( $self, $new_code ) = @_;

    if ( $self->currency_code eq $new_code ) {

        # currency code has not changed
        if ( defined wantarray ) {

            # called in list or scalar context
            return $self->clone;
        }
        else {

            # void context
            return;
        }
    }
    else {

        # remove precision before conversion since new currency may have
        # different maximum_fraction_digits and we don't want to lose accuracy
        $self->value->precision(undef);

        # currency code has changed so convert via converter_class

        my $new_value;

        if ( $self->converter_class eq 'Finance::Currency::Convert::XE' ) {

            # XE is special
            $new_value = $self->converter->convert(
                value  => $self->value,
                source => $self->currency_code,
                target => $new_code
            ) || croak "convert failed: " . $self->converter->error . "\n";
        }
        else {
            # other
            $new_value =
              $self->converter->convert( $self->value, $self->currency_code,
                $new_code );
        }

        croak "convert failed" unless defined $new_value;

        if ( defined wantarray ) {

            # called in list or scalar context

            return $self->clone(
                currency_code => $new_code,
                value         => $new_value,
            );
        }
        else {

            # void context

            $self->currency_code($new_code);
            $self->_set_value($new_value);

            # force cash trigger so we can reset precision on value
            $self->cash( $self->cash );
            $self->value->precision( -$self->maximum_fraction_digits );

            return;
        }
    }
}

=head2 as_string

Stringified formatted currency, e.g.: $3.45

=cut

sub as_string {
    return $_[0]->format( $_[0]->value );
}

=head2 stringify

Alias for L</as_string>.

=cut

sub stringify {
    return $_[0]->as_string;
}

=head2 add $arg

Add C<$arg> to L</value> in place.

=cut

sub add {
    my ( $self, $arg ) = @_;
    $self->value->badd( $self->_clean_arg($arg) );
}

# for overloaded '+'
sub _add {
    my ( $self, $arg ) = @_;
    $self->clone(
        value => $self->value->copy->badd( $self->_clean_arg($arg) ) );
}

=head2 subtract $arg

Subtract C<$arg> from L</value> in place.

=cut

sub subtract {
    my ( $self, $arg ) = @_;
    $self->value->bsub( $self->_clean_arg($arg) );
}

# for overloaded '-'
sub _subtract {
    my ( $self, $arg, $swap ) = @_;
    my $result = $self->value->copy->bsub( $self->_clean_arg($arg) );
    $self->clone( value => $swap ? $result->bneg : $result );
}

=head2 multiply $arg

Multiply L</value> by C<$arg> in place.

=cut

sub multiply {
    my ( $self, $arg ) = @_;
    $self->value->bmul( $self->_clean_arg($arg) );
}

# for overloaded '*'
sub _multiply {
    my ( $self, $arg ) = @_;
    $self->clone(
        value => $self->value->copy->bmul( $self->_clean_arg($arg) ) );
}

=head2 divide $arg

Divide L</value> by C<$arg> in place.

=cut

sub divide {
    my ( $self, $arg ) = @_;
    $self->value->bdiv( $self->_clean_arg($arg) );
}

# for overloaded '/'
sub _divide {
    my ( $self, $arg, $swap ) = @_;
    my $result;
    if ($swap) {
        $result =
          Math::BigFloat->new( $self->_clean_arg($arg) )->bdiv( $self->value );
    }
    else {
        $result = $self->value->copy->bdiv( $self->_clean_arg($arg) );
    }
    $self->clone( value => $result );
}

=head2 modulo $arg

Return L</value> C<%> C<$arg> as currency object.

=cut

sub modulo {
    my ( $self, $arg, $swap ) = @_;
    my $result;
    if ($swap) {
        $result =
          Math::BigFloat->new( $self->_clean_arg($arg) )->bmod( $self->value );
    }
    else {
        $result = $self->value->copy->bmod( $self->_clean_arg($arg) );
    }
    $self->clone( value => $result );
}

=head2 cmp_value $arg

Equivalent to L</value> C<< <=> >> C<$arg>.

=cut

sub cmp_value {
    my ( $self, $arg, $swap ) = @_;
    if ($swap) {
        return Math::BigFloat->new( $self->_clean_arg($arg) )
          ->bcmp( $self->value );
    }
    else {
        return $self->value->bcmp( $self->_clean_arg($arg) );
    }
}

=head2 cmp $arg

String comparison.

Not always useful in itself since string comparison of stringified currency
objects might not produce what you expect depending on locale and currency
code.

=cut

sub cmp {
    my ( $self, $arg, $swap ) = @_;
    if ($swap) {
        return "$arg" cmp "$self";
    }
    else {
        return "$self" cmp "$arg";
    }
}

=head2 SEE ALSO

Other modules which perform currency maths:

=over

=item * L<Math::Currency>

=item * L<Data::Currency>

=back

Other Interchange6 eCommerce modules:

=over

=item * L<Interchange6>

=item * L<Interchange6::Schema>

=item * L<Dancer::Plugin::Interchange6>

=back

=head1 AUTHORS

Peter Mottram (SysPete), C<peter@sysnix.com>

=head1 ACKNOWLEDGEMENTS

Shutterstock, Inc for the excellent L<CLDR::Number> and all of the authors
of L<Math::BigFLoat> and L<Moo>.

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

Unicode is a registered trademark of Unicode, Inc., in the United States
and other countries.

=cut

1;
