#!/usr/local/bin/perl
# CGI script that creates a fill-out form
# and echoes back its values.

use CGI qw/:standard/;
print header,
	start_html('Poly[nomial] Wanna Cracker!?'),
	start_form(-action=>'/cgi-bin/server.cgi',-target=>'server'),
	"Enter Commands:",p
	textarea(-name=>'cmds',-rows=>'10',-cols=>'40'),submit,br
	end_form,
	hr;

	if (param()) {
		$s = param('cmds');
		@lines = split(';',$s);
		foreach $i (0..$#lines)
		{
			print $lines[$i],p;
		}
		print hr;
	}

