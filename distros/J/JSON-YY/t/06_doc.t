use strict;
use warnings;
use Test::More;
use JSON::YY ':doc';

# jdoc — parse JSON
my $doc = jdoc '{"name":"Alice","age":30,"tags":["a","b"]}';
ok defined $doc, 'jdoc creates doc';
is ref $doc, 'JSON::YY::Doc', 'jdoc returns Doc object';

# jencode — serialize
is jencode $doc, "", '{"name":"Alice","age":30,"tags":["a","b"]}', 'jencode full doc';
is jencode $doc, "/tags", '["a","b"]', 'jencode subtree';

# jgetp — get as Perl value
is jgetp $doc, "/name", 'Alice', 'jgetp string';
is jgetp $doc, "/age", 30, 'jgetp number';
is_deeply jgetp $doc, "/tags", ['a', 'b'], 'jgetp array';
is_deeply jgetp $doc, "", {name => 'Alice', age => 30, tags => ['a', 'b']}, 'jgetp root';
is jgetp $doc, "/nonexistent", undef, 'jgetp missing returns undef';

# jset — set scalar values
jset $doc, "/age", 31;
is jgetp $doc, "/age", 31, 'jset scalar';

# jset — set from Perl ref
jset $doc, "/meta", {total => 1, page => 1};
is jtype $doc, "/meta", "object", 'jset hashref creates object';
is jgetp $doc, "/meta/total", 1, 'jset hashref content';

jset $doc, "/nums", [10, 20, 30];
is jtype $doc, "/nums", "array", 'jset arrayref creates array';
is jgetp $doc, "/nums/1", 20, 'jset arrayref content';

# jset — set root
jset $doc, "", {replaced => 1};
is jencode $doc, "", '{"replaced":1}', 'jset root replaces entire doc';

# restore
$doc = jdoc '{"a":{"b":[1,2,3]},"c":"hello"}';

# jhas — existence check
ok jhas $doc, "/a/b", 'jhas existing path';
ok jhas $doc, "/a/b/0", 'jhas array element';
ok !jhas $doc, "/nope", 'jhas missing path';
ok !jhas $doc, "/a/nope", 'jhas missing nested';

# jtype — type checking
is jtype $doc, "/a", "object", 'jtype object';
is jtype $doc, "/a/b", "array", 'jtype array';
is jtype $doc, "/c", "string", 'jtype string';
is jtype $doc, "/a/b/0", "number", 'jtype number';

# jlen — container length
is jlen $doc, "/a/b", 3, 'jlen array';
is jlen $doc, "/a", 1, 'jlen object';
is jlen $doc, "/c", 5, 'jlen string';

# jkeys — object keys
my @keys = jkeys $doc, "/a";
is_deeply [sort @keys], ['b'], 'jkeys';

$doc = jdoc '{"x":1,"y":2,"z":3}';
@keys = sort(jkeys $doc, "");
is_deeply \@keys, ['x','y','z'], 'jkeys root object';

# jget — subtree reference (borrowing)
$doc = jdoc '{"a":{"b":[1,2,3]}}';
my $sub = jget $doc, "/a/b";
is ref $sub, 'JSON::YY::Doc', 'jget returns Doc';
is jencode $sub, "", '[1,2,3]', 'jget subtree encodes correctly';

# modifying via parent affects subtree (shared)
jset $doc, "/a/b/1", 42;
is jencode $sub, "", '[1,42,3]', 'subtree ref reflects parent changes';

# jclone — deep copy
$doc = jdoc '{"a":{"b":[1,2,3]}}';
my $copy = jclone $doc, "/a";
is jencode $copy, "", '{"b":[1,2,3]}', 'jclone creates copy';

jset $copy, "/b/0", 99;
is jencode $copy, "", '{"b":[99,2,3]}', 'jclone is independent (modified)';
is jencode $doc, "/a", '{"b":[1,2,3]}', 'jclone is independent (original unchanged)';

my $full_copy = jclone $doc, "";
is jencode $full_copy, "", '{"a":{"b":[1,2,3]}}', 'jclone full doc';

# jdel — delete
$doc = jdoc '{"a":1,"b":2,"c":3}';
my $del = jdel $doc, "/b";
is ref $del, 'JSON::YY::Doc', 'jdel returns Doc';
is jencode $del, "", '2', 'jdel returns deleted value';
ok !jhas $doc, "/b", 'jdel removes from doc';
is jencode $doc, "", '{"a":1,"c":3}', 'jdel result';

# jdel missing path returns undef
my $del2 = jdel $doc, "/nope";
ok !defined $del2, 'jdel missing returns undef';

# value constructors
is jencode jstr "hello", "", '"hello"', 'jstr';
is jencode jstr "007", "", '"007"', 'jstr preserves string';
is jencode jnum 42, "", '42', 'jnum integer';
is jencode jnum 3.14, "", '3.14', 'jnum float';
is jencode jbool 1, "", 'true', 'jbool true';
is jencode jbool 0, "", 'false', 'jbool false';
is jencode jnull, "", 'null', 'jnull';
is jencode jarr, "", '[]', 'jarr';
is jencode jobj, "", '{}', 'jobj';

