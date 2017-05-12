use blib;
use strict;
use vars qw($perl $output $test_file $test_result);

use Test::More tests => 2;

$perl = $^X;
$test_file = 't/src1.xml';
$output= `$perl $test_file`;

($test_result) = $output =~ m{<h1>(.*?)</h1>};
is($test_result, 'abcdefg', "included src ok: [$test_result]");

($test_result) = $output =~ m{<h3>(.*?)</h3>};
is($test_result, 'FOObar', "variables in src are ok: [$test_result]");

print $output;