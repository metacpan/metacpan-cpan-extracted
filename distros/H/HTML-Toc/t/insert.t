#--- insert.t -----------------------------------------------------------------
# function: Test ToC insertion.

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
	'levelIndent'       => 0,
	'header'            => "",
	'footer'            => "",
});


BEGIN {
		# Create test file
	$filename = "file$$.htm";
	die "$filename is already there" if -e $filename;
	open(FILE, ">$filename") || die "Can't create $filename: $!";
	print FILE <<'HTML'; close(FILE);
<h1>Header</h1>
HTML
}


END {
		# Remove test file
	unlink($filename) or warn "Can't unlink $filename: $!";
}


#--- 1. insert before start ---------------------------------------------------

$toc->setOptions({'insertionPoint' => 'before <h1>'});
	# Generate ToC
$tocGenerator->generate($toc, "<h1>Header</h1>");
$tocInsertor->insert($toc, "<h1>Header</h1>", {
	'output'        => \$output,
	'doGenerateToc' => 0
});
	# Test ToC
eq_or_diff($output, "<ul>\n<li>Header</li>\n</ul><h1>Header</h1>", 'insert before start');


#--- 2. insert after start ----------------------------------------------------

$toc->setOptions({'insertionPoint' => 'after <h1>'});
	# Generate ToC
$tocGenerator->generate($toc, "<h1>Header</h1>");
$tocInsertor->insert($toc, "<h1>Header</h1>", {
	'output' => \$output,
	'doGenerateToc' => 0
});
	# Test ToC
eq_or_diff($output, "<h1><ul>\n<li>Header</li>\n</ul>Header</h1>", 'insert after start');


#--- 3. insert before end -----------------------------------------------------

$toc->setOptions({'insertionPoint' => 'before </h1>'});
	# Generate ToC
$tocGenerator->generate($toc, "<h1>Header</h1>");
$tocInsertor->insert($toc, "<h1>Header</h1>", {
	'output' => \$output,
	'doGenerateToc' => 0
});
	# Test ToC
eq_or_diff($output, "<h1>Header<ul>\n<li>Header</li>\n</ul></h1>", 'insert before end');


#--- 4. insert after end ------------------------------------------------------

$toc->setOptions({'insertionPoint' => 'after </h1>'});
	# Generate ToC
$tocGenerator->generate($toc, "<h1>Header</h1>");
$tocInsertor->insert($toc, "<h1>Header</h1>", {
	'output' => \$output,
	'doGenerateToc' => 0
});
	# Test ToC
eq_or_diff($output, "<h1>Header</h1><ul>\n<li>Header</li>\n</ul>", 'insert after end');


#--- 5. outputFile ------------------------------------------------------------

$toc->setOptions({'insertionPoint' => 'before <h1>'});
	# Generate ToC
$tocGenerator->generate($toc, "<h1>Header</h1>");
	# Insert ToC, output to file
$tocInsertor->insert($toc, "<h1>Header</h1>", {
	'outputFile' => $filename,
	'doGenerateToc' => 0
});
	# Read outputfile
open(FILE, "<$filename") || die "Can't open $filename: $!";
$content = join('', <FILE>);
close(FILE);
	# Test ToC
eq_or_diff($output, "<ul>\n<li>Header</li>\n</ul><h1>Header</h1>", 'outputFile');


#--- 6. empty toc -------------------------------------------------------------

$tocGenerator->generate($toc, "");
$tocInsertor->insert($toc, "", {
	'output' => \$output,
	'doGenerateToc' => 0
});
eq_or_diff($output, "", 'empty toc');


#--- TestAfterDeclaration() ---------------------------------------------------
# function: Test putting HTML comment after declaration.

sub TestAfterDeclaration {
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	my $output;

		# Set ToC options
   $toc->setOptions({
		'insertionPoint' => "after <!--ToC-->"
   });
		# Generate ToC
	$tocInsertor->insert($toc, <<HTML, {'output' => \$output});
<!--ToC-->
<body>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
</body>
HTML
	open(FILE, ">a.out") || die "Can't create a.out: $!";
	print FILE $output;
	close(FILE);
		# Test ToC
	eq_or_diff($output, <<HTML, 'Test putting HTML comment after declaration.', {max_width => 120});
<!--ToC-->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#h-1">Appendix</a>
      <ul>
         <li><a href="#h-1.1">Appendix Paragraph</a></li>
      </ul>
   </li>
   <li><a href="#h-2">Appendix</a>
      <ul>
         <li><a href="#h-2.1">Appendix Paragraph</a></li>
      </ul>
   </li>
</ul>
<!-- End of generated Table of Contents -->

<body>
   <h1><a name="h-1"></a>Appendix</h1>
   <h2><a name="h-1.1"></a>Appendix Paragraph</h2>
   <h1><a name="h-2"></a>Appendix</h1>
   <h2><a name="h-2.1"></a>Appendix Paragraph</h2>
</body>
HTML
}  # TestAfterDeclaration()


#--- TestNumberingStyle() -----------------------------------------------------
# function: Test numberingstyle.

