#!/usr/local/bin/perl
# CGI script that creates a fill-out form
# and echoes back its values.

use CGI qw/:standard/;
use Algebra::Parser;

&main;

sub
main
{
	print	header,
		start_html('Poly[nomial] Wanna Cracker!?');

	if (param()) {
		$s = param('cmds');
		@line = split(";",$s);

		$p = Parser->new();
		foreach $i (0..$#line)
		{
			$line[$i] =~ s/\s//g;
			next if (length($line[$i]) == 0);
			$s = $p->parseLine($line[$i],$i+1);
			if (length($s) > 0)
			{
				print "$s<br>\n";
			}
		}
	}
}

