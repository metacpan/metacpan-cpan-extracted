#============================================================= -*-perl-*-
#
# t/acidtest.t
#
# Test script for the query() method.
#
# Written by Chelsea Rio/Kevin Kamel, September 24, 2010
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::TreeBuilder;
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 80,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $acidtest = $html_dir->file('acidtest.html')->must_exist;

my ($query, $tree);

#-----------------------------------------------------------------------
# load up second test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $acidtest->absolute );
ok( $tree, 'parsed tree for second test file: ' . $acidtest->name );
$query = Query $tree;
ok( $query, 'created query' );

#-----------------------------------------------------------------------
# look for some basic elements using duplicate tagnames in query
#-----------------------------------------------------------------------

my $test0 = $query->query('*');
ok( $test0, '*' );
is( $test0->size, 47, '*' ); #includes javascript and metas

my $test1 = $query->query('div#id-one');
ok( $test1, 'div#id-one' );
is( $test1->size, 1, 'div#id-one' );

my $test2 = $query->query('div#id-one h1[title]');
ok( $test2, 'div#id-one h1[title]' );
is( $test2->size, 2, 'div#id-one h1[title]' );
is( join(', ', $test2->as_trimmed_text), '(h1 title="lorum")(/h1), (h1 title="myheading" class="last-one" rel="last")(/h1)','got var' );

my $test3 = $query->query('div#id-one h1[class=example]');
ok( $test3, 'div#id-one h1[class=example]' );
is( $test3->size, 1, 'div#id-one h1[class=example]' );
is( join(', ', $test3->as_trimmed_text), '(h1 class="example")(/h1)','got var' );

my $test4 = $query->query('h1.another');
ok( $test4, 'h1.another' );
is( $test4->size, 1, 'div#id-one' );
is( join(', ', $test4->as_trimmed_text), '(h1 class="another one")(/h1)','got var' );

my $test5 = $query->query('h1.one');
ok( $test5, 'h1.one' );
is( $test5->size, 1, 'h1.one' );
is( join(', ', $test5->as_trimmed_text), '(h1 class="another one")(/h1)','got var' );

my $test6 = $query->query('p.class-one');
ok( $test6, 'p.class-one' );
is( $test6->size, 2, 'p.class-one' );
is( join(', ', $test6->as_trimmed_text), '(p class="class-one") (span)(/span) text (span)(/span) (/p), (p class="class-one")(span)(/span) text (span)(/span)(/p)','got var' );

my $test7 = $query->query('div#id-one p.class-one');
ok( $test7, 'div#id-one p.class-one' );
is( $test7->size, 1, 'div#id-one p.class-one' );
is( join(', ', $test7->as_trimmed_text), '(p class="class-one") (span)(/span) text (span)(/span) (/p)','got var' );

my $test8 = $query->query('div#id-one p.class-one, p.class-one span, p.class-two');
ok( $test8, 'div#id-one p.class-one, p.class-one span, p.class-two' );
is( $test8->size, 8, 'div#id-one p.class-one, p.class-one span, p.class-two' );
is( join(', ', $test8->as_trimmed_text), '(p class="class-two")(/p), (p class="class-one") (span)(/span) text (span)(/span) (/p), (span)(/span), (span)(/span), (p class="class-two")(/p), (span)(/span), (span)(/span), (p class="class-two") (em)(/em) text (span)(/span)(a href="#")(/a) (/p)','got var' );

my $test9 = $query->query('div#id-one p.class-two *');
ok( $test9, 'div#id-one p.class-two *' );
is( $test9->size, 0, 'div#id-one p.class-two *' );
is( join(', ', $test9->as_trimmed_text), '','got var' );

my $test10 = $query->query('p.class-two em');
ok( $test10, 'p.class-two em' );
is( $test10->size, 1, 'p.class-two em' );
is( join(', ', $test10->as_trimmed_text), '(em)(/em)','got var' );

my $test11 = $query->query('div#id-one p.class-one > span');
ok( $test11, 'div#id-one p.class-one > span' );
is( $test11->size, 2, 'div#id-one p.class-one > span' );
is( join(', ', $test11->as_trimmed_text), '(span)(/span), (span)(/span)','got var' );

my $test12 = $query->query('div em');
ok( $test12, 'div em' );
is( $test12->size, 4, 'div em' );
is( join(', ', $test12->as_trimmed_text), '(em) (span class="sub-class")(/span) (span class="sub-class2")(/span) (span class="under_class2")(/span) (span class="sub-class2 under_class3")(/span) (/em), (em) (span class="sub-class")(/span) (span class="sub-class2")(strong)(/strong)(strong class="class-four")(/strong)(/span) (span class="under_class2")(/span) (/em), (em)(/em), (em)(/em)','got var' );

my $test13 = $query->query('div>em');
ok( $test13, 'div>em' );
is( $test13->size, 2, 'div>em' );
is( join(', ', $test13->as_trimmed_text), '(em)(/em), (em)(/em)','got var' );

