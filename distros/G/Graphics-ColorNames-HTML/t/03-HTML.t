#!/usr/bin/perl

#!/usr/bin/perl

use Test::Most;

use Types::Common::Numeric qw/ IntRange /;
use Types::Standard qw/ HashRef /;

use Graphics::ColorNames::HTML;

ok my $colors = Graphics::ColorNames::HTML->NamesRgbTable(), 'NamesRgbTable';

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

is $colors->{fuchsia}, $colors->{fuscia}, 'alternate spellings';

done_testing;
