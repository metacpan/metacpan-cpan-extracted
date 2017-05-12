use strict;
use Test::More;
use Log::StringFormatter;
use URI;
use Scalar::Util qw/dualvar/;

my $dualvar = dualvar 10, "Hello";
my @tests = (
    [['foo'],'foo'],
    [['%s bar','foo'],'foo bar'],
    [[['foo']],q!['foo']!],
    [['uri %s',URI->new("http://example.com/")],'uri http://example.com/'],
    [['%s vs %d', $dualvar, $dualvar], 'Hello vs 10'],
    [[],'']
);

for my $test (@tests) {
    is ( stringf(@{$test->[0]}), $test->[1] );
}

is( stringf({"a" => 1, "b" => 2}), "{'a' => 1,'b' => 2}" );

done_testing;
