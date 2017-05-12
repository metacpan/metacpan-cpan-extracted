#!/usr/bin/perl

use HTML::Merge::Development;
use HTML::Merge::Compile;
use File::Find;

ReadConfig();

if (fork) {
	print "Content-type: text/html\n\n";
	print <<HTML;
<HTML>
<BODY onLoad="init()">
<SCRIPT>
<!--
	function init() {
		opener.focus();
		window.close();
	}
// -->
</SCRIPT>
</BODY>
</HTML>
HTML
	exit;
}

find(\&one, $HTML::Merge::Ini::TEMPLATE_PATH);

sub one {
	my $source = $File::Find::name;
	my $target = $source;
	$target =~ s/^$HTML::Merge::Ini::TEMPLATE_PATH/$HTML::Merge::Ini::PRECOMPILED_PATH/;
	$target .= ".pl";
	HTML::Merge::Compile::safecreate($target) unless -e $target;
	print STDERR "$source => $target\n";

	eval { HTML::Merge::Compile::CompileFile($source, $target); };
}
