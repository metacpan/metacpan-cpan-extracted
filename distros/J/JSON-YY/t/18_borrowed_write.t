use strict; use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use JSON::YY ':doc';

# Regression: jset/jdel/jraw on a borrowed (jget) Doc must resolve paths from
# the borrowed subtree root, matching jget/jgetp reads — not from the document
# root. (Previously writes used the doc root, silently hitting the wrong node.)
# NB: the Doc keywords are list operators — call them without parentheses.

# jset on a borrowed subtree
{
    my $doc = jdoc '{"a":{"x":1,"y":2},"b":9}';
    my $sub = jget $doc, "/a";
    jset $sub, "/x", 42;
    my $ax    = jgetp $doc, "/a/x";
    my $rootx = jgetp $doc, "/x";
    my $ay    = jgetp $doc, "/a/y";
    my $b     = jgetp $doc, "/b";
    is $ax,    42,    'jset on borrowed Doc sets the subtree path';
    is $rootx, undef, 'jset on borrowed Doc does NOT touch the doc root';
    is $ay,    2,     'sibling in subtree untouched';
    is $b,     9,     'doc-root sibling untouched';
}

# jset creating a new key inside the borrowed subtree
{
    my $doc = jdoc '{"a":{"x":1}}';
    my $sub = jget $doc, "/a";
    jset $sub, "/z", "new";
    my $az   = jgetp $doc, "/a/z";
    my $rz   = jgetp $doc, "/z";
    is $az, "new", 'jset new key in borrowed subtree';
    is $rz, undef, 'jset new key does not leak to doc root';
}

# jset /- array append on a borrowed subtree
{
    my $doc = jdoc '{"a":{"list":[1,2]}}';
    my $sub = jget $doc, "/a";
    jset $sub, "/list/-", 3;
    my $list = jgetp $doc, "/a/list";
    is_deeply $list, [1,2,3], 'jset /- append on borrowed subtree';
}

# jdel on a borrowed subtree
{
    my $doc = jdoc '{"a":{"x":1,"y":2}}';
    my $sub = jget $doc, "/a";
    my $removed = jdel $sub, "/y";
    my $ay = jgetp $doc, "/a/y";
    my $ax = jgetp $doc, "/a/x";
    my $rv = jgetp $removed, "";
    is $ay, undef, 'jdel on borrowed Doc removes the subtree path';
    is $ax, 1,     'jdel leaves sibling in subtree';
    is $rv, 2,     'jdel returns the removed value';
}

# jraw on a borrowed subtree
{
    my $doc = jdoc '{"a":{"x":1}}';
    my $sub = jget $doc, "/a";
    jraw $sub, "/arr", '[1,2,3]';
    my $arr  = jgetp $doc, "/a/arr";
    my $rarr = jgetp $doc, "/arr";
    is_deeply $arr, [1,2,3], 'jraw on borrowed Doc sets subtree path';
    is $rarr, undef,         'jraw on borrowed Doc does NOT touch the doc root';
}

# Non-borrowed (owner) Doc: the common case must still work
{
    my $doc = jdoc '{"x":1}';
    jset $doc, "/x", 7;
    jset $doc, "/new", "v";
    my $x = jgetp $doc, "/x";
    my $n = jgetp $doc, "/new";
    is $x, 7,   'jset on owner Doc updates existing key';
    is $n, "v", 'jset on owner Doc adds new key';
    jdel $doc, "/x";
    my $x2 = jgetp $doc, "/x";
    is $x2, undef, 'jdel on owner Doc removes key';
}

for my $borrow (
    ['jget',  sub { jget $_[0], "/a" }],
    ['jvals', sub { my @v = jvals $_[0], ""; $v[0] }],
    ['jfind', sub { jfind $_[0], "/a", "", 7 }],
) {
    my ($name, $get) = @$borrow;
    my $doc = jdoc '{"a":[7]}';
    my $weak = $doc;
    weaken $weak;
    my $sub = $get->($doc);
    $doc = jdoc '{}';
    ok defined($weak), "$name keeps the original document after reassignment";
    SKIP: {
        skip 'backing document was freed', 1 unless defined $weak;
        is "$sub", $name eq 'jfind' ? '7' : '[7]', "$name remains readable";
    }
    undef $sub;
    ok !defined($weak), "$name releases the original document";
}

{
    my $doc = jdoc '{"a":{"b":7}}';
    my $weak = $doc;
    weaken $weak;
    $doc = jget $doc, "/a";
    $doc = jget $doc, "/b";
    ok defined($weak), 'reassigning a handle to its subtree keeps the owner';
    SKIP: {
        skip 'backing document was freed', 1 unless defined $weak;
        is "$doc", '7', 'reassigned subtree is readable';
    }
    undef $doc;
    ok !defined($weak), 'reassigned subtrees do not create an ownership cycle';
}

{
    my $doc = jdoc '[1,2]';
    my $weak = $doc;
    weaken $weak;
    my $it = jiter $doc, "";
    undef $doc;
    ok defined($weak), 'iterator keeps its backing document after undef';
    SKIP: {
        skip 'backing document was freed', 3 unless defined $weak;
        my $item = jnext $it;
        undef $it;
        ok defined($weak), 'iterator result keeps its backing document';
        is "$item", '1', 'iterator result remains readable';
        undef $item;
        ok !defined($weak), 'iterator and result release the original document';
    }
}

done_testing;
