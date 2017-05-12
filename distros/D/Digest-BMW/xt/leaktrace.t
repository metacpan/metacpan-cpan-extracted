use strict;
use warnings;
use Digest::BMW;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $bmw = Digest::BMW->new(224);
    $bmw->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
