
use strict;
use warnings;
use lib 't/lib';

use Test::More;
use HTML::Parse;
use NRoffTesting;

my $man_date = '20 Dec 97';
my $name = "tinyTable";

my $html_source =<<END_HERE ;
This is some text.
<TABLE>
<TR><TD>1</TD></TR>
</TABLE>
This is some more text.
END_HERE

my $expected = ".TH \"$name\" \"1\" \"$man_date\" \"HTML\"\n";

$expected .=<<'END_EXPECTED' ;
.PP
This is some text.
.in 0
.sp
.TS
tab(%), expand;
lw(6.00i).
T{
.ad l
.fi
1
.nf
T}
.sp
.TE
 This is some more text.
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
