#!/usr/bin/perl -T

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;

# -------------------------#
use tests 4; # Make sure that HTML::DOM::Element::HTML’s @ISA is in the
             # right order, and that it isan HTML element.
{
	my $doc = new HTML::DOM;
	$doc->write('<title></title><body>some text</body>');
	is+(my $elem = $doc->documentElement)->as_text, 'some text',
		'HTML::DOM::Element::HTML->as_text';
	like $elem->as_HTML,qr/^[^~]+\z/,
	 'HTML::DOM::Element::HTML->as_HTML';
	isa_ok $elem, HTML::DOM::Element::class_for('html');
	can_ok $elem, 'version';
}


# -------------------------#
use tests 1; # implicit tbody
{
	my $doc = new HTML::DOM;
	$doc->write('<table><tr><td>foo</table>');
	like $doc->find('table')->as_HTML,
		qr\<table><tbody><tr><td>foo</td></tr></tbody></table>$\,
		'implicit tbody';
}

# -------------------------#
use tests 1; # make sure <td><td> doesn’t try to insert an extra <tr>
{            # inside the current <tr>. Version 0.011 broke this, and
             # 0.016 fixed it.
	my $doc = new HTML::DOM;
	$doc->write('<table><tr><td>a<td>b</table>');
	$doc->close;
	like $doc->documentElement->as_HTML,
	 qr\^<html><head></head><body>(?x:
	       )<table>(?x:
	          )<tbody><tr><td>a</td><td>b</td></tr></tbody>(?x:
	       )</table>(?x:
	    )</body></html>$\,
		'<td><td>';
}

# -------------------------#
use tests 2; # Make sure comments get parsed and added to the tree as
{            # comment nodes (added in 0.026)
	my $doc = new HTML::DOM;
	$doc->write('<body><!--foo-->');
	$doc->close;
	like $doc->documentElement->as_HTML,
	   qr\^<html><head></head><body>(?x:
	      )<!--foo-->(?x:
	      )</body></html>$\,
		'parsing comments';
	isa_ok $doc->body->firstChild, 'HTML::DOM::Comment',
	 'parsed comment';
}

# -------------------------#
use tests 1; # </td> and </th> outside of their respective elements should
{                      # not be allowed to close an elem outside the cur-
	my $doc = new HTML::DOM;  # rent table (fixed in 0.042)
	$doc->write(
	  '<table><tr><th>'
	 .'<table><tr><td>'
	 .'<table><tr><th>A</td><td>B</th><td>C</table>'
	 .'</table></table>'
	);
	$doc->close;
	is $doc->innerHTML,
	   '<html><head></head><body>'
	  ."<table><tbody><tr><th>"
	  ."<table><tbody><tr><td>"
	  ."<table><tbody><tr>"
	  ."<th>A</th><td>B</td><td>C</td>"
	  ."</tr></tbody></table>"
	  ."</td></tr></tbody></table>"
	  ."</th></tr></tbody></table>"
	  ."</body></html>",
		'parsing unmatched </td> and </th>';
}

# -------------------------#
use tests 1; # extraneous <body> should not change current insertion pos
             # See RT #75997 and #76021.
{
  my $doc = new HTML::DOM;
  $doc->innerHTML('<form><body><input name=foo value=bar>');
  is join(",",$doc->forms->[0]->form), "foo,bar",
  '<form><body> does not imply </form>';
}
