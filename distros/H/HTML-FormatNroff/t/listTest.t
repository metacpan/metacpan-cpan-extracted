use strict;
use warnings;
use lib 't/lib';

use Test::More;
use HTML::Parse;
use NRoffTesting;

my $man_date = '20 Dec 97';
my $name = "listTest";
my $project = "FormatNroff";
my $man_header = 0;

my $html_source = <<'END_HTML';
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML>
<HEAD>
<TITLE>ListTest</TITLE>
</HEAD>
<BODY>
This is some text before the list.
<OL>
<LI>Item one.
<LI>Item <B>two</B>.
<LI>Item <BR>Three.
</OL>
This line follows the list.
<BODY>
</HTML>
END_HTML

my $expected =<<'END_OUTPUT';

.PP
 This is some text before the list.
.sp 1

.ti +2
1 Item one.
.sp 1

.ti +2
2 Item \fBtwo\fR.
.sp 1

.ti +2
3 Item
.br
Three.
.sp 1
 This line follows the list.
END_OUTPUT

my $tester = NRoffTesting->new(
    name        => $name,
    man_date    => $man_date,
    project     => $project,
    man_header  => $man_header,
    expected    => $expected,
    html_source => $html_source
);
$tester->run_test();

done_testing;
