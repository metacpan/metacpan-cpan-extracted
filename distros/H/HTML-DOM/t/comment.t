#!/usr/bin/perl -T

use strict; use warnings; use lib 't';

use Test::More tests => 6;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Comment'; }

# -------------------------#
# Tests 2-6: constructor & methods

{
	my $f = new HTML::DOM::Comment 'oneuhonehu';
	isa_ok $f, 'HTML::DOM::Comment';
	is $f->nodeName, '#comment', 'nodeName';
	is $f->nodeType, 8, 'nodeType';
	is $f->nodeValue, 'oneuhonehu', 'nodeValue';
	is scalar(()=$f->attributes), 0, 'attributes';
}