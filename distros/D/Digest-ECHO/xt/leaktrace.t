use strict;
use warnings;
use Digest::ECHO;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $echo = Digest::ECHO->new(224);
    $echo->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
