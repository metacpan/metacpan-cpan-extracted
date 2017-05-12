#--- manual.t -----------------------------------------------------------------
# function: Test HTML::ToC generating a manual.

use strict;
use Test::More tests => 3;
use Test::Differences;

use HTML::Toc;
use HTML::TocGenerator;
use HTML::TocInsertor;
use HTML::TocUpdator;


#--- AssembleTocLine() --------------------------------------------------------
# function: Assemble ToC line.

sub AssembleTocLine {
                # Get arguments
        my ($aLevel, $aGroupId, $aNode, $aSequenceNr, $aText) = @_;
                # Local variables
        my ($result);

                # Assemble ToC line
        SWITCH: {
                if ($aGroupId eq "prelude") {
                        $result = "<li>$aText";
                        last SWITCH;
                }
                if ($aGroupId eq "part") {
                        $result = "<li>Part $aNode &nbsp;$aText";
                        last SWITCH;
                }
                if ($aGroupId eq "h") {
                        $result = "<li>$aSequenceNr. &nbsp;$aText";
                        last SWITCH;
                }
                else {
                        $result = "<li>$aNode &nbsp;$aText";
                        last SWITCH;
                }
        }

                # Return value
        return $result;
}  # AssembleTocLine()


#--- AssembleTokenNumber() ----------------------------------------------------
# function: Assemble token number.

sub AssembleTokenNumber {
                # Get arguments
        my ($aNode, $aGroupId, $aFile, $aGroupLevel, $aLevel, $aToc) = @_;
                # Local variables
        my ($result);
                # Assemble token number
        SWITCH: {
                if ($aGroupId eq "part") {
                        $result = "Part $aNode &nbsp;";
                        last SWITCH;
                }
                else {
                        $result = "$aNode &nbsp;";
                        last SWITCH;
                }
        }
                # Return value
        return $result;
}  # AssembleTokenNumber()


#--- TestInsertManualToc ------------------------------------------------------
# function: Test inserting ToC into manual.

