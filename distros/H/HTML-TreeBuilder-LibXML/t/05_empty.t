use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

my @tests = ("foo", "bar\nbaz", "   ", "   \n   ", "");
plan tests => 3 * @tests;

for my $t (@tests) {
    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($t);
    $tree->eof;

    ok $tree;
    eval { $tree->findnodes('//a') };
    ok !$@ or diag $@;

    like $tree->as_HTML, qr/<html>/;
}
