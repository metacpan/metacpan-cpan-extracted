use strict;
use warnings;
use Digest::Luffa;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $luffa = Digest::Luffa->new(224);
    $luffa->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
