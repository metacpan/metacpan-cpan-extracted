#!/usr/bin/env perl

use strict;
use warnings;

use HTML::WikiConverter;

use Marpa::R2::HTML 'html';

# Author: Jeffrey Kegler.

#--------------------------

sub fix_tags
{
	my($tagname) = Marpa::R2::HTML::tagname();

	return if (Marpa::R2::HTML::is_empty_element);

	return (Marpa::R2::HTML::start_tag() // "<$tagname>\n") .
			Marpa::R2::HTML::contents() .
			(Marpa::R2::HTML::end_tag() // "</$tagname>\n" );
}

#--------------------------

my($original_html) = 'Text<table><tr><td>I am a cell</table> More Text';
my($valid_html)    = ${html( \$original_html, {'*' => \&fix_tags})};
my($dialect)       = shift || 'DokuWiki';
my($converter)     = HTML::WikiConverter -> new(dialect => $dialect);

print "Original HTML: \n";
print '-' x 50, "\n";
print "$original_html\n";
print '-' x 50, "\n";
print "Valid HTML: \n";
print '-' x 50, "\n";
print "$valid_html\n";
print '-' x 50, "\n";
print "$dialect: \n";
print '-' x 50, "\n";
print $converter -> html2wiki(html => $original_html), "\n";
print '-' x 50, "\n";

