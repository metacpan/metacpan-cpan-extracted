use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $template = [
    head => [ title => ["My Site"] ],
    body => [ h1    => ["Hello World!"] ]
];

my $h = HTML::Composer->new( cache => 1 );

ok $h->{cache}, 'cache is enabled by default';

my $first  = $h->html($template);
my $second = $h->html($template);

ok $first, 'first call returns a non-empty string';
is $second, $first, 'second call with same input returns identical result';

is scalar( keys %{ $h->{store} } ), 1,
  'one entry exists in the cache store after one unique call';

my $other = $h->html(
    [
        head => [ title => ["Other Site"] ],
        body => [ h1    => ["Goodbye!"] ]
    ]
);

isnt $other, $first, 'different template produces different HTML';
is scalar( keys %{ $h->{store} } ), 2,
  'two entries exist in the cache store after two distinct calls';

my $other_again = $h->html(
    [
        head => [ title => ["Other Site"] ],
        body => [ h1    => ["Goodbye!"] ]
    ]
);

is $other_again, $other,
  'repeated call for second template returns cached result';
is scalar( keys %{ $h->{store} } ), 2,
  'cache store size unchanged after hitting an existing entry';

my $hn = HTML::Composer->new();

ok !$hn->{cache}, 'cache is disabled when cache => 0 is passed';

my $nc_first  = $hn->html($template);
my $nc_second = $hn->html($template);

ok $nc_first, 'no-cache: first call returns a non-empty string';
is $nc_second, $nc_first,
  'no-cache: output is still correct (same input => same output)';
is scalar( keys %{ $hn->{store} } ), 0,
  'no-cache: store remains empty after calls';

my $cold   = HTML::Composer->new()->html($template);
my $warm_h = HTML::Composer->new();
my $warm_1 = $warm_h->html($template);
my $warm_2 = $warm_h->html($template);

is $warm_1, $cold, 'cached instance first call matches cold call output';
is $warm_2, $cold,
  'cached instance second call (cache hit) matches cold call output';

done_testing;
