#!/usr/bin/perl

use HTML::Merge::Development;
use HTML::Merge::Error;
use CGI qw/:standard/;
use strict;

ReadConfig();

my $template = param('template');
my $from = param('from');
my $title = ($from eq 'view') ? 'Source for' : 'Run';

print "Content-type: text/html\n\n";

unless ($template) {
	&HTML::Merge::Error::ForceError("No template specified");
	exit;
}
my $fn = "$HTML::Merge::Ini::TEMPLATE_PATH/$template";
my $self = "$ENV{'SCRIPT_NAME'}?$extra&template=$template&from=$from";

my $code = param('code');

if ($code) {
	unless (open(O, ">$fn")) {
		&HTML::Merge::Error::ForceError("Could not rewrite $fn: $!");
		exit;
	}

	print O $code;
	close(O);
	print <<HTML;

	<SCRIPT>
	<!--
		location.replace('$self');
	// -->
	</SCRIPT>			
HTML
	exit;
}

print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">

<HTML>
<HEAD>
        <TITLE>$title $template</TITLE>
</HEAD>

<BODY BGCOLOR='white'>
HTML

if($from eq 'view') {
	print <<HTML;
<FONT FACE=Arial SIZE=6 COLOR=black><CENTER><B>Source: $template</B>
</CENTER></FONT><BR>
<CENTER><TABLE BGCOLOR=yellow><TR><TD><FONT FACE=Arial SIZE=5 COLOR=black>
RAZ Information System LTD.
</TD></TR></TABLE></CENTER></FONT>
<BR><BR>

<FORM METHOD=POST ACTION="$ENV{'SCRIPT_NAME'}">
HTML
	&HTML::Merge::Development::Transfer;
	print <<HTML;
<INPUT TYPE=HIDDEN NAME="from" VALUE="view">
<INPUT TYPE=HIDDEN NAME="template" VALUE="$template">
<TABLE>
  <TR>
    <TD>
      &nbsp;
    </TD>
    <TD COLSPAN=2 WIDTH=100%>
HTML

	print '<TEXTAREA NAME="code" COLS=80 ROWS=25 WRAP=PHYSICAL>';

	open(I, $fn);
	my $text = join("", <I>);
	close(I);

	$text =~ s/"/&quot;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;

	print "$text</TEXTAREA>\n";

	print <<HTML;
    <TD>
  </TR>
  <TR>
    <TD COLSPAN=2 WIDTH=50% ALIGN=RIGHT>
      <INPUT TYPE=SUBMIT VALUE="Update">
    </TD>
    <TD WIDTH=50%>
      <INPUT TYPE=BUTTON VALUE="Close" onClick="opener.focus(); window.close();">
    </TD>
  </TR>
</TABLE>
</FORM>
HTML
}

print <<HTML;
<FORM ACTION="runsource.pl" TARGET="runner" 
	onSubmit="createrunner(); return true;">
<INPUT TYPE=HIDDEN NAME="config" VALUE="$extra">
<INPUT TYPE=HIDDEN NAME="template" VALUE="$template">
HTML

foreach (1 .. 8) {
	print <<HTML;
	Field name: <INPUT NAME="key$_">
	Field data: <INPUT NAME="data$_"><BR>
HTML
}

&HTML::Merge::Development::Transfer;

print <<HTML;
<INPUT TYPE=SUBMIT VALUE="Run template">
<INPUT TYPE=BUTTON VALUE="Close" onClick="opener.focus(); window.close();">
</FORM>
<SCRIPT>
<!--
	function createrunner() {
        	var myWin=open("about:blank",
                "runner",
                "screenY=0,stop=0,screenX=0,left=0,width=60,height=40");

	}
// -->
</SCRIPT>
</HTML>

HTML
