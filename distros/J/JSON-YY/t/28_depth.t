use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

my $HAVE_LEAKTRACE;
BEGIN {   # import at compile time so no_leaks_ok's prototype is in scope
    $HAVE_LEAKTRACE =
        eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 } ? 1 : 0;
}
use JSON::YY qw(encode_json decode_json decode_json_ro);
use JSON::YY ':doc';

# Deeply nested input ran the C stack out. yyjson's parser and writer are
# iterative, but our materialisers recurse and so do the copy/equals routines
# behind jclone/jwrite/jeq, so every parse entry point bounds nesting first.

my $LIMIT = 512;                       # MAX_DEPTH_DEFAULT
sub arr { my $n = shift; ('[' x $n) . (']' x $n) }
sub obj { my $n = shift; ('{"a":' x $n) . '1' . ('}' x $n) }

# --- the bound itself ---
{
    ok  eval { decode_json(arr($LIMIT));     1 }, "arrays $LIMIT deep are accepted";
    ok  eval { decode_json(obj($LIMIT));     1 }, "objects $LIMIT deep are accepted";
    ok !eval { decode_json(arr($LIMIT + 1)); 1 }, 'one level deeper is rejected';
    like $@, qr/maximum nesting depth/, 'and says why';
    ok !eval { decode_json(obj($LIMIT + 1)); 1 }, 'objects too, one level deeper';
}

# --- every entry point that takes JSON text ---
{
    my $deep = arr(200_000);           # used to segfault
    my @gates = (
        ['decode_json'    => sub { decode_json($deep) }],
        ['decode_json_ro' => sub { decode_json_ro($deep) }],
        ['OO decode'      => sub { JSON::YY->new->decode($deep) }],
        ['OO decode_doc'  => sub { JSON::YY->new->decode_doc($deep) }],
        ['jdoc'           => sub { jdoc $deep }],
        ['jraw'           => sub { my $d = jfrom {}; jraw $d, "/x", $deep }],
    );
    for my $g (@gates) {
        my ($name, $code) = @$g;
        ok !eval { $code->(); 1 }, "$name rejects 200k levels";
        like $@, qr/maximum nesting depth/, "$name: depth error";
    }

    my ($fh, $file) = tempfile(UNLINK => 1);
    print $fh $deep; close $fh;
    ok !eval { jread $file; 1 }, 'jread rejects a 200k-level file';
    like $@, qr/maximum nesting depth/, 'jread: depth error';
}

# --- encoding a deep Perl structure was already bounded; check it still is ---
{
    my $top = []; my $cur = $top;
    for (1 .. 5000) { my $next = []; push @$cur, $next; $cur = $next }
    ok !eval { encode_json($top); 1 }, 'encode rejects a deep Perl structure';
    ok !eval { jfrom $top; 1 },        'jfrom rejects it too';
}

# --- a very long JSON Pointer would otherwise build a document deeper than
#     anything here can walk: jset creates one parent per component ---
{
    my $doc = jfrom {};
    my $ok_path = join '', map { "/k$_" } 1 .. $LIMIT;
    ok eval { jset $doc, $ok_path, 1; 1 }, "a $LIMIT-component path is accepted";

    my $deep_path = join '', map { "/k$_" } 1 .. $LIMIT + 1;
    ok !eval { jset jfrom({}), $deep_path, 1; 1 }, 'one component more is rejected';
    like $@, qr/nests deeper than the maximum depth/, 'jset: path depth error';
    ok !eval { jraw jfrom({}), $deep_path, '[1]'; 1 }, 'jraw rejects it too';

    # the pointer that used to reach jclone's recursion
    my $huge = join '', map { "/k$_" } 1 .. 200_000;
    ok !eval { jset jfrom({}), $huge, 1; 1 }, 'a 200k-component path is rejected';

    # a slash inside a key is spelled ~1 and must not count as a component
    ok eval { my $d = jfrom {}; jset $d, "/a~1b", 1; "$d" eq '{"a/b":1}' },
        'an escaped slash is not counted as nesting';
}

# --- repeated mutation can still build past the limit (each path is short),
#     which is exactly why the materialisers carry their own budget ---
{
    my $doc = jfrom {};
    my $cur = $doc;
    for (1 .. $LIMIT + 88) { jset $cur, "/k", {}; $cur = jget $cur, "/k" }
    ok !eval { jgetp $doc, ""; 1 },  'jgetp refuses to materialise past the limit';
    like $@, qr/maximum nesting depth/, 'jgetp: depth error';
    ok !eval { my @p = jpaths $doc, ""; 1 }, 'jpaths refuses too';
    like $@, qr/maximum nesting depth/, 'jpaths: depth error';
}

