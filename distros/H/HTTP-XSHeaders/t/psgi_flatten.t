use strict;
use warnings;

use Test::More;

use HTTP::XSHeaders;

my $h = HTTP::XSHeaders->new(foo => 1, bar => 2, foo => 3);
is_deeply(
    $h->psgi_flatten,
    [ 'Bar', 2, 'Foo', 1, 'Foo', 3 ],
    'psgi_flatten returns sorted PSGI pairs',
);

my $flat = $h->psgi_flatten_without_sort;
ok(@{$flat} % 2 == 0, 'psgi_flatten_without_sort returns even number of elements');
my @pairs;
for (my $i = 0; $i < @{$flat}; $i += 2) {
    push @pairs, "$flat->[$i]=$flat->[$i + 1]";
}
is_deeply(
    [ sort @pairs ],
    [ sort 'Bar=2', 'Foo=1', 'Foo=3' ],
    'psgi_flatten_without_sort returns same pairs',
);

done_testing();