sub TestNumberingStyle {
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	my $output;

		# Set ToC options
   $toc->setOptions({
		'numberingStyle'            => 'lower-alpha',
		'doNumberToken'             => 1,
		'tokenToToc' => [{
            'tokenBegin'          => '<h1>',
			}, {
            'tokenBegin' 			 => '<h2>',
            'level'      			 => 2,
				'numberingStyle'      => 'upper-alpha'
			}, {
            'tokenBegin' 			 => '<h3>',
            'level'      			 => 3,
				'numberingStyle'      => 'decimal'
         }]
   });
		# Generate ToC
	$tocInsertor->insert($toc, <<HTML, {'output' => \$output});
<body>
   <h1>Chapter</h1>
   <h2>Paragraph</h2>
   <h3>Paragraph</h3>
   <h3>Paragraph</h3>
   <h3>Paragraph</h3>
</body>
HTML
		# Test ToC
	eq_or_diff($output, <<HTML, 'Test numberingstyle', {max_width => 102});
<body>
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#h-a">Chapter</a>
      <ul>
         <li><a href="#h-a.A">Paragraph</a>
            <ul>
               <li><a href="#h-a.A.1">Paragraph</a></li>
               <li><a href="#h-a.A.2">Paragraph</a></li>
               <li><a href="#h-a.A.3">Paragraph</a></li>
            </ul>
         </li>
      </ul>
   </li>
</ul>
<!-- End of generated Table of Contents -->

   <h1><a name="h-a"></a>a &nbsp;Chapter</h1>
   <h2><a name="h-a.A"></a>a.A &nbsp;Paragraph</h2>
   <h3><a name="h-a.A.1"></a>a.A.1 &nbsp;Paragraph</h3>
   <h3><a name="h-a.A.2"></a>a.A.2 &nbsp;Paragraph</h3>
   <h3><a name="h-a.A.3"></a>a.A.3 &nbsp;Paragraph</h3>
</body>
HTML
}  # TestNumberingStyle()


#--- TestReplaceComment() -----------------------------------------------------
# function: Test replacing HTML comment with ToC.

sub TestReplaceComment {
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	my $output;

		# Set ToC options
   $toc->setOptions({
		'insertionPoint' => "replace <!-- ToC -->"
   });
		# Generate ToC
	$tocInsertor->insert($toc, <<HTML, {'output' => \$output});
<!-- ToC -->
<body>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
</body>
HTML
		# Test ToC
	eq_or_diff($output, <<HTML, 'Test replacing HTML comment with ToC', {max_width => 120});

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#h-1">Appendix</a>
      <ul>
         <li><a href="#h-1.1">Appendix Paragraph</a></li>
      </ul>
   </li>
   <li><a href="#h-2">Appendix</a>
      <ul>
         <li><a href="#h-2.1">Appendix Paragraph</a></li>
      </ul>
   </li>
</ul>
<!-- End of generated Table of Contents -->

<body>
   <h1><a name="h-1"></a>Appendix</h1>
   <h2><a name="h-1.1"></a>Appendix Paragraph</h2>
   <h1><a name="h-2"></a>Appendix</h1>
   <h2><a name="h-2.1"></a>Appendix Paragraph</h2>
</body>
HTML
}  # TestReplaceComment()


#--- TestReplaceText() -----------------------------------------------------
# function: Test replacing text with ToC.

sub TestReplaceText {
		# Create objects
	my $toc         = HTML::Toc->new();
	my $tocInsertor = HTML::TocInsertor->new();
	my $output;

		# Set ToC options
   $toc->setOptions({
		'insertionPoint' => "replace ToC will be placed here[,]"
   });
		# Generate ToC
	$tocInsertor->insert($toc, <<HTML, {'output' => \$output});
The ToC will be placed here, overnight.
<body>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
   <h1>Appendix</h1>
   <h2>Appendix Paragraph</h2>
</body>
HTML
		# Test ToC
	eq_or_diff($output, <<HTML, 'Test replacing text with ToC', {max_width => 120});
The 
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul>
   <li><a href="#h-1">Appendix</a>
      <ul>
         <li><a href="#h-1.1">Appendix Paragraph</a></li>
      </ul>
   </li>
   <li><a href="#h-2">Appendix</a>
      <ul>
         <li><a href="#h-2.1">Appendix Paragraph</a></li>
      </ul>
   </li>
</ul>
<!-- End of generated Table of Contents -->
 overnight.
<body>
   <h1><a name="h-1"></a>Appendix</h1>
   <h2><a name="h-1.1"></a>Appendix Paragraph</h2>
   <h1><a name="h-2"></a>Appendix</h1>
   <h2><a name="h-2.1"></a>Appendix Paragraph</h2>
</body>
HTML
}  # TestReplaceText()


	# 7.  Test 'numberingStyle'
TestNumberingStyle();
	# 8.  Test replace comment
TestReplaceComment();
	# 9.  Test after declaration
TestAfterDeclaration();
	# 10.  Test replace text
TestReplaceText();
