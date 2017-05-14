print "1..1\n";

use strict;

require HTML::FormatNroff;
use HTML::Parse;
require HTML::Testing;

my $man_date = '20 Dec 97';
my $name = "simpleHTML";

my $html_source =<<END_INPUT;
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

$expected .=<<END_EXPECTED;
.PP
 This is the body. It is very simple.  
END_EXPECTED

my $tester = new HTML::Testing(name => $name,
			       man_date => $man_date,
			       project => 'FormatNroff',
			       man_header => 1,
			       expected => $expected,
			       html_source => $html_source
			       );
$tester->run_test();

1;
