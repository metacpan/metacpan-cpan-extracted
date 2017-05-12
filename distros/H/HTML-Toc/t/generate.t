#--- generate.t ---------------------------------------------------------------
# function: Test ToC generation.

use strict;
use Test::More tests => 14;
use Test::Differences;

use HTML::Toc;
use HTML::TocGenerator;

my ($filename);
my $toc          = HTML::Toc->new;
my $tocGenerator = HTML::TocGenerator->new;

$toc->setOptions({
	'doLinkToToken' => 0,
	'levelIndent'   => 0,
	'header'        => '',
	'footer'        => '',
});


BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
	open(FILE, ">$filename") || die "Can't create $filename: $!";
	print FILE <<'EOT';
<h1>Header</h1>
EOT
	close(FILE);
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- 1. generate --------------------------------------------------------------

$tocGenerator->generate($toc, "<h1>Header</h1>");
eq_or_diff($toc->format(), "<ul>\n<li>Header</li>\n</ul>", 'generate');


#--- 2. generateFromFile ------------------------------------------------------

$tocGenerator->generateFromFile($toc, $filename);
eq_or_diff($toc->format(), "<ul>\n<li>Header</li>\n</ul>", 'generateFromFile');


#--- 3. generateFromFiles -----------------------------------------------------

$tocGenerator->generateFromFile($toc, [$filename, $filename]);
eq_or_diff($toc->format(), "<ul>\n<li>Header</li>\n<li>Header</li>\n</ul>", 'generateFromFiles');


#--- 4. doLinkToToken -----------------------------------------------------

$toc->setOptions({'doLinkToToken' => 1});
$tocGenerator->generateFromFile($toc, $filename, {'globalGroups' => 1});
eq_or_diff($toc->format(), "<ul>\n<li><a href=\"#h-1\">Header</a></li>\n</ul>", 'doLinkToToken');


#--- 5. doLinkToFile -------------------------------------------------------

$toc->setOptions({'doLinkToFile' => 1});
$tocGenerator->generateFromFile($toc, $filename);
eq_or_diff($toc->format(), "<ul>\n<li><a href=\"$filename#h-1\">Header</a></li>\n</ul>", 'doLinkToFile');


#--- 6. templateAnchorHrefBegin -----------------------------------------------

	# Set options
$toc->setOptions({'templateAnchorHrefBegin' => '"test-$file"'});
	# Generate ToC
$tocGenerator->generateFromFile($toc, $filename);
	# Test ToC
eq_or_diff($toc->format(), "<ul>\n<li>test-".$filename."Header</a></li>\n</ul>", 'templateAnchorHrefBegin');
	# Reset options
$toc->setOptions({'templateAnchorHrefBegin' => undef});


#--- 7. templateAnchorHrefBegin function --------------------------------------

sub AssembleAnchorHrefBegin {
		# Get arguments
	my ($aFile, $aGroupId, $aLevel, $aNode) = @_;
		# Return value
	return $aFile . $aGroupId . $aLevel . $aNode;
}  # AssembleAnchorHrefBegin()


	# Set options
$toc->setOptions({'templateAnchorHrefBegin' => \&AssembleAnchorHrefBegin});
	# Generate ToC
$tocGenerator->generateFromFile($toc, $filename);
	# Test ToC
eq_or_diff($toc->format(), "<ul>\n<li>".$filename."h11Header</a></li>\n</ul>", 'templateAnchorHrefBegin');
	# Reset options
$toc->setOptions({'templateAnchorHrefBegin' => undef});


#--- 8. levelToToc no levels available ---------------------------------------

$toc->setOptions({'levelToToc' => '2'});
$tocGenerator->generate($toc, "<h1>Header</h1>");
eq_or_diff($toc->format(), "", 'levelToToc');


#--- 9. levelToToc level 1 ---------------------------------------------------

	# Set options
$toc->setOptions({
	'levelToToc' => '1',
	'doLinkToToken' => 0,
});
$tocGenerator->generate($toc, "<h1>Header1</h1>\n<h2>Header2</h2>");
eq_or_diff($toc->format(), "<ul>\n<li>Header1</li>\n</ul>", 'levelToToc level 1');


#--- 10. levelToToc level 2 --------------------------------------------------

	# Set options
$toc->setOptions({
	'levelToToc' => '2',
	'doLinkToToken' => 0,
});
$tocGenerator->generate($toc, "<h1>Header1</h1>\n<h2>Header2</h2>");
eq_or_diff($toc->format(), "<ul>\n<li>Header2</li>\n</ul>", 'levelToToc level 2');
	# Restore options
$toc->setOptions({
	'levelToToc' => '.*',
});


#--- 11. tokenToToc empty array ----------------------------------------------

	# Set options
$toc->setOptions({'tokenToToc' => []});
$tocGenerator->generate($toc, "<h1>Header</h1>");
eq_or_diff($toc->format(), "", 'tokenToToc');


#--- 12. groups nested --------------------------------------------------------

$toc->setOptions({
	'doNestGroup' => 1,
	'tokenToToc' => [
		{
			'level' => 1,
			'tokenBegin' => '<h1 class=-appendix>'
		}, {
			'groupId' => 'appendix',
			'level' => 1,
			'tokenBegin' => '<h1 class=appendix>'
		}
	]
});
$tocGenerator->generate(
	$toc, "<h1>Header1</h1>\n<h1 class=appendix>Appendix</h1>"
);
eq_or_diff($toc->format() . "\n", <<HTML, 'groups nested');
<ul>
<li>Header1
<ul>
<li>Appendix</li>
</ul>
</li>
</ul>
HTML


#--- 13. groups not nested ----------------------------------------------------

$toc->setOptions({
	'doNestGroup' => 0,
	'tokenToToc' => [
		{
			'level' => 1,
			'tokenBegin' => '<h1 class=-appendix>'
		}, {
			'groupId' => 'appendix',
			'level' => 1,
			'tokenBegin' => '<h1 class=appendix>'
		}
	]
});
$tocGenerator->generate(
	$toc, "<h1>Header1</h1>\n<h1 class=appendix>Appendix</h1>"
);
eq_or_diff($toc->format() . "\n", <<HTML, 'groups not nested');
<ul>
<li>Header1</li>
</ul>
<ul>
<li>Appendix</li>
</ul>
HTML


#--- 14. text and children passed to templateAnchorName ----------------

sub AssembleAnchorName {
		# Get arguments
	my ($aFile, $aGroupId, $aLevel, $aNode, $aText, $aChildren) = @_;
		# Return value
	return $aChildren;
}  # AssembleAnchorHrefBegin()

	# Set options
$toc->setOptions({
    'doLinkToToken' => 1,
    'tokenToToc' => [{
	'level'      => 1,
	'tokenBegin' => '<h1>'
    }],
    'templateAnchorName' => \&AssembleAnchorName
});
	# Generate ToC
$tocGenerator->generate($toc, '<h1><b>very</b> important</h1>');
	# Test ToC
eq_or_diff($toc->format(),
    "<ul>\n<li><a href=\"#<b>very</b> important\">very important</a></li>\n</ul>",
    'text and children passed to templateAnchorName'
);
	# Reset options
$toc->setOptions({'templateAnchorName' => undef});
