use strict;
use warnings;
use Test::More tests => 47;
use LRU::Cache 'import';

# ============================================
# Test storing all Perl reference types
# ============================================

my $cache = LRU::Cache::new(50);

# --- Array refs ---
{
    my @data = (1, 2, 3, "four", [5, 6]);
    $cache->set("arrayref", \@data);
    my $got = $cache->get("arrayref");
    is(ref $got, 'ARRAY', 'arrayref: ref type');
    is_deeply($got, [1, 2, 3, "four", [5, 6]], 'arrayref: deep contents');
}

# --- Hash refs ---
{
    my %data = (a => 1, b => { nested => "yes" }, c => [1, 2]);
    $cache->set("hashref", \%data);
    my $got = $cache->get("hashref");
    is(ref $got, 'HASH', 'hashref: ref type');
    is($got->{a}, 1, 'hashref: simple value');
    is_deeply($got->{b}, { nested => "yes" }, 'hashref: nested hash');
    is_deeply($got->{c}, [1, 2], 'hashref: nested array');
}

# --- Scalar refs ---
{
    my $val = 42;
    $cache->set("scalarref", \$val);
    my $got = $cache->get("scalarref");
    is(ref $got, 'SCALAR', 'scalarref: ref type');
    is($$got, 42, 'scalarref: dereferenced value');
}

# --- Code refs ---
{
    my $adder = sub { return $_[0] + $_[1] };
    $cache->set("coderef", $adder);
    my $got = $cache->get("coderef");
    is(ref $got, 'CODE', 'coderef: ref type');
    is($got->(3, 7), 10, 'coderef: invocation works');
}

# --- Regex refs ---
{
    my $re = qr/^hello\s+world$/i;
    $cache->set("regexpref", $re);
    my $got = $cache->get("regexpref");
    is(ref $got, 'Regexp', 'regexpref: ref type');
    ok("Hello World" =~ $got, 'regexpref: matches');
    ok("goodbye" !~ $got, 'regexpref: non-match');
}

# --- Glob refs ---
{
    $cache->set("globref", \*STDOUT);
    my $got = $cache->get("globref");
    is(ref $got, 'GLOB', 'globref: ref type');
    is(*{$got}{IO}, *STDOUT{IO}, 'globref: same IO');
}

# --- Blessed objects ---
{
    my $obj = bless { x => 10, y => 20 }, 'My::Point';
    $cache->set("blessed", $obj);
    my $got = $cache->get("blessed");
    is(ref $got, 'My::Point', 'blessed: class preserved');
    is($got->{x}, 10, 'blessed: field x');
    is($got->{y}, 20, 'blessed: field y');
}

# --- Ref to ref ---
{
    my $inner = \"hello";
    my $outer = \$inner;
    $cache->set("refref", $outer);
    my $got = $cache->get("refref");
    is(ref $got, 'REF', 'refref: ref type');
    is($$$got, "hello", 'refref: double deref');
}

# --- undef as value ---
{
    $cache->set("undef_val", undef);
    ok($cache->exists("undef_val"), 'undef value: exists');
    is($cache->get("undef_val"), undef, 'undef value: returns undef');
}

# --- Empty string ---
{
    $cache->set("empty", "");
    ok($cache->exists("empty"), 'empty string: exists');
    is($cache->get("empty"), "", 'empty string: correct value');
}

# --- Numeric zero ---
{
    $cache->set("zero", 0);
    ok($cache->exists("zero"), 'zero: exists');
    is($cache->get("zero"), 0, 'zero: correct value');
}

# --- Large nested structure ---
{
    my $big = {
        list => [map { { id => $_, data => "x" x 100 } } 1..10],
        meta => { count => 10, type => "test" },
    };
    $cache->set("big_struct", $big);
    my $got = $cache->get("big_struct");
    is(ref $got, 'HASH', 'big struct: ref type');
    is(scalar @{$got->{list}}, 10, 'big struct: list count');
    is($got->{list}[4]{id}, 5, 'big struct: nested field');
    is($got->{meta}{count}, 10, 'big struct: meta field');
}

# ============================================
# Same tests via function-style API
# ============================================

my $fc = LRU::Cache::new(50);

# --- Array refs ---
{
    lru_set($fc, "arr", [10, 20, 30]);
    my $got = lru_get($fc, "arr");
    is(ref $got, 'ARRAY', 'func arrayref: ref type');
    is_deeply($got, [10, 20, 30], 'func arrayref: contents');
}

# --- Hash refs ---
{
    lru_set($fc, "hsh", { a => 1, b => 2 });
    my $got = lru_get($fc, "hsh");
    is(ref $got, 'HASH', 'func hashref: ref type');
    is($got->{b}, 2, 'func hashref: value');
}

# --- Code refs ---
{
    lru_set($fc, "code", sub { $_[0] * 2 });
    my $got = lru_get($fc, "code");
    is(ref $got, 'CODE', 'func coderef: ref type');
    is($got->(21), 42, 'func coderef: invocation');
}

# --- Blessed objects ---
{
    my $obj = bless [1, 2, 3], 'My::List';
    lru_set($fc, "obj", $obj);
    my $got = lru_get($fc, "obj");
    is(ref $got, 'My::List', 'func blessed: class');
    is_deeply($got, [1, 2, 3], 'func blessed: contents');
}

# --- Overwrite with different type ---
{
    lru_set($fc, "morph", "string");
    is(lru_get($fc, "morph"), "string", 'morph: initially string');
    lru_set($fc, "morph", [1, 2]);
    is_deeply(lru_get($fc, "morph"), [1, 2], 'morph: now arrayref');
    lru_set($fc, "morph", { x => 1 });
    is_deeply(lru_get($fc, "morph"), { x => 1 }, 'morph: now hashref');
    lru_set($fc, "morph", sub { 99 });
    is(ref lru_get($fc, "morph"), 'CODE', 'morph: now coderef');
    is(lru_get($fc, "morph")->(), 99, 'morph: coderef works');
}

# --- Delete returns correct ref ---
{
    lru_set($fc, "del_ref", [7, 8, 9]);
    my $deleted = lru_delete($fc, "del_ref");
    is_deeply($deleted, [7, 8, 9], 'delete: returns ref value');
    ok(!lru_exists($fc, "del_ref"), 'delete: key gone');
}

# --- Peek returns ref without promoting ---
{
    my $pc = LRU::Cache::new(10);
    lru_set($pc, "peek_a", "first");
    lru_set($pc, "peek_b", [1, 2]);
    my $peeked = lru_peek($pc, "peek_b");
    is_deeply($peeked, [1, 2], 'peek: returns ref');
    my ($oldest_k) = lru_oldest($pc);
    is($oldest_k, "peek_a", 'peek: did not promote');
}
