use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;
use Data::Dumper;


# list context
my $tree = HTML::TreeBuilder::LibXML->new_from_content('<header>foo</header><footer>bar</footer>');

my @guts = $tree->guts;
is join('|', map {$_->as_HTML} @guts), '<header>foo</header>|<footer>bar</footer>', 'guts - list context';


# scalar context
my $guts = $tree->guts;

isa_ok $guts->{node}->ownerDocument, 'XML::LibXML::Document';
is $guts->as_HTML, '<div><header>foo</header><footer>bar</footer></div>', 'guts - scalar context';


# guts() must return tags from implicit <head> as well
my @nodes = HTML::TreeBuilder::LibXML->new_from_content('<title>head tag</title><div>body tag</div>')->guts;
is join('|', map {$_->as_HTML} @nodes), '<title>head tag</title>|<div>body tag</div>';


# guts must include text and comments
@nodes = HTML::TreeBuilder::LibXML->new_from_content('<title>head tag</title><!-- foo --><div>body tag</div><!-- bar --> some text')->guts;
is join('|', map {$_->as_HTML} @nodes), "<title>head tag</title>|<!-- foo -->\n|<div>body tag</div>|<!-- bar -->\n| some text";

# guts must include DOCTYPE if its not implicit
my $html_with_dtd = "<!DOCTYPE html>\n<html><body><header>html5</header></body></html>\n";
$guts = HTML::TreeBuilder::LibXML->new_from_content($html_with_dtd)->guts;
isa_ok $guts->{node}->ownerDocument->internalSubset, 'XML::LibXML::Dtd', "doctype";
is $guts->parent->as_HTML, $html_with_dtd, "document with doctype";




done_testing;
