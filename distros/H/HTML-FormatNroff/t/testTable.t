
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use HTML::Parse;
use NRoffTesting;

my $man_date = '20 Dec 97';
my $name = 'testTable';

my $html_source = <<'END_HTML';
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head>
<title>TestTable</title>
</head>
<body>
<h1>TestTable</h1>
<TABLE WIDTH="70%" ALIGN="CENTER">
<TR><TH>Age</TH><TH>Cost</TH></TR>
<TR><TD>1</TD><TD>10</TD></TR>
<TR><TD>2</TD><TD>20</TD></TR>
</TABLE>
<hr>
</body>
</html>
END_HTML

my $expected =<<'END_OUTPUT';

.SH TestTable

.PP

.in 0
.sp
.TS
tab(%), center;
lw(1.80i) lw(2.40i)
lw(1.80i) lw(2.40i)
lw(1.80i) lw(2.40i).
T{
.ad l
.fi
\fBAge\fR
.nf
T}%T{
.ad l
.fi
\fBCost\fR
.nf
T}
.sp
T{
.ad l
.fi
1
.nf
T}%T{
.ad l
.fi
10
.nf
T}
.sp
T{
.ad l
.fi
2
.nf
T}%T{
.ad l
.fi
20
.nf
T}
.sp
.TE

.br
.ta 6.5i
.tc _

.br

END_OUTPUT

my $tester = NRoffTesting->new(
    name        => $name,
    man_date    => $man_date,
    project     => 'FormatNroff',
    man_header  => 0,
    expected    => $expected,
    html_source => $html_source
);

$tester->run_test();

done_testing;
