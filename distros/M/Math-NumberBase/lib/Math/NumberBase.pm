package Math::NumberBase;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Math::NumberBase - Number converter from one base to another base

=head1 SYNOPSIS

  use Math::NumberBase;

  # base 16 numbers: hexadecimal
  my $base_16 = Math::NumberBase->new(16);

  # base 4 numbers, but with custom symbols:
  # 'w' = 0
  # 'x' = 1
  # 'y' = 2
  # 'z' = 3
  my $base_4 = Math::NumberBase->new(4, 'wxyz');

  print $base_16->to_decimal('1ac2'), "\n";
  print $base_16->from_decimal(325), "\n";
  print $base_16->convert_to('1ac2', $base_4), "\n";
  print $base_16->convert_from('yzxw', $base_4), "\n";

=head1 DESCRIPTION

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

=cut

sub new {
    my ($class, $base, $symbols) = @_;

    if (not defined $base) {
        # default base = 10
        $base = 10;
    }

    if ($base < 2) {
        die '$base can not be less than 2';
    }

    if (int $base != $base) {
        die '$base must be an integer';
    }

    my @symbols_array = ();

    if (not defined $symbols) {
        # create default symbols
        if ($base > 36) {
            die 'Can not guess what should be the $symbols when $base > 36 and $symbols is not defined';
        }
        my @numalpha = (0 .. 9, 'a' .. 'z');
        @symbols_array = splice @numalpha, 0, $base;
    }
    else {
        @symbols_array = split //, $symbols;
    }

    # check duplicates
    my $value = 0;
    my %symbol_value_map = map { $_ => $value++ } @symbols_array;
    if (scalar keys %symbol_value_map != scalar @symbols_array) {
        die '$symbols contains duplicate(s)';
    }

    if (scalar @symbols_array != $base) {
        die '$symbols length is not equal to $base';
    }

    my $self = bless {
        '_base' => $base,
        '_symbols' => \@symbols_array,
        '_symbol_value_map' => \%symbol_value_map
    }, $class;

    return $self;
}

=head2 get_base( )

Returns the base.

=cut

sub get_base {
    return shift->{'_base'};
}

=head2 get_symbols( )

Returns an arrayref of symbols.

  my $base_3 = Math::NumberBase->new(3, 'abc');
  my $symbols = $base_3->get_symbols();

  # $symbols = ['a', 'b', 'c'];

=cut

sub get_symbols {
    return shift->{'_symbols'};
}

=head2 get_symbol_value_map( )

Returns a hashref of symbol => value map.

  my $base_3 = Math::NumberBase->new(3, 'abc');
  my $symbol_map = $base_3->get_symbol_value_map();

  # $symbol_map = {
  #     'a' => 0,
  #     'b' => 1,
  #     'c' => 2
  # };

=cut

sub get_symbol_value_map {
    return shift->{'_symbol_value_map'};
}

=head2 to_decimal(<string>)

Convert to decimal.

  my $base_3 = Math::NumberBase->new(3, 'abc');

  # convert 'cab' in base 3 to a decimal number
  my $in_decimal = $base_3->to_decimal('cab');

  # $in_decimal = 19;

=cut

sub to_decimal {
    my ($self, $string) = @_;

    my $base = $self->get_base();
    my $symbol_value_map = $self->get_symbol_value_map();

    my $result = 0;

    my $power = 0;
    while (length $string) {
        my $char = chop $string;
        $result += $symbol_value_map->{$char} * ($base ** $power);
        $power++;
    }

    return $result;
}

=head2 from_decimal(<integer>)

Convert from decimal.

  my $base_3 = Math::NumberBase->new(3, 'abc');

  # convert 19 decimal to a base 3 number
  my $in_base_3 = $base_3->from_decimal(19);

  # $in_base_3 = 'cab';

=cut

sub from_decimal {
    my ($self, $in_decimal) = @_;

    my $base = $self->get_base();
    my $symbols = $self->get_symbols();

    my $result = '';
    while ($in_decimal) {
        $result = $symbols->[$in_decimal % $base] . $result;
        $in_decimal = int ($in_decimal / $base);
    }

    return $result;
}

=head2 convert_to(<string>, <Math::NumberBase object>)

Convert a number from this base to another base.

  my $base_3 = Math::NumberBase->new(3, 'abc');
  my $base_4 = Math::NumberBase->new(4);

  # convert 'cab' in base 3 to a base 4 number
  my $in_base_4 = $base_3->convert_to('cab', $base_4);

  # $in_base_4 = '103';

=cut

sub convert_to {
    my ($self, $string, $number_base) = @_;

    return $number_base->from_decimal($self->to_decimal($string));
}

=head2 convert_from(<string>, <Math::NumberBase object>)

Convert a number from another base to this base.

  my $base_3 = Math::NumberBase->new(3, 'abc');
  my $base_4 = Math::NumberBase->new(4);

  # convert 'cab' in base 3 to a base 4 number
  my $in_base_4 = $base_4->convert_from('cab', $base_3);

  # $in_base_4 = '103';

=cut

sub convert_from {
    my ($self, $string, $number_base) = @_;

    return $self->from_decimal($number_base->to_decimal($string));
}

=head1 AUTHOR

Yehezkiel Syamsuhadi <yehezkielbs@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Yehezkiel Syamsuhadi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
