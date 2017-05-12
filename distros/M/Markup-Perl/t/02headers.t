use blib;
use strict;
use vars qw($perl $output $test_file $test_result);

use Test::More tests => 4;

$perl = $^X;
$output = `$perl t/basic1.xml`;
ok($output, "test script can be run:[".length($output)." bytes]");

($test_result) = $output =~ m{Content-length: (.*?)[\r\n\f]}i;
is($test_result, '180', "content-length ok: [$test_result]");

($test_result) = $output =~ m{Content-Type: (.*?)[\r\n\f]}i;
is($test_result, 'text/html; charset=UTF-8', "content-type ok: [$test_result]");

($test_result) = $output =~ m{color: (.*?)[\r\n\f]}i;
is($test_result, 'red', "custom header ok: [$test_result]");

print $output;