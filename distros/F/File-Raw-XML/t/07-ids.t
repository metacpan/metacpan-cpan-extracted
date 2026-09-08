#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# The ID index: keyed by attribute local name in any namespace, a
# duplicate refused at parse citing the later offset, exactly one hit.

sub by_id   { File::Raw::XML::_by_id(@_) }
sub refused { my $ok = eval { File::Raw::XML::_dump($_[0], 0, $_[1]); 1 }; $ok ? '' : $@ }

my $doc = '<r xmlns:s="urn:s"><a ID="x"/><s:b s:ID="y"/><c Id="z" other="x"/><d ID="w"><e ID="v"/></d></r>';

is_deeply(by_id($doc, ['ID'], ID => 'x'), ['a', 19],   'a hit: the element and its offset');
is_deeply(by_id($doc, ['ID'], ID => 'y'), ['s:b', 30], 'an ID in a namespace is indexed by local name');
is_deeply(by_id($doc, ['ID'], ID => 'v'), ['e', 76],   'a nested one');
is(by_id($doc, ['ID'], ID => 'z'),  undef, 'Id is not ID: only the names given are indexed');
is(by_id($doc, ['ID'], ID => 'nope'), undef, 'a miss is undef');
is(by_id($doc, ['ID'], other => 'x'), undef, 'a value under an attribute name that was not indexed');
is_deeply(by_id($doc, ['ID', 'Id'], Id => 'z'), ['c', 45], 'two names in id_attrs index both');
is(by_id($doc, [], ID => 'x'), undef, 'no id_attrs means no index');

# duplicates
{
    my $dup = '<r><a ID="x"/><b ID="x"/></r>';
    like(refused($dup, ['ID']), qr/two elements carry the same ID value at byte offset 17/,
         'a duplicate is refused at parse, citing the second element\'s attribute');
    ok(!refused($dup, []), 'and not refused when ID is not an indexed name');
    ok(!refused($dup, ['Id']), 'nor when a different name is');
    ok(!refused('<r><a ID="x"/><b Id="x"/></r>', ['ID', 'Id']), 'the same value under two attribute names is two keys');
    like(refused('<r><a ID="x"/><b ID="y"/><c ID="x"/></r>', ['ID']), qr/at byte offset 28/, 'the later duplicate is the one cited, however far apart');
    like(refused('<r xmlns:s="urn:s"><a ID="x"/><b s:ID="x"/></r>', ['ID']), qr/same ID value/,
         'the index is by local name, so a namespaced ID collides with a plain one');
}

# values are compared as bytes, after normalisation
{
    ok(defined by_id('<r><a ID="a b"/></r>', ['ID'], ID => 'a b'), 'a value with a space');
    ok(defined by_id("<r><a ID='a\tb'/></r>", ['ID'], ID => 'a b'), 'a literal TAB was normalised to a space before indexing');
    ok(defined by_id('<r><a ID="&#x41;"/></r>', ['ID'], ID => 'A'), 'a reference was decoded before indexing');
    is(by_id('<r><a ID="x"/></r>', ['ID'], ID => 'X'), undef, 'and the comparison is case-sensitive');
}

done_testing;
