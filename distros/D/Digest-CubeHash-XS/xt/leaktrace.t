use strict;
use warnings;
use Digest::CubeHash::XS;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $cubehash = Digest::CubeHash::XS->new(224);
    $cubehash->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
