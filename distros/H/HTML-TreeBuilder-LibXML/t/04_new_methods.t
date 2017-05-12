use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

plan tests => 2;

{
    my $root = HTML::TreeBuilder::LibXML->new_from_content("<html><body>", "<p>foo</p>", "</body></html>");
    is $root->findvalue("//p"), "foo";
}

{
    my $root = HTML::TreeBuilder::LibXML->new_from_file("t/test.html");
    is $root->findvalue("//p"), "bar";
}
