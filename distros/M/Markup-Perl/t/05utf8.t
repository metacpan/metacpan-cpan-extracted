use blib;
use strict;
use vars qw($perl $output $test_file $expected);

use Test::More tests => 6;

$perl = $^X;
$test_file = 't/utf1.xml';

$output= `$perl $test_file`;
$expected = '<h1>smile ☺</h1>';
like($output, qr($expected), "utf-8 text as expected: [$expected]");

$expected = '<h2>€1</h2>';
like($output, qr($expected), "utf-8 print output as expected: [$expected]");

$expected = '<h3>和平:peace</h3>';
like($output, qr($expected), "utf-8 from src is as expected: [$expected]");

$test_file = 't/utf3.xml';
$output= `$perl $test_file`;
$expected = 'Content-length: 12';
like($output, qr($expected), "utf-8 body has header length as expected: [$expected]");

$test_file = 't/notutf.xml';
$output= `$perl $test_file`;

$expected = '<h1>not utf8</h1>';
like($output, qr($expected), "non utf content as expected: [$expected]");

$expected = '<h2>not utf8 either</h2>';
like($output, qr($expected), "non utf src as expected: [$expected]");

print $output;