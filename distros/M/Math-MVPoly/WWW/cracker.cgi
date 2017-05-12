#!/usr/local/bin/perl

# author: brian guarraci: bguarrac@hotmail.com

use CGI qw/:standard/;
use Algebra::Parser;

	$txt = "";

	if (param()) {
		$txt = param('cmds');
	}	

	print	header, 
		start_html(-title=>'Poly[nomial] Wanna Cracker!?',
			   -BGCOLOR=>"#aaaaaa");
	print	"MVPoly - A multi-variate polynomial package",p; 

	print <<__BLOCK__;

<script language="JavaScript">

var info,infotext;
function info()
{ 
newwindow=window.open("http://gamma.cbos.org/h.htm","",
"height=400,width=600,scrollbars=yes,resizable=yes")
}

</script>

__BLOCK__

	print	start_form(-action=>'/cgi-bin/cracker.cgi');
	print <<__BLOCK__;
<input type="button" value="Open Help" onclick="info()">
__BLOCK__

	print	p,"Enter Commands:",p,
		textarea(-name=>'cmds',-value=>$txt,-rows=>'10',-cols=>'40'),
		br,
		submit(-value=>"Calculate"),
		br,
		end_form,p;

	if (param()) {

		print "Result: ",p;
		$s = param('cmds');
		$p = Parser->new();
		if ($s ne "")
		{
			$r = $p->parseCGICmdString($s);
		}
		else
		{
			$r = "Nothing ventured, nothing gained!<br>\n";
		}
		print $r;
	}

	print	p,hr,
		"Author: <a href=mailto:bguarrac\@hotmail.com>Brian Guarraci</a>",
		br,
		"Copyright 1998";
		

