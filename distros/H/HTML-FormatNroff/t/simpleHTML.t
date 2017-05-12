use strict;
use warnings;
use lib 't/lib';

use Test::More;
use HTML::Parse;
use NRoffTesting;

my $man_date = '30 Dec 2014';
my $name     = "simpleHTML";

my $html_source = <<END_INPUT;
<HTML>
<HEAD>
<TITLE>This is the Title</TITLE>
</HEAD>
<BODY>
This is the body.
It is very simple.
</BODY>
</HTML>
END_INPUT

my $expected = ".TH \"$name\" \"1\" \"$man_date\" \"FormatNroff\"  \n";

$expected .= <<END_EXPECTED;
.PP
 This is the body. It is very simple.
END_EXPECTED

my $tester = NRoffTesting->new(
    name        => $name,
    man_date    => $man_date,
    project     => 'FormatNroff',
    man_header  => 1,
    expected    => $expected,
    html_source => $html_source
);
$tester->run_test();

done_testing;
