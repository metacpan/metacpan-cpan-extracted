package Math::NumberBase::XS;

use 5.008;
use strict;
use warnings;

require XSLoader;
our $VERSION = '0.02';

XSLoader::load('Math::NumberBase::XS', $VERSION);

sub new {
  my ($class, $base, $symbols) = @_;

  $base //= 10;
  die '$base must be an integer >= 2' if $base < 2 || int($base) != $base;

  my @symbols_array = defined $symbols
    ? split //, $symbols
    : do {
        die 'Cannot auto determine symbols for base > 36' if $base > 36;
        my @numalpha = (0 .. 9, 'a' .. 'z');
        splice @numalpha, 0, $base;
    };

  my %symbol_value_map = map { $symbols_array[$_] => $_ } 0 .. $#symbols_array;

  die 'Symbols length must match base' if @symbols_array != $base;
  die 'Symbols contain duplicates' if keys(%symbol_value_map) != @symbols_array;

  my $self = bless {}, $class;
  $self->_init($base, \@symbols_array, \%symbol_value_map);

  return $self;
}

sub get_base {
  my ($self) = @_;
  return $self->_get_base();
}

sub get_symbols {
  my ($self) = @_;
  return $self->_get_symbols();
}

sub get_symbol_value_map {
  my ($self) = @_;
  return $self->_get_symbol_value_map();
}

sub to_decimal {
  my ($self, $string) = @_;
  return $self->_to_decimal($string);
}

sub from_decimal {
  my ($self, $in_decimal) = @_;
  return $self->_from_decimal($in_decimal);
}

sub convert_to {
  my ($self, $string, $number_base) = @_;
  return $number_base->from_decimal($self->to_decimal($string));
}

sub convert_from {
  my ($self, $string, $number_base) = @_;
  return $self->from_decimal($number_base->to_decimal($string));
}

1;

__END__

=head1 NAME

Math::NumberBase::XS - Lighting fast number converter from one base to another base

=head1 SYNOPSIS

  use Math::NumberBase::XS;

  # base 16 numbers: hexadecimal
  my $base_16 = Math::NumberBase::XS->new(16);

  # base 4 numbers, but with custom symbols:
  # 'w' = 0
  # 'x' = 1
  # 'y' = 2
  # 'z' = 3
  my $base_4 = Math::NumberBase::XS->new(4, 'wxyz');

  print $base_16->to_decimal('1ac2'), "\n";
  print $base_16->from_decimal(325), "\n";
  print $base_16->convert_to('1ac2', $base_4), "\n";
  print $base_16->convert_from('yzxw', $base_4), "\n";

=head1 DESCRIPTION

This module was inspired by L<Math::NumberBase>. It uses the same exact interface, the same internal logic, but all the heavy lifting is done in C through XS, which makes it extremelly faster.

This class can convert a number from one base to another base.

By default, this class will use a subset of (0..9,'a'..'z') as the symbols.
That means for base-16 numbers, the default symbols are 0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f'.
But you can always specify your own symbols by passing a string to the constructor.

=head1 METHODS

=head2 new(<integer>, <string>)

The constructor.

Receives 2 optional parameters: $base and $symbols.

If no paramteres passed to constructor, the base would be 10, and the symbols would be 0,1,2,3,4,5,6,7,8,9, thus it makes a normal decimal number system.

If only $base is passed to constructor, the $symbols would be a subset of (0..9,'a'..'z'). That means if you pass a number greater than 36 to the constructor you have to define the symbols you want to use to represent the number.

$base has to be an integer >= 2.

$symbols should be a string.

=head2 get_base( )

Returns the base.

=head2 get_symbols( )

Returns an arrayref of symbols.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');
  my $symbols = $base_3->get_symbols();

  # $symbols = ['a', 'b', 'c'];

=head2 get_symbol_value_map( )

Returns a hashref of symbol => value map.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');
  my $symbol_map = $base_3->get_symbol_value_map();

  # $symbol_map = {
  #     'a' => 0,
  #     'b' => 1,
  #     'c' => 2
  # };

=head2 to_decimal(<string>)

Convert to decimal.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');

  # convert 'cab' in base 3 to a decimal number
  my $in_decimal = $base_3->to_decimal('cab');

  # $in_decimal = 19;

=head2 from_decimal(<integer>)

Convert from decimal.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');

  # convert 19 decimal to a base 3 number
  my $in_base_3 = $base_3->from_decimal(19);

  # $in_base_3 = 'cab';

=head2 convert_to(<string>, <Math::NumberBase::XS object>)

Convert a number from this base to another base.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');
  my $base_4 = Math::NumberBase::XS->new(4);

  # convert 'cab' in base 3 to a base 4 number
  my $in_base_4 = $base_3->convert_to('cab', $base_4);

  # $in_base_4 = '103';

=head2 convert_from(<string>, <Math::NumberBase::XS object>)

Convert a number from another base to this base.

  my $base_3 = Math::NumberBase::XS->new(3, 'abc');
  my $base_4 = Math::NumberBase::XS->new(4);

  # convert 'cab' in base 3 to a base 4 number
  my $in_base_4 = $base_4->convert_from('cab', $base_3);

  # $in_base_4 = '103';

=head1 ACKNOWLEDGEMENTS

All of the logic, interface, test files and documentation were adapted from L<Math::NumberBase>, by Yehezkiel Syamsuhadi <yehezkielbs@gmail.com>. The original logic was translated from Perl to C (XS) to make it extremely faster for massive operations.

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-numberbase-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-NumberBase-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::NumberBase::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-NumberBase-XS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-NumberBase-XS>

=item * Search CPAN

L<https://metacpan.org/release/Math-NumberBase-XS>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021-2024 by Francisco Zarabozo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
