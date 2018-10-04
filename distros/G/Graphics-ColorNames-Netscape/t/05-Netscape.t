#!/usr/bin/perl

use Test::Most;

use Types::Common::Numeric qw/ IntRange /;
use Types::Standard qw/ HashRef /;

use Graphics::ColorNames::Netscape;

ok my $colors = Graphics::ColorNames::Netscape->NamesRgbTable(), 'NamesRgbTable';

my $type = HashRef [ IntRange [ 0, 0xffffff ] ];

ok $type->check($colors), 'returns expected type';

cmp_deeply [ keys %$colors ], array_each(
    code(
        sub {
            my ($name) = @_;
            return ( $name eq lc($name) ) &&
                ( $name !~ m/\W/ )
        }
    )
  ),
  'normalized names';

isnt $colors->{gold} => $colors->{mediumblue}, 'gold != mediumblue';
isnt $colors->{lightblue} => $colors->{mediumblue}, 'lightblue != mediumblue';
isnt $colors->{lightblue} => $colors->{gold}, 'lightblue != gold';

done_testing;
