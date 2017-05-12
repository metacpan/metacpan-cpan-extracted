sub backend_header {
	print "Content-type: text/html\n\n";
	print <<HTML;
<HTML>
<HEAD>
<TITLE>Merge backend</TITLE>
</HEAD>
<BODY BGCOLOR="Silver">
HTML
	foreach (param(), 'create') {
#		print $_ , " = ", join(" || ", param($_)), "<BR>\n";
	}
}

sub backend_footer {
	print <<HTML;
<HR>
Merge &copy; 1998-2002 Raz Information systems.<BR>
</BODY>
</HTML>
HTML
}

sub openform {
	my ($action, @fields) = @_;
	print <<HTML;
<FORM ACTION="$ENV{'SCRIPT_NAME'}" METHOD=POST>
<INPUT NAME="action" VALUE="$action" TYPE=HIDDEN>
HTML
	if ($type) {
		print qq!<INPUT NAME="type" VALUE="$type" TYPE=HIDDEN>\n!;
		if ($this) {
			print qq!<INPUT NAME="$type" VALUE="$this" TYPE=HIDDEN>\n!;
		}
	}
	&HTML::Merge::Development::Transfer;
	foreach (@fields) {
		my $val = eval '$' . $_; # do NOT use soft references
		print qq!<INPUT NAME="$_" VALUE="$val" TYPE=HIDDEN>\n!;
	}
}
1;
