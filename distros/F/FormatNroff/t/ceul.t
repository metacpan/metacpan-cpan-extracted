print "1..1\n";

use strict;

require HTML::FormatNroffSub;
use HTML::Parse;
$HTML::Parse::IMPLICIT_TAGS = 0;
require HTML::Testing;

my $man_date = '20 Dec 97';
my $name = "ceul";

my $html_source = <<'END_HTML';
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML>
<HEAD>
<TITLE>TestTable</TITLE>
</HEAD>
<BODY>
This is some text.
<CENTER>
This is centered.
<P>
<U>This is centered and underlined.</U>
</CENTER>
<HR>
This follows the horizontal line.
<BODY>
</HTML>
END_HTML

my $expected =<<'END_OUTPUT';
    This is some text. 
.ce
 This is centered. 
.PP

.ce
 
.ce

.ul
This is centered and underlined.
.ce
  
.br
.ta 6.5i
.tc _
	
.br
 This follows the horizontal line.  
END_OUTPUT

my $tester = new HTML::Testing(name => $name,
			       man_date => $man_date,
			       project => 'FormatNroff',
			       man_header => 0,
			       expected => $expected,
			       html_source => $html_source
			       );
$tester->run_test();

1;
