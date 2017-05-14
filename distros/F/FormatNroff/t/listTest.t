print "1..1\n";

use strict;

require HTML::Testing;

#$HTML::Parse::IMPLICIT_TAGS = 0;

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

#my $html = parse_html("$html_source");
#my $formatter = new HTML::FormatNroffSub(name => "${name}_test", 
#					 project => 'FormatNroff', 
#					 man_date => $man_date,
#					 man_header => 0);
#my $actual = $formatter->format($html);
#
#open(FILE, ">${name}_actual.out");
#print FILE $actual;
#close(FILE);
#
#open(FILE, ">${name}_expected.out");
#print FILE $expected;
#close(FILE);
#
#open(FILE, ">${name}.html");
#print FILE $html_source;
#close(FILE);
#
#if("$actual" ne "$expected") {
##    print STDERR "Actual=\"\n$actual\n\"";
##    print STDERR "Expected=\"\n$expected\n\"";
#    print 'not ok';
#} else {
#   print 'ok';
#}

my $tester = new HTML::Testing(name => $name,
			       man_date => $man_date,
			       project => $project,
			       man_header => $man_header,
			       expected => $expected,
			       html_source => $html_source
			       );
$tester->run_test();

1;