sub TestInsertManualToc {
        my $output;
                # Create objects
        my $toc          = new HTML::Toc;
        my $tocOfFigures = new HTML::Toc;
        my $tocOfTables  = new HTML::Toc;
        my $tocInsertor  = new HTML::TocInsertor;

                # Set ToC options
        $toc->setOptions({
                'doNestGroup'          => 1,
                'doNumberToken'        => 1,
                'insertionPoint'       => "replace <!-- Table of Contents -->",
                'templateLevel'        => \&AssembleTocLine,
      'templateLevelBegin'   => '"<ul class=\"toc_$groupId$level\">\n"',
      'templateLevelEnd'     => '"</ul>\n"',
                'templateTokenNumber'  => \&AssembleTokenNumber,
      'tokenToToc'           => [{
            'groupId'        => 'part',
                           'doNumberToken'  => 1,
            'level'          => 1,
            'tokenBegin'     => '<h1 class="part">',
         }, {
            'tokenBegin'     => '<h1 class="-[appendix|prelude|hidden|part]">'
         }, {
            'tokenBegin'     => '<h2>',
            'level'          => 2
         }, {
            'tokenBegin'     => '<h3>',
            'level'          => 3
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h1 class="appendix">',
                           'numberingStyle' => 'upper-alpha',
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h2 class="appendix">',
            'level'          => 2
         }, {
            'groupId'        => 'prelude',
            'tokenBegin'     => '<h1 class="prelude">',
            'level'          => 1,
                           'doNumberToken'  => 0,
         }],
        });
        $tocOfFigures->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "replace <!-- Table of Figures -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Figure $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Figure',
                                'tokenBegin'     => '<p class="captionFigure">'
                        }]
        });
        $tocOfTables->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "replace <!-- Table of Tables -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Table $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Table',
                                'tokenBegin'     => '<p class="captionTable">'
                        }]
        });
                # Insert ToC
        $tocInsertor->insertIntoFile(
                [$toc, $tocOfFigures, $tocOfTables],
                't/ManualTest/manualTest1.htm', {
                         'doUseGroupsGlobal' => 1,
                         'output'            => \$output,
                         'outputFile'        => 't/ManualTest/manualTest2.htm'
                }
        );
        eq_or_diff($output, <<HTML, 'Test inserting ToC into manual', {max_width => 120});
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
   <title>Manual</title>
    <style type="text/css">
       ul.toc_appendix1 {
         list-style-type: none;
         margin-left: 0;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h2 {
         list-style-type: none;
       }
       ul.toc_h3 {
         list-style-type: none;
       }
       ul.toc_part1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_prelude1 {
         list-style: none;
       }
       p.captionFigure {
         font-style: italic;
         font-weight: bold;
       }
       p.captionTable {
         font-style: italic;
         font-weight: bold;
       }
    </style>
</head>
<body>

<h1 class="prelude"><a name="prelude-1"></a>Preface</h1>
<p>Better C than never.</p>

<h1 class="hidden">Table of Contents</h1>

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul class="toc_prelude1">
   <li><a href="#prelude-1">Preface</a></li>
   <li><a href="#prelude-2">Table of Figures</a></li>
   <li><a href="#prelude-3">Table of Tables</a></li>
   <li><a href="#prelude-4">Introduction</a>
      <ul class="toc_part1">
         <li>Part 1 &nbsp;<a href="#part-1">Disks</a>
            <ul class="toc_h1">
               <li>1. &nbsp;<a href="#h-1">Compiler Disk v1</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-1.1">System</a></li>
                     <li>2. &nbsp;<a href="#h-1.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>2. &nbsp;<a href="#h-2">Compiler Disk v2</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-2.1">System</a>
                        <ul class="toc_h3">
                           <li>1. &nbsp;<a href="#h-2.1.1">parser.com</a></li>
                           <li>2. &nbsp;<a href="#h-2.1.2">compiler.com</a></li>
                           <li>3. &nbsp;<a href="#h-2.1.3">linker.com</a></li>
                        </ul>
                     </li>
                     <li>2. &nbsp;<a href="#h-2.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>3. &nbsp;<a href="#h-3">Library System Disk</a></li>
            </ul>
         </li>
         <li>Part 2 &nbsp;<a href="#part-2">Personal</a>
            <ul class="toc_h1">
               <li>4. &nbsp;<a href="#h-4">Tips &amp; Tricks</a></li>
            </ul>
         </li>
         <li>Part 3 &nbsp;<a href="#part-3">Appendixes</a>
            <ul class="toc_appendix1">
               <li>A &nbsp;<a href="#appendix-A">Functions Standard Library v1</a></li>
               <li>B &nbsp;<a href="#appendix-B">Functions Standard Library v2</a></li>
               <li>C &nbsp;<a href="#appendix-C">Functions Graphic Library</a></li>
            </ul>
         </li>
      </ul>
   </li>
   <li><a href="#prelude-5">Bibliography</a></li>
</ul>
<!-- End of generated Table of Contents -->


<h1 class="prelude"><a name="prelude-2"></a>Table of Figures</h1>

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Figure-1">Contents Compiler Disk v1</a></li>
   <li><a href="#Figure-2">Contents Compiler Disk v2</a></li>
</ol>
<!-- End of generated Table of Contents -->


<h1 class="prelude"><a name="prelude-3"></a>Table of Tables</h1>

<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Table-1">Compile Steps</a></li>
</ol>
<!-- End of generated Table of Contents -->


<h1 class="prelude"><a name="prelude-4"></a>Introduction</h1>
<p>Thanks to standardisation and the excellent work of the QWERTY corporation it is possible to learn C with almost any C manual.</p>
<p class="captionTable"><a name="Table-1"></a>Table 1: &nbsp;Compile Steps</p>
<pre>
   Parser
   Compiler
   Linker
</pre>

<h1 class="part"><a name="part-1"></a>Part 1 &nbsp;Disks</h1>
<h1><a name="h-1"></a>1 &nbsp;Compiler Disk v1</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v1"/></p>
<p class="captionFigure"><a name="Figure-1"></a>Figure 1: &nbsp;Contents Compiler Disk v1</p>

<h2><a name="h-1.1"></a>1.1 &nbsp;System</h2>
<h2><a name="h-1.2"></a>1.2 &nbsp;Standard Library</h2>

<h1><a name="h-2"></a>2 &nbsp;Compiler Disk v2</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v2"/></p>
<p class="captionFigure"><a name="Figure-2"></a>Figure 2: &nbsp;Contents Compiler Disk v2</p>

<h2><a name="h-2.1"></a>2.1 &nbsp;System</h2>
<h3><a name="h-2.1.1"></a>2.1.1 &nbsp;parser.com</h3>
<h3><a name="h-2.1.2"></a>2.1.2 &nbsp;compiler.com</h3>
<h3><a name="h-2.1.3"></a>2.1.3 &nbsp;linker.com</h3>
<h2><a name="h-2.2"></a>2.2 &nbsp;Standard Library</h2>

<h1><a name="h-3"></a>3 &nbsp;Library System Disk</h1>
<h1 class="part"><a name="part-2"></a>Part 2 &nbsp;Personal</h1>
<h1><a name="h-4"></a>4 &nbsp;Tips &amp; Tricks</h1>
<h1 class="part"><a name="part-3"></a>Part 3 &nbsp;Appendixes</h1>
<h1 class="appendix"><a name="appendix-A"></a>A &nbsp;Functions Standard Library v1</h1>
<h1 class="appendix"><a name="appendix-B"></a>B &nbsp;Functions Standard Library v2</h1>
<h1 class="appendix"><a name="appendix-C"></a>C &nbsp;Functions Graphic Library</h1>
<h1 class="prelude"><a name="prelude-5"></a>Bibliography</h1>
</body>
</html>
HTML
}  # TestInsertManualToc()