my $test14 = $query->query('div#id-one div p>em');
ok( $test14, 'div#id-one div p>em' );
is( $test14->size, 2, 'div#id-one div p>em' );
is( join(', ', $test14->as_trimmed_text), '(em) (span class="sub-class")(/span) (span class="sub-class2")(/span) (span class="under_class2")(/span) (span class="sub-class2 under_class3")(/span) (/em), (em) (span class="sub-class")(/span) (span class="sub-class2")(strong)(/strong)(strong class="class-four")(/strong)(/span) (span class="under_class2")(/span) (/em)','got var' );

my $test15 = $query->query('div#id-one div p>em span[class|=sub]');
ok( $test15, 'div#id-one div p>em span[class|=sub]' );
is( $test15->size, 5, 'div#id-one div p>em span[class|=sub]' );
is( join(', ', $test15->as_trimmed_text), '(span class="sub-class")(/span), (span class="sub-class2")(/span), (span class="sub-class2 under_class3")(/span), (span class="sub-class")(/span), (span class="sub-class2")(strong)(/strong)(strong class="class-four")(/strong)(/span)','got var' );

my $test16 = $query->query('div#id-one div p>em span[class=sub-class2] + span[class=under_class2]');
ok( $test16, 'div#id-one div p>em span[class=sub-class2] + span[class=under_class2]' );
is( $test16->size, 2, 'div#id-one div p>em span[class=sub-class2] + span[class=under_class2]' );
is( join(', ', $test16->as_trimmed_text), '(span class="under_class2")(/span), (span class="under_class2")(/span)','got var' );

my $test17 = $query->query('div#id-one div.class-three p>em span[class|=sub] + span[class=under_class2]');
ok( $test17, 'div#id-one div.class-three p>em span[class|=sub] + span[class=under_class2]' );
is( $test17->size, 1, 'div#id-one div.class-three p>em span[class|=sub] + span[class=under_class2]' );
is( join(', ', $test17->as_trimmed_text), '(span class="under_class2")(/span)','got var' );

my $test18 = $query->query('div.class-three + div.class-four');
ok( $test18, 'div.class-three + div.class-four' );
is( $test18->size, 1, 'div.class-three + div.class-four' );
is( join(', ', $test18->as_trimmed_text), '(div class="class-four") (p)(/p)(em)(/em) (/div)','got var' );

my $test19 = $query->query('div#id-one * span + span.sub-class2 > strong');
ok( $test19, 'div#id-one * span + span.sub-class2 > strong' );
is( $test19->size, 2, 'div#id-one * span + span.sub-class2 > strong' );
is( join(', ', $test19->as_trimmed_text), '(strong)(/strong), (strong class="class-four")(/strong)','got var' );

my $test20 = $query->query('div#id-one * span + span.sub-class2 >[class]');
ok( $test20, 'div#id-one * span + span.sub-class2 >[class]' );
is( $test20->size, 1, 'div#id-one * span + span.sub-class2 >[class]' );
is( join(', ', $test20->as_trimmed_text), '(strong class="class-four")(/strong)','got var' );

my $test21 = $query->query('span[class~=under_class3]');
ok( $test21, 'span[class~=under_class3]' );
is( $test21->size, 1, 'span[class~=under_class3]' );
is( join(', ', $test21->as_trimmed_text), '(span class="sub-class2 under_class3")(/span)','got var' );

my $test22 = $query->query('div#id-one p>em span[class=under_class2] + span[class~=under_class3]');
ok( $test22, 'div#id-one p>em span[class=under_class2] + span[class~=under_class3]' );
is( $test22->size, 1, 'div#id-one p>em span[class=under_class2] + span[class~=under_class3]' );
is( join(', ', $test22->as_trimmed_text), '(span class="sub-class2 under_class3")(/span)','got var' );

my $test23 = $query->query('div#id-one div[class=class-three] span[class=sub-class2] strong[class=class-four]');
ok( $test23, 'div#id-one div[class=class-three] span[class=sub-class2] strong[class=class-four]' );
is( $test23->size, 1, 'div#id-one div[class=class-three] span[class=sub-class2] strong[class=class-four]' );
is( join(', ', $test23->as_trimmed_text), '(strong class="class-four")(/strong)','got var' );

my $test24 = $query->query('h1[title][class=last-one][rel=last]');
ok( $test24, 'h1[title][class=last-one][rel=last]' );
is( $test24->size, 1, 'h1[title][class=last-one][rel=last]' );
is( join(', ', $test24->as_trimmed_text), '(h1 title="myheading" class="last-one" rel="last")(/h1)','got var' );

my $test25 = $query->query('* html');
ok( $test25, '* html' );
is( $test25->size, 0, '* html' );

my $test26 = $query->query('a');
ok( $test26, 'a' );
is( $test26->size, 1, 'link test' );
is( join(', ', $test26->as_trimmed_text), '(a href="#")(/a)','got var' );