# value constructors with jset
$doc = jdoc '{}';
jset $doc, "/s", jstr "007";
jset $doc, "/n", jnum 42;
jset $doc, "/t", jbool 1;
jset $doc, "/f", jbool 0;
jset $doc, "/null", jnull;
jset $doc, "/a", jarr;
jset $doc, "/o", jobj;
my $result = jencode $doc, "";
like $result, qr/"s":"007"/, 'jstr in jset preserves string';
like $result, qr/"t":true/, 'jbool true in jset';
like $result, qr/"f":false/, 'jbool false in jset';
like $result, qr/"null":null/, 'jnull in jset';
like $result, qr/"a":\[\]/, 'jarr in jset';
like $result, qr/"o":\{\}/, 'jobj in jset';

# jset with Doc value (from jclone)
$doc = jdoc '{"a":1}';
my $other = jdoc '{"x":10,"y":20}';
jset $doc, "/b", jclone $other, "";
is jencode $doc, "/b", '{"x":10,"y":20}', 'jset Doc value from jclone';

# array append with JSON Pointer "-"
$doc = jdoc '{"arr":[1,2]}';
jset $doc, "/arr/-", 3;
is jencode $doc, "/arr", '[1,2,3]', 'array append with /-';
jset $doc, "/arr/-", jstr "end";
is jencode $doc, "/arr", '[1,2,3,"end"]', 'array append typed value';

# nested document operations
$doc = jdoc '{}';
jset $doc, "/users", jarr;
jset $doc, "/users/-", {name => "Alice", age => 30};
jset $doc, "/users/-", {name => "Bob", age => 25};
is jlen $doc, "/users", 2, 'nested ops: array length';
is jgetp $doc, "/users/0/name", 'Alice', 'nested ops: access first';
is jgetp $doc, "/users/1/name", 'Bob', 'nested ops: access second';

# cleanup: doc goes out of scope
{
    my $temp = jdoc '{"x":1}';
    my $ref = jget $temp, "/x";
    is jencode $ref, "", '1', 'subtree ref works in scope';
}
# no crash after scope exit

# unicode
$doc = jdoc '{"emoji":"\u263a"}';
my $e = jgetp $doc, "/emoji";
ok utf8::is_utf8($e), 'jgetp returns UTF-8 string';

# booleans
$doc = jdoc '{"t":true,"f":false,"n":null}';
ok jgetp $doc, "/t", 'jgetp true is true';
ok !jgetp $doc, "/f", 'jgetp false is false';
ok !defined jgetp $doc, "/n", 'jgetp null is undef';

# ---- iterators ----

# array iterator
$doc = jdoc '{"items":[10,20,30]}';
{
    my $it = jiter $doc, "/items";
    is ref $it, 'JSON::YY::Iter', 'jiter returns Iter object';
    my @vals;
    while (defined(my $v = jnext $it)) {
        push @vals, jgetp $v, "";
    }
    is_deeply \@vals, [10, 20, 30], 'array iterator collects all values';
}

# object iterator with jkey
$doc = jdoc '{"x":1,"y":2,"z":3}';
{
    my $it = jiter $doc, "";
    my %kv;
    while (defined(my $v = jnext $it)) {
        my $k = jkey $it;
        $kv{$k} = jgetp $v, "";
    }
    is_deeply \%kv, {x => 1, y => 2, z => 3}, 'object iterator with jkey';
}

# empty container iterators
$doc = jdoc '[]';
{
    my $it = jiter $doc, "";
    ok !defined(jnext $it), 'empty array iterator returns undef immediately';
}
$doc = jdoc '{}';
{
    my $it = jiter $doc, "";
    ok !defined(jnext $it), 'empty object iterator returns undef immediately';
}

# iterator values are Doc subtree refs
$doc = jdoc '[{"a":1},{"a":2}]';
{
    my $it = jiter $doc, "";
    my $first = jnext $it;
    is ref $first, 'JSON::YY::Doc', 'iterator value is Doc';
    is jencode $first, "", '{"a":1}', 'iterator value encodes correctly';
    is jgetp $first, "/a", 1, 'iterator value supports path access';
}

# nested iteration
$doc = jdoc '[[1,2],[3,4],[5,6]]';
{
    my $it = jiter $doc, "";
    my @sums;
    while (defined(my $row = jnext $it)) {
        my $inner = jiter $row, "";
        my $sum = 0;
        while (defined(my $cell = jnext $inner)) {
            $sum += jgetp $cell, "";
        }
        push @sums, $sum;
    }
    is_deeply \@sums, [3, 7, 11], 'nested array iteration';
}

# iterator scope safety
{
    my $doc2 = jdoc '[1,2,3]';
    my $it = jiter $doc2, "";
    my $v = jnext $it;
    is jgetp $v, "", 1, 'iterator value in scope';
}
# no crash after scope exit

done_testing;