#--- TestInsertManualForUpdating() --------------------------------------------
# function: Test inserting ToC into manual.

sub TestInsertManualForUpdating {
        my $output;
                # Create objects
        my $toc          = new HTML::Toc;
        my $tocOfFigures = new HTML::Toc;
        my $tocOfTables  = new HTML::Toc;
        my $tocUpdator   = new HTML::TocUpdator;

                # Set ToC options
        $toc->setOptions({
                'doNestGroup'          => 1,
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Contents -->",
                'templateLevel'        => \&AssembleTocLine,
      'templateLevelBegin'   => '"<ul class=\"toc_$groupId$level\">\n"',
      'templateLevelEnd'     => '"</ul>\n"',
                'templateTokenNumber'  => \&AssembleTokenNumber,
      'tokenToToc'           => [{
            'groupId'        => 'part',
                           'doNumberToken'  => 1,
            'level'          => 1,
            'tokenBegin'     => '<h1 class="part">',
         }, {
            'tokenBegin'     => '<h1 class="-[appendix|prelude|hidden|part]">'
         }, {
            'tokenBegin'     => '<h2>',
            'level'          => 2
         }, {
            'tokenBegin'     => '<h3>',
            'level'          => 3
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h1 class="appendix">',
                           'numberingStyle' => 'upper-alpha',
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h2 class="appendix">',
            'level'          => 2
         }, {
            'groupId'        => 'prelude',
            'tokenBegin'     => '<h1 class="prelude">',
            'level'          => 1,
                           'doNumberToken'  => 0,
         }],
        });
        $tocOfFigures->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Figures -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Figure $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Figure',
                                'tokenBegin'     => '<p class="captionFigure">'
                        }]
        });
        $tocOfTables->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Tables -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Table $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Table',
                                'tokenBegin'     => '<p class="captionTable">'
                        }]
        });
                # Insert ToC
        $tocUpdator->updateFile(
                [$toc, $tocOfFigures, $tocOfTables],
                't/ManualTest/manualTest1.htm', {
                         'doUseGroupsGlobal' => 1,
                         'output'            => \$output,
                         'outputFile'        => 't/ManualTest/manualTest3.htm'
                }
        );
        eq_or_diff($output, <<HTML, 'Test inserting ToC into manual', {max_width => 120});
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
   <title>Manual</title>
    <style type="text/css">
       ul.toc_appendix1 {
         list-style-type: none;
         margin-left: 0;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h2 {
         list-style-type: none;
       }
       ul.toc_h3 {
         list-style-type: none;
       }
       ul.toc_part1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_prelude1 {
         list-style: none;
       }
       p.captionFigure {
         font-style: italic;
         font-weight: bold;
       }
       p.captionTable {
         font-style: italic;
         font-weight: bold;
       }
    </style>
</head>
<body>

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-1"></a><!-- #EndTocAnchorNameBegin -->Preface</h1>
<p>Better C than never.</p>

<h1 class="hidden">Table of Contents</h1>
<!-- Table of Contents --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul class="toc_prelude1">
   <li><a href="#prelude-1">Preface</a></li>
   <li><a href="#prelude-2">Table of Figures</a></li>
   <li><a href="#prelude-3">Table of Tables</a></li>
   <li><a href="#prelude-4">Introduction</a>
      <ul class="toc_part1">
         <li>Part 1 &nbsp;<a href="#part-1">Disks</a>
            <ul class="toc_h1">
               <li>1. &nbsp;<a href="#h-1">Compiler Disk v1</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-1.1">System</a></li>
                     <li>2. &nbsp;<a href="#h-1.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>2. &nbsp;<a href="#h-2">Compiler Disk v2</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-2.1">System</a>
                        <ul class="toc_h3">
                           <li>1. &nbsp;<a href="#h-2.1.1">parser.com</a></li>
                           <li>2. &nbsp;<a href="#h-2.1.2">compiler.com</a></li>
                           <li>3. &nbsp;<a href="#h-2.1.3">linker.com</a></li>
                        </ul>
                     </li>
                     <li>2. &nbsp;<a href="#h-2.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>3. &nbsp;<a href="#h-3">Library System Disk</a></li>
            </ul>
         </li>
         <li>Part 2 &nbsp;<a href="#part-2">Personal</a>
            <ul class="toc_h1">
               <li>4. &nbsp;<a href="#h-4">Tips &amp; Tricks</a></li>
            </ul>
         </li>
         <li>Part 3 &nbsp;<a href="#part-3">Appendixes</a>
            <ul class="toc_appendix1">
               <li>A &nbsp;<a href="#appendix-A">Functions Standard Library v1</a></li>
               <li>B &nbsp;<a href="#appendix-B">Functions Standard Library v2</a></li>
               <li>C &nbsp;<a href="#appendix-C">Functions Graphic Library</a></li>
            </ul>
         </li>
      </ul>
   </li>
   <li><a href="#prelude-5">Bibliography</a></li>
</ul>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-2"></a><!-- #EndTocAnchorNameBegin -->Table of Figures</h1>
<!-- Table of Figures --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Figure-1">Contents Compiler Disk v1</a></li>
   <li><a href="#Figure-2">Contents Compiler Disk v2</a></li>
</ol>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-3"></a><!-- #EndTocAnchorNameBegin -->Table of Tables</h1>
<!-- Table of Tables --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Table-1">Compile Steps</a></li>
</ol>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-4"></a><!-- #EndTocAnchorNameBegin -->Introduction</h1>
<p>Thanks to standardisation and the excellent work of the QWERTY corporation it is possible to learn C with almost any C manual.</p>
<p class="captionTable"><!-- #BeginTocAnchorNameBegin --><a name="Table-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Table 1: &nbsp;<!-- #EndTocNumber -->Compile Steps</p>
<pre>
   Parser
   Compiler
   Linker
</pre>

<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 1 &nbsp;<!-- #EndTocNumber -->Disks</h1>
<h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Compiler Disk v1</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v1"/></p>
<p class="captionFigure"><!-- #BeginTocAnchorNameBegin --><a name="Figure-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Figure 1: &nbsp;<!-- #EndTocNumber -->Contents Compiler Disk v1</p>

<h2><!-- #BeginTocAnchorNameBegin --><a name="h-1.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1.1 &nbsp;<!-- #EndTocNumber -->System</h2>
<h2><!-- #BeginTocAnchorNameBegin --><a name="h-1.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1.2 &nbsp;<!-- #EndTocNumber -->Standard Library</h2>

<h1><!-- #BeginTocAnchorNameBegin --><a name="h-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2 &nbsp;<!-- #EndTocNumber -->Compiler Disk v2</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v2"/></p>
<p class="captionFigure"><!-- #BeginTocAnchorNameBegin --><a name="Figure-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Figure 2: &nbsp;<!-- #EndTocNumber -->Contents Compiler Disk v2</p>

<h2><!-- #BeginTocAnchorNameBegin --><a name="h-2.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1 &nbsp;<!-- #EndTocNumber -->System</h2>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.1 &nbsp;<!-- #EndTocNumber -->parser.com</h3>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.2 &nbsp;<!-- #EndTocNumber -->compiler.com</h3>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.3 &nbsp;<!-- #EndTocNumber -->linker.com</h3>
<h2><!-- #BeginTocAnchorNameBegin --><a name="h-2.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.2 &nbsp;<!-- #EndTocNumber -->Standard Library</h2>

<h1><!-- #BeginTocAnchorNameBegin --><a name="h-3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->3 &nbsp;<!-- #EndTocNumber -->Library System Disk</h1>
<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 2 &nbsp;<!-- #EndTocNumber -->Personal</h1>
<h1><!-- #BeginTocAnchorNameBegin --><a name="h-4"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->4 &nbsp;<!-- #EndTocNumber -->Tips &amp; Tricks</h1>
<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 3 &nbsp;<!-- #EndTocNumber -->Appendixes</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-A"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->A &nbsp;<!-- #EndTocNumber -->Functions Standard Library v1</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-B"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->B &nbsp;<!-- #EndTocNumber -->Functions Standard Library v2</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-C"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->C &nbsp;<!-- #EndTocNumber -->Functions Graphic Library</h1>
<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-5"></a><!-- #EndTocAnchorNameBegin -->Bibliography</h1>
</body>
</html>
HTML
}  # TestInsertManualForUpdating()


