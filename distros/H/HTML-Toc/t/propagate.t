#--- propagate.t --------------------------------------------------------------
# function: Test ToC propagation.

use strict;
use Test::More tests => 10;
use Test::Differences;

use HTML::Toc;
use HTML::TocGenerator;
use HTML::TocInsertor;

my ($output, $content, $filename);
my $toc          = HTML::Toc->new;
my $tocGenerator = HTML::TocGenerator->new;
my $tocInsertor  = HTML::TocInsertor->new;

$toc->setOptions({
	'doLinkToToken'  => 0,
	'levelIndent'    => 0,
	'insertionPoint' => 'before <h1>',
	'header'         => '',
	'footer'         => '',
});


BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
	open my $file, ">", $filename or die "Can't create $filename: $!";
	print $file <<'EOT'; close $file;
<h1>Header</h1>
EOT
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- 1. propagate -------------------------------------------------------------

$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
eq_or_diff($output, "<ul>\n<li>Header</li>\n</ul><h1>Header</h1>", 'propagate');


#--- 2. propagateFile ---------------------------------------------------------

$tocInsertor->insertIntoFile($toc, $filename, {'output' => \$output});
eq_or_diff($output, "<ul>\n<li>Header</li>\n</ul><h1>Header</h1>\n", 'propagateFile');


#--- 3. doLinkToToken -----------------------------------------------------

$toc->setOptions({'doLinkToToken' => 1});
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
eq_or_diff("$output\n", <<'EOT', 'doLinkToToken');
<ul>
<li><a href="#h-1">Header</a></li>
</ul><h1><a name="h-1"></a>Header</h1>
EOT


#--- 4. templateAnchorHrefBegin -----------------------------------------------

$toc->setOptions(
	{'templateAnchorHrefBegin' => '"<$node${file}test${groupId}>"'}
);
$tocInsertor->insertIntoFile($toc, $filename, {'output' => \$output});
eq_or_diff(
    $output,
    "<ul>\n<li><1${filename}testh>Header</a></li>\n</ul><h1><a name=\"h-1\"></a>Header</h1>\n",
    'templateAnchorHrefBegin'
);
$toc->setOptions({'templateAnchorHrefBegin' => undef});


#--- 5. templateAnchorNameBegin -----------------------------------------------

$toc->setOptions({
	'templateAnchorName'      => '"$node$groupId"',
	'templateAnchorNameBegin' => '"<$anchorName>"'
});
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
eq_or_diff(
    $output,
    "<ul>\n<li><a href=\"#1h\">Header</a></li>\n</ul><h1><1h>Header</h1>",
    'templateAnchorNameBegin'
);
$toc->setOptions({'templateAnchorName' => undef});


#--- 6. templateAnchorName function -------------------------------------------

sub AssembleAnchorName {
		# Get arguments
	my ($aFile, $aGroupId, $aLevel, $aNode, $aText, $aChildren) = @_;
		# Return value
	return $aFile . $aGroupId . $aLevel . $aNode;
}  # AssembleAnchorName()

	# Set options
$toc->setOptions({'templateAnchorNameBegin' => \&AssembleAnchorName});
	# Propagate ToC
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
	# Test ToC
eq_or_diff(
    $output,
    "<ul>\n<li><a href=\"#h-1\">Header</a></li>\n</ul><h1>h11Header</h1>",
    'templateAnchorName'
);
	# Restore options
$toc->setOptions({'templateAnchorNameBegin' => undef});


#--- 7. doNumberToken --------------------------------------------------------

	# Set options
$toc->setOptions({'doNumberToken' => 1});
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
eq_or_diff("$output\n", <<HTML, 'doNumberToken');
<ul>
<li><a href="#h-1">Header</a></li>
</ul><h1><a name="h-1"></a>1 &nbsp;Header</h1>
HTML
	# Reset options
$toc->setOptions({
	'templateTokenNumber' => undef,
	'doNumberToken'      => 0
});


#--- 8. templateTokenNumber ---------------------------------------------------

	# Set options
$toc->setOptions({
	'templateTokenNumber' => '"-$node-"',
	'doNumberToken'      => 1
});
	# Propagate ToC
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
	# Test ToC
eq_or_diff("$output\n", <<'EOT', 'templateTokenNumber');
<ul>
<li><a href="#h-1">Header</a></li>
</ul><h1><a name="h-1"></a>-1-Header</h1>
EOT
	# Reset options
$toc->setOptions({
	'doNumberToken'      => 0,
	'templateTokenNumber' => undef
});


#--- 9. numberingStyle --------------------------------------------------------

	# Set options
$toc->setOptions({
	'doNumberToken' => 1,
	'tokenToToc' => [{
		'level' => 1,
		'tokenBegin' => '<h1>',
		'numberingStyle' => 'lower-alpha'
	}]
});
	# Propagate ToC
$tocInsertor->insert($toc, "<h1>Header</h1>", {'output' => \$output});
	# Test ToC
eq_or_diff("$output\n", <<'EOT', 'numberingStyle');
<ul>
<li><a href="#h-a">Header</a></li>
</ul><h1><a name="h-a"></a>a &nbsp;Header</h1>
EOT
	# Reset options
$toc->setOptions({
	'doNumberToken' => 0,
	'tokenToToc' => undef,
});


#--- 10. declaration pass through ---------------------------------------------

$tocInsertor->insert($toc, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"><h1>Header</h1>', {'output' => \$output});
	# Test ToC
eq_or_diff(
    $output,
    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"><h1>Header</h1>',
    'declaration pass through'
);
