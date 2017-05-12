#!/usr/bin/perl -w

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;
use HTML::DOM;
use Scalar::Util 'weaken';

#use Devel::Cycle;
#use Scalar::Util 'isweak';

# -------------------------#
use tests 9; # Make sure the dust cart comes.

my $doc = new HTML::DOM;
$doc->write('<title>A</title><body>hole<div>bunch<i>o’</i>stuff</div>');
$doc->close;
weaken $doc;
is $doc, undef, 'poof';

$doc = new HTML::DOM;
$doc->write('stuff');
$doc->open;
weaken $doc;
is $doc, undef, 'poof after open';

$doc = new HTML::DOM;
$doc->write('<table></table>');
$doc->close;
(my $table = $doc->getElementsByTagName('table')->[0])->caption(
	$doc->createElement('caption')
);
weaken $table;
undef $doc;
is $table, undef, 'poof after unshift_content (implied by table->caption)';

$doc = new HTML::DOM;
$doc->write('<body>stuff');
$doc->close;
my $body = $doc->body;
weaken $body;
undef $doc;
is $body, undef,
	'poof after splice_content (text nodes are added that way)';


$doc = new HTML::DOM;
$doc->write(" ");
$doc->close;
{
	my $copy = $doc;
	weaken $doc;
	undef $copy;
	is $doc, undef, 'poof after $doc->write(" "); $doc->close';
}

$doc = new HTML::DOM;
{
	my $elem = $doc->createElement("body");
	$elem->setAttribute("onload","foo");
	my $a = $elem->getAttributeNode('onload');
	scalar $a->childNodes; # autovivifies the text node;
	my $a_copy = $a;
	weaken $a;
	undef $a_copy; undef $elem;
	is $a, undef, 'poof after $attr->childNodes';
}

{
	my $elem = $doc->createElement("body");
	$elem->setAttribute("onload","foo");
	my $t = $doc->createTextNode('yoo');
	my $a = $elem->getAttributeNode('onload');
	$a->replaceChild($t, $a->firstChild);
	my $a_copy = $a;
	weaken $a;
	undef $a_copy, undef $elem;
	is $a, undef, 'poof after $attr->childNodes';
}

{
	my $node = $doc->createElement("body");
	$node->innerHTML("<foo><bar>baz</bar></foo>");
	my $clone = $node->cloneNode("deeep");
	my $other_ref = $clone;
	weaken $clone;
	undef $other_ref;
	is $clone, undef, 'pooof!  on a deep clone';
}

{
	my $node = $doc->createElement("body");
	$node->innerHTML("eioiu;");
	$node->replaceChild($doc->createTextNode('Ooe'),$node->firstChild);
	my $other_ref = $node;
	weaken $node;
	undef $other_ref;
	is $node, undef, 'poof after replaceChild';
}




__END__

Copy and paste this stuff for debugging:

find_cycle $doc;
diag 'isweak: ',isweak ${$doc->defaultView};
diag 'isweak: ',isweak $doc->documentElement->{_parent};
