use strict;
use warnings;
use Digest::SHAvite3;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $shavite3 = Digest::SHAvite3->new(224);
    $shavite3->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
