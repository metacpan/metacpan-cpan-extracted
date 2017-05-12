use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use HTML::Valid::Tagset ':all';
my $taginfo = test_taginfo ('a');
ok ($taginfo, "got tag info for a element");
ok (ref $taginfo eq 'ARRAY', "a element tag info is an array");
ok (scalar (@$taginfo) == 3, "a element tag info has two members");
ok ($taginfo->[0] == 1, "a is the first element");

ok ($emptyElement{'br'}, "br is among the empty elements");
ok ($isTableElement{'tr'}, "<tr> is among the table elements");
ok ($isTableElement{'td'}, "<td> is among the table elements");
ok ($isTableElement{'th'}, "<th> is among the table elements");
ok ($isTableElement{'tbody'}, "<tbody> is among the table elements");
ok ($isTableElement{'caption'}, "<caption> is among the table elements");
ok ($isTableElement{'colgroup'}, "<caption> is among the table elements");
# <table> is not a table element, in that it doesn't appear inside
# tables.
ok (! $isTableElement{'table'}, "<table> is not among the table elements");
ok (! $isTableElement{'banana'}, "<banana> is not among the table elements");
ok (! $isTableElement{a}, "<a> is not among the table elements");

# This list was poached from HTML::Tagset but I removed isindex from
# it. Reported as https://rt.cpan.org/Ticket/Display.html?id=109018.

for (qw(title base link meta script style bgsound)) {
    ok ($isHeadElement{$_}, "<$_> is a head element");
}
ok (! $isHeadElement{'a'}, "<a> is not a head element");
ok (! $isHeadElement{isindex}, "<isindex> is not a head element");

for (qw/canvas section/) {
ok ($isHTML5{$_}, "<$_> is HTML5");
}
for (qw/plaintext listing/) {
ok (! $isHTML5{$_}, "<$_> is not HTML5");
ok ($isObsolete{$_}, "<$_> is obsolete");
}
for (qw(input select option optgroup textarea button label)) {
ok ($isFormElement{$_}, "<$_> is a form element");
}

for (qw(
  span abbr acronym q sub sup
  cite code em kbd samp strong var dfn strike
  b i u s tt small big 
  a img br
  wbr nobr blink
  font basefont bdo
  spacer embed noembed
   )) {
    ok ($isPhraseMarkup{$_}, "<$_> is phrasal (inline)");
}

ok ($isBlock{p}, "<p> is a block-level element");
ok (! $isBlock{span}, "<span> is not a block-level element");
ok ($isTableElement{tr}, "<tr> is a table element");
ok ($isTableElement{tfoot}, "<tfoot> is a table element");
ok (! $isTableElement{p}, "<p> is not a table element");

TODO: {
    local $TODO = 'do not include the flagging tags from the tag list';
    ok (! $isKnown{'unknown!'});
};

TODO: {
local $TODO = 'implement head-only element hashset';
eval "\$isHeadOnlyElement{title};";
ok (! $@);
};
done_testing ();