#--- TestUpdateManual() -------------------------------------------------------
# function: Test inserting ToC into manual.

sub TestUpdateManual {
        my $output;
                # Create objects
        my $toc          = new HTML::Toc;
        my $tocOfFigures = new HTML::Toc;
        my $tocOfTables  = new HTML::Toc;
        my $tocUpdator   = new HTML::TocUpdator;

                # Set ToC options
        $toc->setOptions({
                'doNestGroup'          => 1,
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Contents -->",
                'templateLevel'        => \&AssembleTocLine,
      'templateLevelBegin'   => '"<ul class=\"toc_$groupId$level\">\n"',
      'templateLevelEnd'     => '"</ul>\n"',
                'templateTokenNumber'  => \&AssembleTokenNumber,
      'tokenToToc'           => [{
            'groupId'        => 'part',
                           'doNumberToken'  => 1,
            'level'          => 1,
            'tokenBegin'     => '<h1 class="part">',
         }, {
            'tokenBegin'     => '<h1 class=-[appendix|prelude|hidden|part]>'
         }, {
            'tokenBegin'     => '<h2>',
            'level'          => 2
         }, {
            'tokenBegin'     => '<h3>',
            'level'          => 3
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h1 class="appendix">',
                           'numberingStyle' => 'upper-alpha',
         }, {
            'groupId'        => 'appendix',
            'tokenBegin'     => '<h2 class="appendix">',
            'level'          => 2
         }, {
            'groupId'        => 'prelude',
            'tokenBegin'     => '<h1 class="prelude">',
            'level'          => 1,
                           'doNumberToken'  => 0,
         }],
        });
        $tocOfFigures->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Figures -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Figure $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Figure',
                                'tokenBegin'     => '<p class="captionFigure">'
                        }]
        });
        $tocOfTables->setOptions({
                'doNumberToken'        => 1,
                'insertionPoint'       => "after <!-- Table of Tables -->",
                'templateLevelBegin'   => '"<ol>\n"',
                'templateLevelEnd'     => '"</ol>\n"',
                'templateTokenNumber'  => '"Table $node: &nbsp;"',
                'tokenToToc'           => [{
                                'groupId'        => 'Table',
                                'tokenBegin'     => '<p class="captionTable">'
                        }]
        });
                # Insert ToC
        $tocUpdator->updateFile(
                [$toc, $tocOfFigures, $tocOfTables],
                't/ManualTest/manualTest3.htm', {
                         'doUseGroupsGlobal' => 1,
                         'output'            => \$output,
                         'outputFile'        => 't/ManualTest/manualTest4.htm'
                }
        );
        eq_or_diff($output, <<HTML, 'Test inserting ToC into manual', {max_width => 120});
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
   <title>Manual</title>
    <style type="text/css">
       ul.toc_appendix1 {
         list-style-type: none;
         margin-left: 0;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_h2 {
         list-style-type: none;
       }
       ul.toc_h3 {
         list-style-type: none;
       }
       ul.toc_part1 {
         list-style-type: none;
         margin-left: 1;
         margin-top: 1em;
         margin-bottom: 1em;
       }
       ul.toc_prelude1 {
         list-style: none;
       }
       p.captionFigure {
         font-style: italic;
         font-weight: bold;
       }
       p.captionTable {
         font-style: italic;
         font-weight: bold;
       }
    </style>
</head>
<body>

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-1"></a><!-- #EndTocAnchorNameBegin -->Preface</h1>
<p>Better C than never.</p>

<h1 class="hidden">Table of Contents</h1>
<!-- Table of Contents --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ul class="toc_prelude1">
   <li><a href="#prelude-1">Preface</a></li>
   <li><a href="#prelude-2">Table of Figures</a></li>
   <li><a href="#prelude-3">Table of Tables</a></li>
   <li><a href="#prelude-4">Introduction</a>
      <ul class="toc_part1">
         <li>Part 1 &nbsp;<a href="#part-1">Disks</a>
            <ul class="toc_h1">
               <li>1. &nbsp;<a href="#h-1">Compiler Disk v1</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-1.1">System</a></li>
                     <li>2. &nbsp;<a href="#h-1.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>2. &nbsp;<a href="#h-2">Compiler Disk v2</a>
                  <ul class="toc_h2">
                     <li>1. &nbsp;<a href="#h-2.1">System</a>
                        <ul class="toc_h3">
                           <li>1. &nbsp;<a href="#h-2.1.1">parser.com</a></li>
                           <li>2. &nbsp;<a href="#h-2.1.2">compiler.com</a></li>
                           <li>3. &nbsp;<a href="#h-2.1.3">linker.com</a></li>
                        </ul>
                     </li>
                     <li>2. &nbsp;<a href="#h-2.2">Standard Library</a></li>
                  </ul>
               </li>
               <li>3. &nbsp;<a href="#h-3">Library System Disk</a></li>
            </ul>
         </li>
         <li>Part 2 &nbsp;<a href="#part-2">Personal</a>
            <ul class="toc_h1">
               <li>4. &nbsp;<a href="#h-4">Tips &amp; Tricks</a></li>
            </ul>
         </li>
         <li>Part 3 &nbsp;<a href="#part-3">Appendixes</a>
            <ul class="toc_appendix1">
               <li>A &nbsp;<a href="#appendix-A">Functions Standard Library v1</a></li>
               <li>B &nbsp;<a href="#appendix-B">Functions Standard Library v2</a></li>
               <li>C &nbsp;<a href="#appendix-C">Functions Graphic Library</a></li>
            </ul>
         </li>
      </ul>
   </li>
   <li><a href="#prelude-5">Bibliography</a></li>
</ul>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-2"></a><!-- #EndTocAnchorNameBegin -->Table of Figures</h1>
<!-- Table of Figures --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Figure-1">Contents Compiler Disk v1</a></li>
   <li><a href="#Figure-2">Contents Compiler Disk v2</a></li>
</ol>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-3"></a><!-- #EndTocAnchorNameBegin -->Table of Tables</h1>
<!-- Table of Tables --><!-- #BeginToc -->
<!-- Table of Contents generated by Perl - HTML::Toc -->
<ol>
   <li><a href="#Table-1">Compile Steps</a></li>
</ol>
<!-- End of generated Table of Contents -->
<!-- #EndToc -->

<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-4"></a><!-- #EndTocAnchorNameBegin -->Introduction</h1>
<p>Thanks to standardisation and the excellent work of the QWERTY corporation it is possible to learn C with almost any C manual.</p>
<p class="captionTable"><!-- #BeginTocAnchorNameBegin --><a name="Table-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Table 1: &nbsp;<!-- #EndTocNumber -->Compile Steps</p>
<pre>
   Parser
   Compiler
   Linker
</pre>

<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 1 &nbsp;<!-- #EndTocNumber -->Disks</h1>
<h1><!-- #BeginTocAnchorNameBegin --><a name="h-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1 &nbsp;<!-- #EndTocNumber -->Compiler Disk v1</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v1"/></p>
<p class="captionFigure"><!-- #BeginTocAnchorNameBegin --><a name="Figure-1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Figure 1: &nbsp;<!-- #EndTocNumber -->Contents Compiler Disk v1</p>

<h2><!-- #BeginTocAnchorNameBegin --><a name="h-1.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1.1 &nbsp;<!-- #EndTocNumber -->System</h2>
<h2><!-- #BeginTocAnchorNameBegin --><a name="h-1.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->1.2 &nbsp;<!-- #EndTocNumber -->Standard Library</h2>

<h1><!-- #BeginTocAnchorNameBegin --><a name="h-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2 &nbsp;<!-- #EndTocNumber -->Compiler Disk v2</h1>
<p><img src="img.gif" alt="Contents Compiler Disk v2"/></p>
<p class="captionFigure"><!-- #BeginTocAnchorNameBegin --><a name="Figure-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Figure 2: &nbsp;<!-- #EndTocNumber -->Contents Compiler Disk v2</p>

<h2><!-- #BeginTocAnchorNameBegin --><a name="h-2.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1 &nbsp;<!-- #EndTocNumber -->System</h2>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.1"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.1 &nbsp;<!-- #EndTocNumber -->parser.com</h3>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.2 &nbsp;<!-- #EndTocNumber -->compiler.com</h3>
<h3><!-- #BeginTocAnchorNameBegin --><a name="h-2.1.3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.1.3 &nbsp;<!-- #EndTocNumber -->linker.com</h3>
<h2><!-- #BeginTocAnchorNameBegin --><a name="h-2.2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->2.2 &nbsp;<!-- #EndTocNumber -->Standard Library</h2>

<h1><!-- #BeginTocAnchorNameBegin --><a name="h-3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->3 &nbsp;<!-- #EndTocNumber -->Library System Disk</h1>
<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-2"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 2 &nbsp;<!-- #EndTocNumber -->Personal</h1>
<h1><!-- #BeginTocAnchorNameBegin --><a name="h-4"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->4 &nbsp;<!-- #EndTocNumber -->Tips &amp; Tricks</h1>
<h1 class="part"><!-- #BeginTocAnchorNameBegin --><a name="part-3"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->Part 3 &nbsp;<!-- #EndTocNumber -->Appendixes</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-A"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->A &nbsp;<!-- #EndTocNumber -->Functions Standard Library v1</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-B"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->B &nbsp;<!-- #EndTocNumber -->Functions Standard Library v2</h1>
<h1 class="appendix"><!-- #BeginTocAnchorNameBegin --><a name="appendix-C"></a><!-- #EndTocAnchorNameBegin --><!-- #BeginTocNumber -->C &nbsp;<!-- #EndTocNumber -->Functions Graphic Library</h1>
<h1 class="prelude"><!-- #BeginTocAnchorNameBegin --><a name="prelude-5"></a><!-- #EndTocAnchorNameBegin -->Bibliography</h1>
</body>
</html>
HTML
}  # TestUpdateManual()


        # Test inserting ToC into manual
TestInsertManualToc();
        # Test inserting ToC with update tokens into manual
TestInsertManualForUpdating();
       # Test updating ToC
TestUpdateManual();
