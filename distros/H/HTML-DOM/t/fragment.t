#!/usr/bin/perl -T

use strict; use warnings; use lib 't';

use Test::More tests => 6;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::DocumentFragment'; }

# -------------------------#
# Tests 2-6: constructor & methods

{
	my $f = new HTML::DOM::DocumentFragment;
	isa_ok $f, 'HTML::DOM::DocumentFragment';
	is $f->nodeName, '#document-fragment', 'nodeName';
	is $f->nodeType, 11, 'nodeType';
	is scalar(()=$f->nodeValue), 0, 'nodeValue';
	is scalar(()=$f->attributes), 0, 'attributes';
}