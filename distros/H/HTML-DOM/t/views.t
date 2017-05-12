#!/usr/bin/perl -T

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM::View;  # load test

use HTML::DOM;
use Scalar::Util 'weaken';

my $doc = new HTML::DOM;
my $view = bless[], 'HTML::DOM::View';

use tests 11;
is +()=$doc->defaultView, 0, 'no defaultView by default';
is +()=$doc->defaultView(\($_="foo")), 0,
	'defaultView returns nothing when assigned the first time';
is ${$doc->defaultView($view)}, 'foo',
	'defaultView with an arg returns the old one';
is $doc->defaultView, $view, '  and sets it';

is +()=$view->document, 0,
	'view->document returns nothing at first';
is +()=$view->document($doc), 0,
	'view->document returns nothing when assiged the first time';
is $view->document, $doc, 'document with arg sets it';
is $view->document(\my@x), $doc,'retval of document with arg';
is $view->document, \@x,
	'document with arg sets it when something is already set';

$view->document($doc);
weaken $doc;
ok $doc, 'view holds a strong ref to the doc';
$doc = map $_, $doc;
weaken $view;
is $view, undef, 'doc holds a weak ref to the view';
