use strict;
use warnings;
use lib 't/lib';

use Test::More;
use HTML::Parse;
use NRoffTesting;

note "Empty Subclass Test\n";

my $man_date = '20 Dec 97';
my $name = 'FormatNroffSub';

my $html_source =<<END_HERE ;
<H1>First <B>Section</B></H1>
with some <I>text</I>
<TABLE>
<TR><TH>Amount</TH><TH>Cost</TH></TR>
<TR><TD>1</TD><TD>10</TD></TR>
<TR><TD>10</TD><TD>8</TD></TR>
</TABLE>
END_HERE

my $expected = ".TH \"$name\" \"1\" \"$man_date\" \"HTML\"\n";

$expected .=<<'END_EXPECTED' ;
.SH First \fBSection\fR

.PP
 with some \fItext\fR
.in 0
.sp
.TS
tab(%), expand;
lw(3.60i) lw(2.40i)
lw(3.60i) lw(2.40i)
lw(3.60i) lw(2.40i).
T{
.ad l
.fi
\fBAmount\fR
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
10
.nf
T}%T{
.ad l
.fi
8
.nf
T}
.sp
.TE

END_EXPECTED

my $tester = NRoffTesting->new(
    name        => $name,
    man_date    => $man_date,
    project     => 'HTML',
    man_header  => 1,
    expected    => $expected,
    html_source => $html_source
);
$tester->run_test();

done_testing;
