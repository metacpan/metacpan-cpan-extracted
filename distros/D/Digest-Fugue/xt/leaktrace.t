use strict;
use warnings;
use Digest::Fugue;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $fugue = Digest::Fugue->new(224);
    $fugue->add('foobar');
};

$try->();

is(leaked_count($try), 0, 'leaks');
