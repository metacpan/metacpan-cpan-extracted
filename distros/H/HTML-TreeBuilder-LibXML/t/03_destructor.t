use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

plan skip_all => 'this test requires HTML::TreeBuilder::XPath' unless eval 'use HTML::TreeBuilder::XPath;1;';
plan tests => 2;

{
    my $destructor = HTML::TreeBuilder::LibXML->replace_original;
    isa_ok(HTML::TreeBuilder::XPath->new, 'HTML::TreeBuilder::LibXML');
}

isa_ok(HTML::TreeBuilder::XPath->new, 'HTML::TreeBuilder::XPath');

