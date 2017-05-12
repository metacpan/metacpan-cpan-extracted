use blib;
use strict;
use vars qw($perl $output $test_file $test_result);

use Test::More tests => 4;

$perl = $^X;
$test_file = 't/edge1.xml';
$output= `$perl $test_file`;

($test_result) = $output =~ m/[\r\n\f](.*)$/i;
is($test_result, '0123456789', "all perl ok: [$test_result]");

$test_file = 't/edge2.xml';
$output= `$perl $test_file`;

($test_result) = $output =~ m/[\r\n\f](.*)$/i;
is($test_result, 'Just text.', "all text ok: [$test_result]");

$test_file = 't/edge3.xml';
$output= `$perl $test_file`;

($test_result) = $output =~ m{<h1>(.*?)</h1>};
is($test_result, 'Some text.', "text first ok: [$test_result]");

($test_result) = $output =~ m/[\r\n\f](.*)$/i;
is($test_result, '€\'">/\\', "perl last and funny src text ok: [$test_result]");

#print $output;