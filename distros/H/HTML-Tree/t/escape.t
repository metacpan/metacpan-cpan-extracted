#!/usr/bin/perl -T

use warnings;
use strict;

# Tests that the following translations take place, and none other:
#
#  & => &amp;
#  < => &lt;
#  > => &gt;
#  ' => &apos;
#  " => &quot;
#
# Further tests that already-escaped things are not further escaped.
#
# Escapes are defined in the XML spec:
#    http://www.w3.org/TR/2006/REC-xml11-20060816/#dt-escape

my %translations;
my $tests = 0;

BEGIN {
    %translations = (
        'x > 3' => 'x &gt; 3',
        'x < 3' => 'x &lt; 3',
        '< 3 >' => '&lt; 3 &gt;',
        "he's"  => "he&apos;s",
## MS "smart" quotes don't get escaped (single)
        "he’s"  => "he’s",
        '"his"' => '&quot;his&quot;',
## MS "smart" quotes don't get escaped (single)
        '‘his’' => '‘his’',
## MS "smart" quotes don't get escaped (double)
        '“his”'           => '“his”',
        '1&2'             => '1&amp;2',
        '1&#38;2'         => '1&#38;2',
        '1&amp;2'         => '1&amp;2',
        '1&amp 2'         => '1&amp;amp 2',
        '1&#38 2'         => '1&amp;#38 2',
        'abc'             => 'abc',
        'número'          => 'número',
        '&dArr;'          => '&dArr;',
        '&OElig;'         => '&OElig;',
        '&sup2;'          => '&sup2;',
        '&no\go;'         => '&amp;no\go;',
        '&amp;foo;'       => '&amp;foo;',
        '&amp;foo; &bar;' => '&amp;foo; &bar;',
## RT 18568
        'This &#x17f;oftware has &#383;ome bugs' =>
            'This &#x17f;oftware has &#383;ome bugs',
    );

    $tests = keys(%translations) + 1;
}

use Test::More tests => $tests + 3;

use HTML::Element;

$HTML::Element::encoded_content = 1;

foreach my $orig ( keys %translations ) {
    my $new = $orig;
    HTML::Element::_xml_escape($new);
    is( $new, $translations{$orig}, "Properly escaped: $orig" );
}

# test that multiple runs don't change the value
my $test_orig = '&amp;foo; &bar;';
my $test_str  = $test_orig;
HTML::Element::_xml_escape($test_str);
is( $test_str, $test_orig, "Multiple runs 1" );
HTML::Element::_xml_escape($test_str);
is( $test_str, $test_orig, "Multiple runs 2" );
HTML::Element::_xml_escape($test_str);
is( $test_str, $test_orig, "Multiple runs 3" );

# test default path, always encode '&'
$HTML::Element::encoded_content = 0;
$test_str  = $test_orig;
my $test_expected = '&amp;amp;foo; &amp;bar;';
HTML::Element::_xml_escape($test_str);
is( $test_str, $test_expected, "Default encode" );

