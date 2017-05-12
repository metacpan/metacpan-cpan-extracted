use strict;
use warnings;
use Digest::BLAKE;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $blake = Digest::BLAKE->new(224);
    $blake->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
