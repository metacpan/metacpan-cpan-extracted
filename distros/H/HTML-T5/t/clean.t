#!/usr/bin/perl -T

use 5.010001;
use strict;
use warnings;

use Test::Exception;
use Test::More tests => 3;

use HTML::T5;

use lib 't';

use TidyTestUtils;


my $tidy = HTML::T5->new( { wrap => 0 } );
isa_ok( $tidy, 'HTML::T5' );

my $expected_pattern = 'Usage: clean($str [, $str...])';
throws_ok {
    $tidy->clean();
} qr/\Q$expected_pattern\E/,
'clean() croaks when not given a string or list of strings';

my $actual = $tidy->clean('');
$actual = remove_specificity( $actual );

my $expected_empty_html = <<'HERE';
<!DOCTYPE html>
<html>
<head>
<meta name="generator" content="TIDY">
<title></title>
</head>
<body>
</body>
</html>
HERE

is( $actual, $expected_empty_html, '$tidy->clean("") returns empty HTML document' );


done_testing();
exit 0;
