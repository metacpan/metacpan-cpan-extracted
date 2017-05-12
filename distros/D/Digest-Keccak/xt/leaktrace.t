use strict;
use warnings;
use Digest::Keccak;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $keccak = Digest::Keccak->new(224);
    $keccak->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
