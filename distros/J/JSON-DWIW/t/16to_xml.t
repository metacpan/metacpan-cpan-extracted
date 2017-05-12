#!/usr/bin/env perl

# Original authors: don
# $Revision: 1302 $


use strict;
use warnings;

use Test::More tests => 5;

use JSON::DWIW;

my $json = '{"foo":"bar", "a":[ 1, 2, 3], "b":{"one":1,"two":2}';
$json .= ', "c":{"three":3, "four": [ 4.1, 4.2, 4.3 ]}}';

my $xml = JSON::DWIW::json_to_xml($json);
my $expected = '<a>1</a><a>2</a><a>3</a><b><one>1</one><two>2</two></b><c><four>4.1</four><four>4.2</four><four>4.3</four><three>3</three></c><foo>bar</foo>';

ok($xml eq $expected, 'hash at top level');


$json = '{"foo":"bar", "a":[ 1, 2, 3], "b":{"one":1,"two":2}';
$json .= ', "c":{"three":3, "four": [ 4.1, "\u00e9", "\u706b" ]}}';
$xml = JSON::DWIW::json_to_xml($json);
$expected = "<a>1</a><a>2</a><a>3</a><b><one>1</one><two>2</two></b><c><four>4.1</four><four>\xe9</four><four>\x{706b}</four><three>3</three></c><foo>bar</foo>";

ok($xml eq $expected, 'multibyte utf-8');


$json = '{"foo":"bar><&", "a":[ 1, 2, 3], "b":{"one":1,"two":2}';
$json .= ', "c":{"three":3, "four": [ 4.1, "\u00e9", "\u706b" ]}}';
$xml = JSON::DWIW::json_to_xml($json);
$expected = "<a>1</a><a>2</a><a>3</a><b><one>1</one><two>2</two></b><c><four>4.1</four><four>\xe9</four><four>\x{706b}</four><three>3</three></c><foo>bar&gt;&lt;&amp;</foo>";

ok($xml eq $expected, 'escapes');


$json = '{"foo":"bar><&", "a":[ 1, 2, 3], "b & >":{"one":1,"two":2}';
$json .= ', "c ":{"three":3, "four": [ 4.1, "\u00e9", "\u706b" ]}}';
$xml = JSON::DWIW::json_to_xml($json);
$expected = "<a>1</a><a>2</a><a>3</a><b____><one>1</one><two>2</two></b____><c_><four>4.1</four><four>\xe9</four><four>\x{706b}</four><three>3</three></c_><foo>bar&gt;&lt;&amp;</foo>";

ok($xml eq $expected, 'bad keys/tags');


$json = '{"foo":"bar><&", "a":[ 1, 2, 3, { "deep_foo": 5, "deep_bar": 6 }], "b":{"one":1,"two":2}';
$json .= ', "c":{"three":3, "four": [ 4.1, "\u00e9", "\u706b" ]}}';
$xml = JSON::DWIW::json_to_xml($json);
$expected = "<a>1</a><a>2</a><a>3</a><a><deep_bar>6</deep_bar><deep_foo>5</deep_foo></a><b><one>1</one><two>2</two></b><c><four>4.1</four><four>\x{e9}</four><four>\x{706b}</four><three>3</three></c><foo>bar&gt;&lt;&amp;</foo>";

ok($xml eq $expected, 'hash inside array');
