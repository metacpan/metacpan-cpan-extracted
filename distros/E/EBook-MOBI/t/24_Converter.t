#!/usr/bin/perl

use strict;
use warnings;

use utf8;

#######################
# TESTING starts here #
#######################
use Test::More tests => 21;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Converter';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################

my $mhtml;
my $expect;

# text
$mhtml = $obj->text('Boris Däppen');
$expect = "Boris D&auml;ppen";
is($mhtml, $expect, "text");

# title
$mhtml = $obj->title('Test Titel');
$expect = "<h1>Test Titel</h1>\n";
is($mhtml, $expect, "title");

$mhtml = $obj->title('Test Titel', 6);
$expect = "<h6>Test Titel</h6>\n";
is($mhtml, $expect, "title 6");

my $eval_run = 0;
eval {
    $obj->title('Test Titel', 7);
} or do {
    $eval_run = 1;
};
ok($eval_run, 'title 7');

# paragraph
$mhtml = $obj->paragraph("Ein Text.\nUnd das ist gut so.");
$expect = "<p>Ein Text.\nUnd das ist gut so.</p>\n";
is($mhtml, $expect, "paragraph");

# newline
$mhtml = $obj->newline();
$expect = "<br />\n";
is($mhtml, $expect, "newline");

# pagebreak
$mhtml = $obj->pagebreak();
$expect = "<mbp:pagebreak />\n";
is($mhtml, $expect, "pagebreak");

# italic
$mhtml = $obj->italic("Ein Text.\nUnd das ist gut so.");
$expect = "<i>Ein Text.\nUnd das ist gut so.</i>";
is($mhtml, $expect, "italic");

# bold
$mhtml = $obj->bold("Ein Text.\nUnd das ist gut so.");
$expect = "<b>Ein Text.\nUnd das ist gut so.</b>";
is($mhtml, $expect, "bold");

# code
$mhtml = $obj->code(
'for my $i (@a) {
    print $_;
    print "the end\n";
}
');
$expect = '<code>for&nbsp;my&nbsp;$i&nbsp;(@a)&nbsp;{<br />
&nbsp;&nbsp;&nbsp;&nbsp;print&nbsp;$_;<br />
&nbsp;&nbsp;&nbsp;&nbsp;print&nbsp;"the&nbsp;end\n";<br />
}<br />
</code>
';
is($mhtml, $expect, "code");

# small
$mhtml = $obj->small("Ein Text.\nUnd das ist gut so.");
$expect = "<small>Ein Text.\nUnd das ist gut so.</small>";
is($mhtml, $expect, "small");

# big
$mhtml = $obj->big("Ein Text.\nUnd das ist gut so.");
$expect = "<big>Ein Text.\nUnd das ist gut so.</big>";
is($mhtml, $expect, "big");

# emphasize
$mhtml = $obj->emphasize("Ein Text.\nUnd das ist gut so.");
$expect = "<em>Ein Text.\nUnd das ist gut so.</em>";
is($mhtml, $expect, "emphasize");

# list
$mhtml = $obj->list(['A', 'B', 'C', 'D']);
$expect = "<ul>\n<li>A</li>\n<li>B</li>\n<li>C</li>\n<li>D</li>\n</ul>\n";
is($mhtml, $expect, "list");

$mhtml = $obj->list(['A', 'B', 'C', 'D'], 'ol');
$expect = "<ol>\n<li>A</li>\n<li>B</li>\n<li>C</li>\n<li>D</li>\n</ol>\n";
is($mhtml, $expect, "list ol");

# table
$mhtml = $obj->table(   th =>   ['A', 'B', 'C'],
                        td => [
                                ['1', '2', '3'],
                                ['10', '20', '30'],
                                ['100', '200', '300']
                              ],
                   );
$expect = "<table>\n<tr><th>A</th><th>B</th><th>C</th></tr>\n<tr><td>1</td><td>2</td><td>3</td></tr>\n<tr><td>10</td><td>20</td><td>30</td></tr>\n<tr><td>100</td><td>200</td><td>300</td></tr>\n</table>\n";
is($mhtml, $expect, "table minimal");

$mhtml = $obj->table(   th =>   ['A', 'B', 'C'],
                        td => [
                                ['1', '2', '3'],
                                ['10', '20', '30'],
                                ['100', '200', '300']
                              ],
                        caption => 'This is a table',
                        border => '8',
                        cellspacing => '10',
                        cellpadding => '20'
                    );
$expect = "<table border=\"8\" cellspacing=\"10\" cellpadding=\"20\">\n<tr><th>A</th><th>B</th><th>C</th></tr>\n<tr><td>1</td><td>2</td><td>3</td></tr>\n<tr><td>10</td><td>20</td><td>30</td></tr>\n<tr><td>100</td><td>200</td><td>300</td></tr>\n<caption>This is a table</caption>\n</table>\n";
is($mhtml, $expect, "table full");

# image
$mhtml = $obj->image('/path/to/pic.jpg', 'This is a picture');
$expect = '<img src="/path/to/pic.jpg" recindex="1" >' . "\n<p>This is a picture</p>\n";
is($mhtml, $expect, "image");

$mhtml = $obj->image('/path/to/pic2.jpg', 'This is a second picture');
$expect = '<img src="/path/to/pic2.jpg" recindex="2" >' . "\n<p>This is a second picture</p>\n";
is($mhtml, $expect, "image 2");

