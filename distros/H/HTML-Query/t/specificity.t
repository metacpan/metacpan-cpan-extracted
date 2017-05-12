#============================================================= -*-perl-*-
#
# t/element.t
#
# Test 'query' export hook which monkey patches the query() method
# into HTML::Element.
#
# Written by Andy Wardley, October 2008
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 24,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::TreeBuilder;
use HTML::Query 'Query query';

my %rules = (
    "li"                    => 1,
    "ul li"                 => 2,
    "ul ol li"              => 3,
    "li.red"                => 11,
    "ul ol li.red"          => 13,
    "td.foo p.bar em"       => 23,
    "td.foo"                => 11,
    "td.foo p"              => 12,
    "td.foo p.bar em.blah"  => 33,
    "td p em"               => 3,
    "td #blah"              => 101,
    "#blah td"              => 101,
    "#blah td.foo"          => 111,
    "#blah td.foo span"     => 112,
    "#blah td.foo span.bar" => 122,
    "div#id-one p>em span[class=under_class2] + span[class~=under_class3]" => 125,
    "span[title='w00t'][title].new-class#test-id[lang='en']" => 141,
    "div em" => 2,
    "div>em" => 2,
    "*" => 0,
    "div#id-one div p>em" => 104,
    "html#simple body#internal" => 202,
    "body#internal" => 101,
    "div:first-child" => 11,
);

foreach my $rule (keys %rules) {
  my $weight = Query->get_specificity($rule);

  is($weight, $rules{$rule}, "correct weight for \"$rule\"");
}