# --- wide documents must not be mistaken for deep ones ---
{
    my $wide = '[' . join(',', map { qq({"k":[1,2,3],"s":"x"}) } 1 .. 5000) . ']';
    my $got = decode_json($wide);
    is scalar(@$got), 5000, 'a wide shallow document is accepted';
    ok defined(jdoc $wide), 'jdoc accepts it as well';

    # a deep branch buried inside a wide document must still be caught
    my $buried = '[' . join(',', map { 1 } 1 .. 5000) . ',' . arr(600) . ']';
    ok !eval { decode_json($buried); 1 }, 'a deep branch inside a wide document is caught';
}

# --- the OO coder's max_depth applies to decoding ---
{
    my $c = JSON::YY->new(max_depth => 10);
    ok  eval { $c->decode(arr(10)); 1 },  'max_depth 10 accepts 10 levels';
    ok !eval { $c->decode(arr(11)); 1 },  'max_depth 10 rejects 11';
    ok !eval { $c->decode_doc(arr(11)); 1 }, 'decode_doc honours max_depth';
    my $loose = JSON::YY->new(max_depth => 2000);
    ok eval { $loose->decode(arr(1000)); 1 }, 'a raised max_depth accepts deeper input';
}

# --- encode and decode must agree on the boundary, or the module emits JSON
#     it will not read back ---
{
    sub nest { my $n = shift; my $t = []; my $c = $t;
               for (2 .. $n) { my $x = []; push @$c, $x; $c = $x } $t }
    ok  eval { encode_json(nest($LIMIT)); 1 },     "encode accepts $LIMIT levels";
    ok !eval { encode_json(nest($LIMIT + 1)); 1 }, 'encode rejects one more';
    ok  eval { decode_json(encode_json(nest($LIMIT))); 1 },
        'what encode emits at the limit, decode accepts';
    ok !eval { JSON::YY->new(utf8 => 1, pretty => 1)->encode(nest($LIMIT + 1)); 1 },
        'the pretty path agrees';
    ok !eval { jfrom nest($LIMIT + 1); 1 }, 'jfrom agrees';
}

# --- a TO_JSON returning its own object must hit max_depth, not the C stack ---
{
    { package YYDepth::Self; sub new { bless {}, shift } sub TO_JSON { $_[0] } }
    { package YYDepth::A; our $o; sub TO_JSON { $o } }
    { package YYDepth::B; our $o; sub TO_JSON { $o } }
    my $c = JSON::YY->new(utf8 => 1, convert_blessed => 1, allow_blessed => 1);
    ok !eval { $c->encode(YYDepth::Self->new); 1 }, 'self-returning TO_JSON croaks';
    like $@, qr/maximum nesting depth/, 'and it is the depth guard that fires';
    ok !eval { JSON::YY->new(utf8 => 1, convert_blessed => 1, pretty => 1)
                 ->encode(YYDepth::Self->new); 1 }, 'pretty path too';
    ok !eval { jfrom YYDepth::Self->new; 1 }, 'jfrom too';

    my $a = bless {}, 'YYDepth::A'; my $b = bless {}, 'YYDepth::B';
    $YYDepth::A::o = $b; $YYDepth::B::o = $a;
    ok !eval { $c->encode($a); 1 }, 'a two-object TO_JSON cycle croaks';

    # a legitimate TO_JSON chain is unaffected
    { package YYDepth::Ok; sub new { bless { v => $_[1] }, $_[0] }
                           sub TO_JSON { { v => $_[0]{v} } } }
    is $c->encode(YYDepth::Ok->new(1)), '{"v":1}', 'ordinary TO_JSON still works';
    ok eval { $c->encode([ map { YYDepth::Ok->new($_) } 1 .. 400 ]); 1 },
        '400 TO_JSON objects in a row still encode';
}

# --- rejecting deep input must not leak ---
SKIP: {
    skip 'Test::LeakTrace required', 2 unless $HAVE_LEAKTRACE;
    my $deep = arr(2000);
    eval { decode_json($deep) };            # warm caches
    no_leaks_ok { eval { decode_json($deep) } } 'rejected decode does not leak';
    eval { jdoc $deep };
    no_leaks_ok { eval { jdoc $deep } } 'rejected jdoc does not leak';
}

done_testing;
