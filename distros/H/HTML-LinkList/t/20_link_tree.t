# testing link_tree
use strict;
use Test::More tests => 6;

use HTML::LinkList qw(link_tree);

my @links = (
'/foo/bar/baz.html',
'/fooish.html',
'/bringle/',
['/tray/nav.html',
'/tray/tea_tray.html'],
);

my %labels = (
'/tray/nav.html' => 'Navigation',
'/foo/bar/baz.html' => 'Bazzy',
);

my $link_html = '';
# default, no current
$link_html = link_tree(labels=>\%labels,
    link_tree=>\@links);
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

# not-welformed list
@links = (
['#Askew'],
'#Big',
['#Lower'],
);

%labels = (
'#Askew' => 'Askew Header',
'#Big' => 'Big Header',
'#Lower' => 'Lower Section',
);

$link_html = link_tree(labels=>\%labels,
    link_tree=>\@links);
ok($link_html, "(2) not-wellformed; links HTML");

$ok_str = '<ul><li>
<ul><li><a href="#Askew">Askew Header</a></li>
</ul></li>
<li><a href="#Big">Big Header</a>
<ul><li><a href="#Lower">Lower Section</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(2) not-wellformed; values match");

#
# (3) more complicated (example from HTML::GenToc tests)
#
@links =
(
 [
 'tfiles/test5.php#Title-Archaeology701',
 'tfiles/test5.php#Title-Platinum',
 'tfiles/test5.php#Title-RoutineTrafficStop'
 ],
 'tfiles/test5.php#Series-FauxPawsProductions',
 [
 'tfiles/test5.php#Title-WindShiftFPP-506'
 ]
 );

%labels =
(
 'tfiles/test5.php#Title-Archaeology701' => 'Archaeology 701 (Sentinel)',
 'tfiles/test5.php#Title-Platinum' => 'Platinum (Sentinel)',
 'tfiles/test5.php#Title-RoutineTrafficStop' => 'Routine Traffic Stop (Sentinel/ER)',
 'tfiles/test5.php#Title-WindShiftFPP-506' => '(520) Wind Shift (FPP-506) (Sentinel)',
 'tfiles/test5.php#Series-FauxPawsProductions' => 'Faux Paws Productions'
 );

my %formats =
(
 '0' => {
 'tree_head' => '<ol>',
 'tree_foot' => "\n</ol>",
 },
 '1' => {
 'tree_head' => '<ul>',
 'tree_foot' => "\n</ul>"
 },

);

$link_html = link_tree(labels=>\%labels,
    link_tree=>\@links,
    formats=>\%formats);
ok($link_html, "(3) not-wellformed; links HTML");

$ok_str = '<ol><li>
<ul><li><a href="tfiles/test5.php#Title-Archaeology701">Archaeology 701 (Sentinel)</a></li>
<li><a href="tfiles/test5.php#Title-Platinum">Platinum (Sentinel)</a></li>
<li><a href="tfiles/test5.php#Title-RoutineTrafficStop">Routine Traffic Stop (Sentinel/ER)</a></li>
</ul></li>
<li><a href="tfiles/test5.php#Series-FauxPawsProductions">Faux Paws Productions</a>
<ul><li><a href="tfiles/test5.php#Title-WindShiftFPP-506">(520) Wind Shift (FPP-506) (Sentinel)</a></li>
</ul></li>
</ol>';

is($link_html, $ok_str, "(3) not-wellformed; values match");

