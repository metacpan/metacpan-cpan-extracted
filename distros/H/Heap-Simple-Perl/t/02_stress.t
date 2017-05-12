#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02_stress.t'
# use warnings;	# Remove this for production. Assumes perl 5.6
use strict;

BEGIN { $^W = 1 };
use Test::More "no_plan";
use lib "t";
use FakeHeap;

my $wanted_implementor;
BEGIN {
    $wanted_implementor = "Perl";
    @Heap::Simple::implementors = ("Heap::Simple::$wanted_implementor") unless
        @Heap::Simple::implementors;
    use_ok("Heap::Simple");
};
my $class = Heap::Simple->implementation;
if ($class ne "Heap::Simple::$wanted_implementor") {
    diag("Was supposed to test Heap::Simple::$wanted_implementor but loaded $class");
    fail("Wrong heap library got loaded");
    exit 1;
}

my %order2infinity =
    (""  => 9**9**9,
     "<" => 9**9**9,
     ">" => -(9**9**9),
     "gt" => "");

sub wrap {
    my $code = shift;
    my $canary = bless [], "Canary";
    $canary->inc;
    return sub { return $canary && $code->(@_) };
}

my ($fake, $val, $code);
my $unicode = "utf8"->can("is_utf8");
# diag("unicode=$unicode");

my $evil_string = " _ABC()";
if ($unicode) {
    $evil_string .= chr for 1..38,40..512;	# Avoid 0 and '
} else {
    $evil_string .= chr for 1..38,40..255;	# Avoid 0 and '
}

{
    no strict "refs";
    *{"Canary::$evil_string"} = sub {
        shift if $_[0] eq "Canary";
        return 5 * shift->[0];
    };
}
is(Canary->$evil_string([3]), 15, "Succesfully installed function");

is(Canary->count, 0, "Nothing yet");

# Unknown options are noticed
eval { Heap::Simple->new(foo => 5) };
ok($@ =~ /^Unknown option 'foo' at /, "Proper error message: '$@'");
# Missing option argument is noticed
eval { Heap::Simple->new("order") };
ok($@ =~ /^Odd number of elements in options at /,
   "Proper error message: '$@'");
eval { Heap::Simple->new(order => "zap") };
ok($@ =~ /^Unknown order 'zap' at /, "Proper error message: '$@'");
eval { Heap::Simple->new(elements => "zap") };
if ($class eq "Heap::Simple::Perl") {
    ok($@ =~ m!^Can.t locate Heap/Simple/Zap.pm in \@INC !,
       "Proper error message: '$@'");
} else {
    ok($@ =~ /^Unknown element type 'zap' at /, "Proper error message: '$@'");
}
eval { Heap::Simple->new(max_count => -1) };
ok($@ =~ /^max_count should not be negative at /,"Proper error message: '$@'");
# eval { Heap::Simple->new(max_count => 1e50) };
# ok($@ =~ /^max_count too big. Use infinity instead at /,
#    "Proper error message: '$@'");
eval { Heap::Simple->new(max_count => 2.3) };
ok($@ =~ /^max_count should be an integer at /,
   "Proper error message: '$@'");
$fake = Heap::Simple->new(max_count => 9**9**9);
is($fake->max_count, 9**9**9);

# < order
$fake = FakeHeap->new;
is($fake->order, "<");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, 9);
is($fake->extract_top, 11);
is($fake->extract_top, 100);
$fake = FakeHeap->new(order => "<");
is($fake->order, "<");

# > order
$fake = FakeHeap->new(order => ">");
is($fake->order, ">");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, 100);
is($fake->extract_top, 11);
is($fake->extract_top, 9);

# lt order
$fake = FakeHeap->new(order => "lt");
is($fake->order, "lt");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, "A100");
is($fake->extract_top, "A11");
is($fake->extract_top, "A9");
$fake = FakeHeap->new(order => "LT");
is($fake->order, "lt", "Case doesn't matter");

# gt order
$fake = FakeHeap->new(order => "gt");
is($fake->order, "gt");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, "A9");
is($fake->extract_top, "A11");
is($fake->extract_top, "A100");
$fake = FakeHeap->new(order => "GT");
is($fake->order, "gt", "Case doesn't matter");

# Code order
$code = wrap(sub { shift() > shift });
$fake = FakeHeap->new(order => $code);
$val = $fake->order;
is($val, $code);
isa_ok($val, "CODE");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, 100);
is($fake->extract_top, 11);
is($fake->extract_top, 9);

# Scalar types
$fake = FakeHeap->new;
is($fake->elements, "Scalar");
$val = [$fake->elements];
is_deeply($val, ["Scalar"], "Scalar is default");
isa_ok($val, "ARRAY", "elements is not blessed");
bless $val, "Canary";
$val->inc;
ok(!$fake->wrapped, "Not wrapped");
is(() = $fake->wrapped, 0, "wrapped is empty in list context");
$fake->insert(11);
$fake->insert(100, 9);
is($fake->extract_top, 9);
is($fake->extract_top, 11);
is($fake->extract_top, 100);
$fake = FakeHeap->new(order => "lt");
$fake->insert("fo\xcdo");
$fake->insert($evil_string);
$val = $fake->extract_top;
is($val, "A" . $evil_string, "String is preserved");
ok(utf8::is_utf8($val), "String is in utf8") if $unicode;
$val = $fake->extract_top;
is($val, "Afo\xcdo", "String is preserved");
ok(!utf8::is_utf8($val), "String is not in utf8") if $unicode;
$fake = FakeHeap->new(elements => "Scalar");
is_deeply([$fake->elements], ["Scalar"], "explicit scalar");
$fake = FakeHeap->new(elements => "scaLar");
is_deeply([$fake->elements], ["Scalar"], "case doesn't matter");
$fake = FakeHeap->new(elements => ["Scalar"]);
is_deeply([$fake->elements], ["Scalar"], "explicit scalar as array");
$fake = FakeHeap->new(elements => ["scaLar"]);
is_deeply([$fake->elements], ["Scalar"], "case doesn't matter");
$fake = FakeHeap->new(elements => "Key");
is_deeply([$fake->elements], ["Scalar"], "key is an alias for scalar");

# Array types
$fake = FakeHeap->new(elements => "Array");
is($fake->elements, "Array");
is_deeply([$fake->elements], [Array => 0], "array defaults to index 0");
ok(!$fake->wrapped, "Not wrapped");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
isa_ok($val, "Canary");
is_deeply($val, [9]);
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [100]);
$val = undef;
$fake = FakeHeap->new(elements => ["Array"]);
is_deeply([$fake->elements], [Array => 0], "array ref without index");
$fake = FakeHeap->new(elements => [Array => 0]);
is_deeply([$fake->elements], [Array => 0], "array ref with index");
$fake = FakeHeap->new(elements => [Array => 1]);
is_deeply([$fake->elements], [Array => 1], "array ref with index");
$fake = FakeHeap->new(elements => [Array => -1]);
is_deeply([$fake->elements], [Array => -1], "array ref with negative index");

# Hash types
eval { FakeHeap->new(elements => "Hash") };
ok($@ =~ /^missing key name for Hash at /, "Proper error message: $@");
$fake = FakeHeap->new(elements => [Hash => "foo"]);
is($fake->elements, "Hash");
$val = [$fake->elements];
is_deeply($val, [Hash => "foo"], "hash element");
ok(!utf8::is_utf8($val->[1]), "index did not become unicode") if $unicode;
ok(!$fake->wrapped, "Not wrapped");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
isa_ok($val, "Canary");
is_deeply($val, {"foo" => 9});
ok(!utf8::is_utf8((%$val)[0]), "index did not become unicode") if $unicode;
is_deeply($fake->extract_top, {"foo" => 11});
is_deeply($fake->extract_top, {"foo" => 100});

$fake = FakeHeap->new(elements => [Hash => $evil_string]);
is($fake->elements, "Hash");
$val = [$fake->elements];
is_deeply($val, [Hash => $evil_string], "hash element");
ok(utf8::is_utf8($val->[1]), "index is unicode") if $unicode;
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
isa_ok($val, "Canary");
is_deeply($val, {$evil_string => 9});
ok(utf8::is_utf8((%$val)[0]), "index is unicode") if $unicode;
is_deeply($fake->extract_top, {$evil_string => 11});
is_deeply($fake->extract_top, {$evil_string => 100});

# Function type
eval { FakeHeap->new(elements => "Function") };
ok($@ =~ /^missing key function for Function at /, "Proper error message: $@");
$code = wrap(sub { return -2 * shift->[0]});
$fake = FakeHeap->new(elements => [Function => $code]);
is($fake->elements, "Function");
$val = [$fake->elements];
is_deeply($val, [Function => $code], "Code is preserved");
isa_ok($val->[1], "CODE");
ok(!$fake->wrapped, "Not wrapped");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
is_deeply($val, [100]);
isa_ok($val, "Canary");
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [9]);
$code = undef;

# Any type
$fake = FakeHeap->new(elements => "Any");
is($fake->elements, "Any");
is_deeply([$fake->elements], ["Any"], "No Code is needed for Any");
ok($fake->wrapped, "Wrapped");
is_deeply([$fake->wrapped], [1], "wrapped is true in list context too");
eval { $fake->insert(11) };
ok($@ =~ /^Element type 'Any' without key code at /, "But can't insert: $@");
$code = wrap(sub { return -3 * shift->[0]});
$fake = FakeHeap->new(elements => [Any => $code]);
is($fake->elements, "Any");
$val = [$fake->elements];
is_deeply($val, [Any => $code], "Code is preserved");
isa_ok($val->[1], "CODE");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
is_deeply($val, [100]);
isa_ok($val, "Canary");
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [9]);
$code = undef;

# Method type
eval { FakeHeap->new(elements => "Method") };
ok($@ =~ /^missing key method for Method at /, "Proper error message: $@");
$fake = FakeHeap->new(elements => [Method => "meth"]);
is($fake->elements, "Method");
is_deeply([$fake->elements], [Method => "meth"], "method element");
ok(!$fake->wrapped, "Not wrapped");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
is_deeply($val, [100]);
isa_ok($val, "Canary");
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [9]);

$fake = FakeHeap->new(elements => [Method => $evil_string]);
$fake->insert(11);
$fake->insert(100, 9);
is_deeply($fake->extract_top, [9]);
is($fake->top_key, 55);
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [100]);

# Object type
$fake = FakeHeap->new(elements => "Object");
is($fake->elements, "Object");
is_deeply([$fake->elements], ["Object"], "No method is needed for Object");
ok($fake->wrapped, "Wrapped");
eval { $fake->insert(11) };
ok($@ =~ /^Element type 'Object' without key method at /,
   "But can't insert: $@");
$fake = FakeHeap->new(elements => [Object => "meth"]);
is($fake->elements, "Object");
is_deeply([$fake->elements], [Object => "meth"], "method element");
$fake->insert(11);
$fake->insert(100, 9);
$val = $fake->extract_top;
is_deeply($val, [100]);
isa_ok($val, "Canary");
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [9]);

$fake = FakeHeap->new(elements => [Object => $evil_string]);
$fake->insert(11);
$fake->insert(100, 9);
is_deeply($fake->extract_top, [9]);
is($fake->top_key, 55);
is_deeply($fake->extract_top, [11]);
is_deeply($fake->extract_top, [100]);

# Check proper cleanup of already added stuff on a croak
eval { $class->new(infinity => Canary->new(5), order => "waf") };

$fake = undef;
$code = undef;
$val  = undef;
die "\nYou're leaking" if Canary->count;

my ($order, $elements, $dirty, $base_infinity);
for (0, 8) {
    $dirty = $_;
    check_errors();
    for (qw(< > lt gt), sub { shift() > shift }) {
        $order = $_;
        $base_infinity = $order2infinity{$order};
        for (["Scalar"],
             [Array => 1],
             [Hash => "foo"],
             [Function => sub { return $order =~ /t/ ?
                                    "Y$_[0]->[0]" : -2 * shift->[0]}],
             [Any      => sub { return $order =~ /t/ ?
                                    "Z$_[0]->[0]" : -3 * shift->[0]}],
             [Method   => "meth"],
             [Method   => "-'\$f#"],
             [Object   => "meth"],
             [Object   => "-'\$f#"]) {
            $elements = $_;
            check($order ? (order => $order) : (),
                  $elements ? (elements => $elements) : (),
                  dirty => $dirty);



            pass("order: $order, elements: @$elements, dirty: $dirty");
        }
        for (["Any"], ["Object"]) {
            $elements = $_;
            check_keyed($order ? (order => $order) : (),
                        $elements ? (elements => $elements) : (),
                        dirty	=> $dirty);
        }
    }
}

sub check {
    my @options = @_;
    my $val;
    # diag("options=order => $order, elements => [@$elements], dirty => $dirty");
    my $fake = FakeHeap->new(@options,
                             user_data => "xyzzy");
    is($fake->implementation, Heap::Simple->implementation);
    is_deeply([$fake->implementation], [Heap::Simple->implementation]);
    is($fake->max_count, 9**9**9);
    is($fake->count, 0, "Start empty");
    is($fake->dirty, $dirty ? 1 : !1);
    is_deeply([$fake->dirty], [$dirty ? 1 : ()]);
    is($fake->can_die, !1);
    is_deeply([$fake->can_die], []);

    is(() = $fake->values, 0, "There are no values");
    is(() = $fake->keys, 0, "There are no keys");

    is($fake->order, $order || "<", "Expected order");
    is_deeply([$fake->order], [$order || "<"], "Expected order");
    is($fake->elements, ($elements || ["Scalar"])->[0],
       "Expected element type");
    is_deeply([$fake->elements], $elements || ["Scalar"],
              "Expected element type");

    if ($elements->[0] eq "Array") {
        is($fake->key_index, $elements->[1]);
        is_deeply([$fake->key_index], [$elements->[1]]);
    } else {
        eval { $fake->key_index };
        ok($@ =~ /^Heap elements are not of type 'Array' at /,
           "Proper error message: $@");
        eval { () = $fake->key_index };
        ok($@ =~ /^Heap elements are not of type 'Array' at /,
           "Proper error message: $@");
    }

    if ($elements->[0] eq "Hash") {
        is($fake->key_name, $elements->[1]);
        is_deeply([$fake->key_name], [$elements->[1]]);
    } else {
        eval { $fake->key_name };
        ok($@ =~ /^Heap elements are not of type 'Hash' at /,
           "Proper error message: $@");
        eval { () = $fake->key_name };
        ok($@ =~ /^Heap elements are not of type 'Hash' at /,
           "Proper error message: $@");
    }

    if ($elements->[0] eq "Method" || $elements->[0] eq "Object") {
        is($fake->key_method, $elements->[1]);
        is_deeply([$fake->key_method], [$elements->[1]]);
    } else {
        eval { $fake->key_method };
        ok($@ =~ /^Heap elements are not of type 'Method' or 'Object' at /,
           "Proper error message: $@");
        eval { () = $fake->key_method };
        ok($@ =~ /^Heap elements are not of type 'Method' or 'Object' at /,
           "Proper error message: $@");
    }

    if ($elements->[0] eq "Function" || $elements->[0] eq "Any") {
        is($fake->key_function, $elements->[1]);
        is_deeply([$fake->key_function], [$elements->[1]]);
    } else {
        eval { $fake->key_function };
        ok($@ =~ /^Heap elements are not of type 'Function' or 'Any' at /,
           "Proper error message: $@");
        eval { () = $fake->key_function };
        ok($@ =~ /^Heap elements are not of type 'Function' or 'Any' at /,
           "Proper error message: $@");
    }

    is($fake->infinity, $base_infinity, "proper infinity");
    is_deeply([$fake->infinity], [$base_infinity], "proper infinity");
    $fake->insert(qw(12 2 -12 0 13 -1 -2 1 12));
    is($fake->count, 9, "Count is number of inserts");
    () = $fake->count;
    $fake->values;
    my @values = $fake->values;
    is(@values, 9, "There are 9 values");
    $fake->keys;
    my @keys = $fake->keys;
    is(@keys, 9, "There are 9 keys");
    is_deeply([map $fake->key($_), @values], \@keys,
              "keys and values have compatible order");
    is($fake->extract_top, shift @values);
    () = $fake->extract_top;
    $fake->extract_min;
    () = $fake->extract_min;
    $fake->extract_first;
    () = $fake->extract_first;
    is($fake->count, 3, "Count lowered by extracts");
    $fake->extract_top for 1..$fake->count;
    die "Heap should have been empty" if $fake->count;
    $fake->insert(3);
    $val = $fake->top_key;
    $fake->insert($_) for 1..5;
    () = $fake->extract_upto($val);
    is($fake->count, 2, "2 values left");
    $fake->clear;
    is ($fake->count, 0, "Empty after clear");
    $fake->clear;
    is ($fake->count, 0, "Double clear works");
    $fake->insert(int rand 10) for 1..8;
    () = $fake->extract_all;
    is ($fake->count, 0, "Empty after extract_all");

    # Some tests on an empty heap
    die "Heap should have been empty" if $fake->count;
    eval { $fake->extract_top };
    ok($@ =~ /^Empty heap at /, "extract_top on empty heap dies");
    () = eval { $fake->extract_top };
    ok($@ =~ /^Empty heap at /, "extract_top on empty heap dies");

    eval { $fake->extract_min };
    ok($@ =~ /^Empty heap at /, "extract_min on empty heap dies");
    () = eval { $fake->extract_min };
    ok($@ =~ /^Empty heap at /, "extract_min on empty heap dies");

    is($fake->extract_first, undef, "extract first on empty returns undef");
    is(() = $fake->extract_first, 0,
       "extract first on empty returns no values");

    eval { $fake->top };
    ok($@ =~ /^Empty heap at /, "top on empty heap dies");
    () = eval { $fake->top };
    ok($@ =~ /^Empty heap at /, "top on empty heap dies");
    is($fake->first, undef, "undefined first on empty heap");
    if ($class eq "Heap::Simple::Perl") {
        is_deeply([$fake->first], [undef], "Undef first key in list context");
    } else {
        is(() = $fake->first, 0, "No first key in list context");
    }

    if (defined($base_infinity)) {
        is($fake->top_key, $base_infinity, "Return infinity on empty");
        is_deeply([$fake->top_key], [$base_infinity],
                  "Return infinity on empty in list context");
        is($fake->min_key, $base_infinity, "Return infinity on empty");
        is_deeply([$fake->min_key], [$base_infinity],
                  "Return infinity on empty in list context");
    } else {
        eval { $fake->top_key };
        ok($@ =~ /^Empty heap at /, "Proper error message: $@");
        eval { () = $fake->top_key };
        ok($@ =~ /^Empty heap at /, "Proper error message: $@");
        eval { $fake->min_key };
        ok($@ =~ /^Empty heap at /, "Proper error message: $@");
        eval { () = $fake->min_key };
        ok($@ =~ /^Empty heap at /, "Proper error message: $@");
    }
    is($fake->first_key, undef, "undef first_key");
    if ($class eq "Heap::Simple::Perl") {
        is_deeply([$fake->first_key], [undef],
                  "Undef from first_key in list context");
    } else {
        is(() = $fake->first_key, 0, "Empty list from first_key");
    }

    is(() = $fake->values, 0, "There are no values");
    is(() = $fake->keys,   0, "There are no keys");
    is(() = $fake->extract_all, 0, "There are no values");

    # $fake should be empty at this point
    die "Heap should have been empty" if $fake->count;
    my $in = -12;
    $fake->insert($in);
    $in = "A$in" if $order =~ /t/;

    $val = $fake->top;

    if ($elements->[0] eq "Scalar") {
        is($val, $in, "Scalar is simple");
        ok(!$fake->wrapped, "Scalars aren't wrapped");
        is(()=$fake->wrapped, 0, "Scalars aren't wrapped");
    } else {
        isa_ok($val, "Canary");
        if ($elements->[0] eq "Array") {
            my @a;
            $a[$elements->[1]] = $in;
            is_deeply($val, \@a);
            if ($class ne "Heap::Simple::Perl" && 
                $dirty && ($order eq "<" || $order eq ">")) {
                ok($fake->wrapped, "dirty Arrays can be wrapped");
                is_deeply([$fake->wrapped], [1], 
                          "dirty Arrays can be wrapped");
            } else {
                ok(!$fake->wrapped, "Arrays aren't wrapped");
                is(()=$fake->wrapped, 0, "Arrays aren't wrapped");
            }
        } elsif ($elements->[0] eq "Hash") {
            is_deeply($val, { $elements->[1] => $in});
            if ($class ne "Heap::Simple::Perl" && 
                $dirty && ($order eq "<" || $order eq ">")) {
                ok($fake->wrapped, "dirty Hashes can be wrapped");
                is_deeply([$fake->wrapped], [1], 
                          "dirty Hashes can be wrapped");
            } else {
                ok(!$fake->wrapped, "Hashes aren't wrapped");
                is(()=$fake->wrapped, 0, "Hashes aren't wrapped");
            }
        } elsif ($elements->[0] eq "Function" || $elements->[0] eq "Method") {
            is_deeply($val, [$in]);
            ok(!$fake->wrapped, "Functions/Methods aren't wrapped");
            is(()=$fake->wrapped, 0, "Functions/Methods aren't wrapped");
        } elsif ($elements->[0] eq "Any" || $elements->[0] eq "Object") {
            is_deeply($val, [$in]);
            ok($fake->wrapped, "Any/Objects aren't wrapped");
            is_deeply([$fake->wrapped], [1], "Any/Objects aren't wrapped");
        } else {
            die "Element type '$elements->[0]' not handled yet";
        }
    }
    my $wrapped = $fake->wrapped;

    is_deeply([$fake->top], [$val]);
    is_deeply($fake->first, $val);
    is_deeply([$fake->first], [$val]);
    is_deeply([$fake->values], [$val]);

    if ($order =~ /t/) {
        $in = "Y$in" if $elements->[0] eq "Function";
        $in = "Z$in" if $elements->[0] eq "Any";
    } else {
        $in *= -2 if $elements->[0] eq "Function";
        $in *= -3 if $elements->[0] eq "Any";
    }
    $in = -$in if $elements->[0] eq "Method" || $elements->[0] eq "Object";

    is($fake->key($val), $in, "Use value itself as key");
    is_deeply([$fake->key($val)], [$in], "Use value itself as key");
    is($fake->top_key,   $in, "Is also the effective key");
    is_deeply([$fake->top_key],   [$in], "Is also the effective key");
    is($fake->min_key,   $in, "Is also the effective key");
    is_deeply([$fake->min_key],   [$in], "Is also the effective key");
    is($fake->first_key, $in, "Is also the effective key");
    is_deeply([$fake->first_key], [$in], "Is also the effective key");
    is_deeply([$fake->keys], [$in], "Is also the effective key");

    is_deeply($fake->extract_top, $val);
    die "Heap should have been empty" if $fake->count;
    $fake->insert(-12);
    is_deeply([$fake->extract_top], [$val]);
    $fake->insert(-12);
    is_deeply($fake->extract_min, $val);
    $fake->insert(-12);
    is_deeply([$fake->extract_min], [$val]);
    $fake->insert(-12);
    is_deeply($fake->extract_first, $val);
    $fake->insert(-12);
    is_deeply([$fake->extract_first], [$val]);

    # insert_key
    die "Heap should have been empty" if $fake->count;
    if ($wrapped) {
        $fake->key_insert(-$_, $_) for qw(12 2 -12 0 13 -1 -2 1 12);
        is($fake->count, 9, "Have all new values");
        @values = $fake->values;
        @keys   = $fake->keys;
        is_deeply($fake->top,     $values[0]);
        is_deeply($fake->top_key, $keys[0]);
        $fake->extract_top for 1..9;
        is($fake->count, 0, "Empty again");
        $fake->key_insert(-3, 8);
        is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
        $fake->clear;

        $fake->key_insert(map {-$_, $_} qw(12 2 -12 0 13 -1 -2 1 12));
        is($fake->count, 9, "Have all new values");
        @values = $fake->values;
        @keys   = $fake->keys;
        is_deeply($fake->top,     $values[0]);
        is_deeply($fake->top_key, $keys[0]);
        $fake->extract_top for 1..9;
        is($fake->count, 0, "Empty again");
        $fake->key_insert(-3, 8);
        is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
        $fake->clear;

        $fake->_key_insert([-$_, $_]) for qw(12 2 -12 0 13 -1 -2 1 12);
        is($fake->count, 9, "Have all new values");
        @values = $fake->values;
        @keys   = $fake->keys;
        is_deeply($fake->top,     $values[0]);
        is_deeply($fake->top_key, $keys[0]);
        $fake->extract_top for 1..9;
        is($fake->count, 0, "Empty again");
        $fake->_key_insert([-3, 8]);
        is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
        $fake->clear;

        $fake->_key_insert(map [-$_, $_], qw(12 2 -12 0 13 -1 -2 1 12));
        is($fake->count, 9, "Have all new values");
        @values = $fake->values;
        @keys   = $fake->keys;
        is_deeply($fake->top,     $values[0]);
        is_deeply($fake->top_key, $keys[0]);
        $fake->extract_top for 1..9;
        is($fake->count, 0, "Empty again");
        $fake->_key_insert([-3, 8]);
        is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
        $fake->clear;
    } else {
        eval { $fake->key_insert(-3, 8) };
        ok($@ =~ /^This heap type does not support key_insert at /,
           "Proper error message: $@");
        eval { () = $fake->key_insert(-3, 8) };
        ok($@ =~ /^This heap type does not support key_insert at /,
           "Proper error message: $@");
        Canary->inc;
        eval { $fake->_key_insert(bless [-3, 8], "Canary") };
        ok($@ =~ /^This heap type does not support _key_insert at /,
           "Proper error message: $@");
        Canary->inc;
        eval { () = $fake->_key_insert(bless [-3, 8], "Canary") };
        ok($@ =~ /^This heap type does not support _key_insert at /,
           "Proper error message: $@");
    }

    # user_data
    is($fake->user_data, "xyzzy", "user_data survived everything");
    is_deeply([$fake->user_data], ["xyzzy"], "user_data in list context too");
    is_deeply([$fake->user_data(Canary->new("zzz"))], ["xyzzy"],
              "Combined get/set");
    $val = $fake->user_data;
    is_deeply($val, ["zzz"]);
    isa_ok($val, "Canary");
    is_deeply([$fake->user_data], [$val]);
    $fake->user_data($evil_string);
    is($fake->user_data, $evil_string);
    () = $fake->user_data(undef);
    is($fake->user_data, undef);
    is_deeply([$fake->user_data], [undef]);
    $fake->user_data(Canary->new("zzz"));

    # infinity
    is($fake->infinity, $base_infinity, "infinity survived everything");
    is_deeply([$fake->infinity], [$base_infinity],
              "infinity in list context too");
    is_deeply([$fake->infinity(Canary->new("ii"))], [$base_infinity],
              "Combined get/set");
    $val = $fake->infinity;
    is_deeply($val, ["ii"]);
    isa_ok($val, "Canary");
    is_deeply([$fake->infinity], [$val]);
    $fake->infinity($evil_string);
    is($fake->infinity, $evil_string);
    () = $fake->infinity(undef);
    is($fake->infinity, undef);
    is_deeply([$fake->infinity], [undef]);

    $fake = FakeHeap->new(@options,
                          infinity => Canary->new("iiii"),
                          can_die => 9);
    is($fake->can_die, 1);
    is_deeply([$fake->can_die], [1]);
    is($fake->user_data, undef, "Default userdata is undef");
    is_deeply([$fake->user_data], [undef], "Default userdata is undef");

    $val = $fake->infinity;
    is_deeply($val, ["iiii"], "return set infinity");
    isa_ok($val, "Canary");
    @values = $fake->infinity;
    is_deeply(\@values, [["iiii"]], "return set infinity, even in list context");
    isa_ok($values[0], "Canary");

    $val = $fake->top_key;
    is_deeply($val, ["iiii"], "top_key on empty heap returns set infinity");
    isa_ok($val, "Canary");
    @values = $fake->top_key;
    is_deeply(\@values, [["iiii"]], "top_key on empty heap returns set infinity, even in list context");
    isa_ok($values[0], "Canary");

    $val = $fake->min_key;
    is_deeply($val, ["iiii"], "min_key on empty heap returns set infinity");
    isa_ok($val, "Canary");
    @values = $fake->min_key;
    is_deeply(\@values, [["iiii"]], "min_key on empty heap returns set infinity, even in list context");
    isa_ok($values[0], "Canary");

    # merge_array
    $fake->merge_arrays([1, 2], [3, 4], [5, 6]);
    $fake->merge_arrays([1, 2, 5], [3, 4, 6]);
    $fake->merge_arrays();
    $fake->merge_arrays([1, 2, 3, 4, 5, 6, 7]);
    $fake->merge_arrays([], [1, 2, 3, 4, 5, 6, 7]);
    $fake->merge_arrays(map [map int rand 10, 1..rand 10], 1..rand 6);

    # Some major inserts and deletes
    $fake->insert(rand) for 1..100;
    $fake->extract_top for 1..50;
    $fake->insert(map rand, 1..100);
    if ($wrapped) {
        $fake->extract_top for 1..150;
        $fake->key_insert(rand, rand) for 1..100;
        $fake->extract_top for 1..50;
        $fake->key_insert(map {rand, rand} 1..100);

        $fake->extract_top for 1..150;
        $fake->_key_insert([rand, rand]) for 1..100;
        $fake->extract_top for 1..50;
        $fake->_key_insert(map [rand, rand], 1..100);
    }

    if ($class ne "Heap::Simple::Perl") {
        $fake = FakeHeap->new(@options,
                              max_count => 0,
                              user_data => 8,
                              infinity  => 9,
                              can_die => 0,
                              );
        is($fake->max_count, 0);
        $fake->insert(Canary->new(8));
        is($fake->count, 0);
        is($fake->can_die, !1);
        is_deeply([$fake->can_die], []);
    } else {
        $fake = FakeHeap->new(@options,
                              max_count => 1,
                              user_data => 8,
                              infinity  => 9,
                              can_die => 0,
                              );
        is($fake->max_count, 1);
        $fake->insert(Canary->new(8));
        is($fake->count, 1);
        is($fake->can_die, !1);
        is_deeply([$fake->can_die], []);
    }

    my $fake1 = FakeHeap->new(@options,
                              max_count => 9);
    $fake1->insert($_) for 9, -3, 2, 7;
    my $fake2 = FakeHeap->new(@options);
    $fake2->insert(6, 3, 8, -1);
    my $fake3 = FakeHeap->new(@options);
    $fake3->insert($_) for 14, 12, -7, 3;
    $fake1->absorb($fake2, $fake3);
    is($fake2->count, 0);
    is($fake3->count, 0);
    is($fake1->count, 9);
    eval {
        my $heap = $fake1->heap;
        $heap->absorb($heap);
    };
    ok($@ =~ /^Self absorption at /, "proper error message: $@");

    $fake3 = FakeHeap->new();
    eval { $fake1->_key_absorb($fake3) };
    ok($@ =~ /^This heap type does not support _?key_insert at /,
       "Proper error message: $@");
    $fake3 = undef;

    if ($wrapped) {
        $fake2->key_absorb($fake1);
        is($fake1->count, 0);
        is($fake2->count, 9);
    } else {
        my $heap = Heap::Simple->new(order => $order, elements => "Any");
        $heap->key_insert(5, 8);
        eval { $fake1->key_absorb($heap) };
        ok($@ =~ /^This heap type does not support _?key_insert at /,
           "proper error message: $@");
        $heap->key_absorb($fake1);
        is($fake1->count, 0);
        is($heap->count, 10);
    }
    $fake1 = FakeHeap->new(@options, max_count => 7);
    $fake1->insert($_) for 9, -3, 2, 7;
    $fake2 = FakeHeap->new(@options);
    $fake2->insert(6, 3, 8, -1);
    $fake1->heap->absorb($fake2->heap);
    is($fake1->heap->count, 7);
    is($fake2->heap->count, 0);
    if ($wrapped) {
        $fake1 = FakeHeap->new(@options, max_count => 7);
        $fake1->key_insert(-$_, $_) for 9, -3, 2, 7;
        $fake2 = FakeHeap->new(@options);
        $fake2->key_insert(map {-$_, $_} 6, 3, 8, -1);
        $fake1->heap->key_absorb($fake2->heap);
        is($fake1->heap->count, 7);
        is($fake2->heap->count, 0);
    }

    $fake = FakeHeap->new(@options,
                          max_count => 3,
                          user_data => 8,
                          infinity  => 9,
                          can_die   => Canary->new(6));
    is($fake->max_count, 3);
    is($fake->can_die, 1);
    is_deeply([$fake->can_die], [1]);
    is($fake->user_data, 8);
    is($fake->infinity,  9);
    $fake->insert($_) for qw(12 2 -12 0 13 -1 -2 1 12);
    is($fake->count, 3);
    @values = $fake->values;
    is(@values, 3);
    $fake->extract_top;
    is($fake->count, 2);
    @values = $fake->values;
    is(@values, 2);
    $fake->insert(qw(12 2));
    is($fake->count, 3);

    # merge_array
    $fake->merge_arrays([1, 2], [3, 4], [5, 6]);
    $fake->merge_arrays([1, 2, 5], [3, 4, 6]);
    $fake->merge_arrays();
    $fake->merge_arrays([1, 2, 3, 4, 5, 6, 7]);
    $fake->merge_arrays([], [1, 2, 3, 4, 5, 6, 7]);
    $fake->merge_arrays(map [map int rand 10, 1..rand 10], 1..rand 6);

    $fake = FakeHeap->new(@options,
                          max_count => 4);
    $fake->insert(-12, 8);
    () = $fake->keys;
    () = $fake->values;
    $fake->insert(-13, 1, 9, -14, 6, 10, -15, 7, 11);
    () = $fake->keys;
    () = $fake->values;
    if ($wrapped) {
        $fake->clear;
        $fake2->key_insert(map {-$_, $_} -12, 8);
        () = $fake->keys;
        () = $fake->values;
        $fake->key_insert(map {-$_, $_} -13, 1, 9, -14, 6, 10, -15, 7, 11);
        () = $fake->keys;
        () = $fake->values;

        $fake->clear;
        $fake2->_key_insert(map [-$_, $_], -12, 8);
        () = $fake->keys;
        () = $fake->values;
        $fake->_key_insert(map [-$_, $_], -13, 1, 9, -14, 6, 10, -15, 7, 11);
        () = $fake->keys;
        () = $fake->values;
    }

    $fake->insert(-12);
    # $fake should be non-empty at this point so we test values cleanup too
    $fake = $fake1 = $fake2 = $val = undef;
    @keys = @values = ();
    die "You're leaking (options=order => $order, elements => [@$elements], dirty => $dirty)" if Canary->count;
}

sub check_keyed {
    # These should only allow key_insert/_key_insert
    my @options = @_;

    my $fake = FakeHeap->new(@options,
                             user_data	=> "qrn");
    if (@$elements < 2) {
        eval { $fake->insert(3) };
        ok($@ =~ /^Element type '\Q$elements->[0]\E' without key \w+ at /,
           "Proper error message: $@");
        eval { () = $fake->insert(3) };
        ok($@ =~ /^Element type '\Q$elements->[0]\E' without key \w+ at /,
           "Proper error message: $@");
    }

    $fake->key_insert(-$_, $_) for qw(12 2 -12 0 13 -1 -2 1 12);
    is($fake->count, 9, "Have all new values");
    my @values = $fake->values;
    my @keys   = $fake->keys;
    is_deeply($fake->top,     $values[0]);
    is_deeply($fake->top_key, $keys[0]);
    $fake->extract_top for 1..9;
    is($fake->count, 0, "Empty again");
    $fake->key_insert(-3, 8);
    is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
    $fake->clear;

    for (qw(12 2 -12 0 13 -1 -2 1 12)) {
        Canary->inc;
        $fake->_key_insert(bless [-$_, $_], "Canary");
    }
    is($fake->count, 9, "Have all new values");
    @values = $fake->values;
    @keys   = $fake->keys;
    is_deeply($fake->top,     $values[0]);
    is_deeply($fake->top_key, $keys[0]);
    $fake->extract_top for 1..9;
    is($fake->count, 0, "Empty again");
    $fake->_key_insert([-3, 8]);
    is($fake->top_key, $order =~ /t/ ? "A-3" : -3);
    $fake->clear;

    if ($class ne "Heap::Simple::Perl") {
        $fake = FakeHeap->new(@options,
                              max_count => 0,
                              user_data => 8,
                              infinity  => 9);
        is($fake->max_count, 0);
        $fake->key_insert(Canary->new(8), Canary->new(9));
        is($fake->count, 0);
        Canary->inc;
        $fake->_key_insert(bless [Canary->new(8),
                                  Canary->new(9)], "Canary");
        is($fake->count, 0);
    } else {
        $fake = FakeHeap->new(@options,
                              max_count => 1,
                              user_data => 8,
                              infinity  => 9);
        is($fake->max_count, 1);
        $fake->key_insert(Canary->new(8), Canary->new(9));
        is($fake->count, 1);
        Canary->inc;
        $fake->_key_insert(bless [Canary->new(8),
                                  Canary->new(9)], "Canary");
        is($fake->count, 1);
    }

    $fake = FakeHeap->new(@options,
                          max_count => 3,
                          user_data => 8,
                          infinity  => 9);
    is($fake->max_count, 3);
    is($fake->user_data, 8);
    is($fake->infinity,  9);
    $fake->key_insert(-$_, $_) for qw(12 2 -12 0 13 -1 -2 1 12);
    is($fake->count, 3);
    @values = $fake->values;
    is(@values, 3);
    $fake->extract_top;
    is($fake->count, 2);
    @values = $fake->values;
    is(@values, 2);
    $fake->key_insert(map {-$_, $_} qw(12 2));
    is($fake->count, 3);

    $fake->clear;
    is($fake->user_data, 8);
    is($fake->infinity,  9);
    for (qw(12 2 -12 0 13 -1 -2 1 12)) {
        Canary->inc;
        $fake->_key_insert(bless [-$_, $_], "Canary");
    }
    is($fake->count, 3);
    @values = $fake->values;
    is(@values, 3);
    $fake->extract_top;
    is($fake->count, 2);
    @values = $fake->values;
    is(@values, 2);
    $fake->_key_insert(map [-$_, $_], qw(12 2));
    is($fake->count, 3);

    $fake->clear;
    $fake->key_insert(Canary->new(8), Canary->new(9));
    $fake->_key_insert([Canary->new(8), Canary->new(9)]);
    is($fake->count, 2);
    @values = @keys = ();
    $fake = undef;
    die "You're leaking options=order => $order, elements => [@$elements]"
        if Canary->count;
}

sub heapy {
    my $n = 1;
    for (0..$#_) {
        return 1 if $n >= @_;
        $_[$_] < $_[$n++] || return 0;
        return 1 if $n >= @_;
        $_[$_] < $_[$n++] || return 0;
    }
    return 1;
}

sub check_errors {
    my $i = 0;
    while (1) {
        my $n = ++$i;
        my $heap = Heap::Simple->new(order => sub {
            --$n || die "Wam";
            return shift() < shift },
                               elements => "Array",
                               can_die => 1,
                               dirty => $dirty);
        my $j = 0;
        # The strange 0-$j is for perl5.6.1 which otherwise passes -0
        eval { $heap->insert(Canary->new(0-$j)), $j++, while $j < 15 };
        is($heap->count, $j);
        my @v = map $_->[0], $heap->values;
        ok(heapy(@v), "Is a heap: @v");
        is_deeply([$heap->keys], \@v);
        is_deeply([sort {$a <=> $b } @v], [1-$j..0]);
        die "Keep failing" if $i >= 100;
        last unless $@;
        ok($@ =~ /^Wam at /, "Died properly: $@");
    }
    die "Too few failures: $i" if $i < 15;

    $i = 0;
    while (1) {
        my $n = ++$i;
        my $heap = Heap::Simple->new(order    => "<",
                               elements => [Function => sub {
                                   --$n || die "Wam"; return 2*shift->[0] }],
                               can_die => 1,
                               dirty => $dirty);
        my $j = 0;
        # The strange 0-$j is for perl5.6.1 which otherwise passes -0
        eval { $heap->insert(Canary->new(0-$j)), $j++ while $j < 15 };
        $n = 0;
        is($heap->count, $j);
        my @v = map $_->[0], $heap->values;
        ok(heapy(@v), "Is a heap: @v");
        is_deeply([$heap->keys], [map $_*2, @v]);
        is_deeply([sort {$a <=> $b } @v], [1-$j..0]);
        die "Keep failing" if $i >= 100;
        last unless $@;
        ok($@ =~ /^Wam at /, "Died properly: $@");
    }
    die "Too few failures: $i" if $i < 15;

    $i = 0;
    while (1) {
        my $n = ++$i;
        my $heap = Heap::Simple->new(order    => sub {
            --$n || die "Wam";
            return shift->[0] < shift->[0] },
                               elements => "Any",
                               can_die => 1,
                               dirty => $dirty);
        my $j = 0;
        # The strange 0-$j is for perl5.6.1 which otherwise passes -0
        eval { $heap->key_insert(Canary->new(0-$j), 
                                 Canary->new($j)), $j++ while $j < 15 };
        is($heap->count, $j);
        # The strange 0- is for perl5.6.1 which otherwise passes -0
        my @v = map 0-$_->[0], $heap->values;
        ok(heapy(@v), "Is a heap: @v");
        is_deeply([map $_->[0], $heap->keys], \@v);
        is_deeply([sort {$a <=> $b } @v], [1-$j..0]);
        die "Keep failing" if $i >= 100;
        last unless $@;
        ok($@ =~ /^Wam at /, "Died properly: $@");
    }
    die "Too few failures: $i" if $i < 15;

    $i = 0;
    while (1) {
        my $n = ++$i;
        my $order = sub { --$n || die "Wam"; return shift->[0] < shift->[0] };
        my $heap = Heap::Simple->new(order    => $order,
                               elements => "Any",
                               can_die => 1,
                               dirty => $dirty);
        my $j = 0;
        eval {
            while ($j < 15) {
                Canary->inc;
                # The strange 0-$j is for perl5.6.1 which otherwise passes -0
                $heap->_key_insert(bless [Canary->new(0-$j), Canary->new($j)], "Canary");
                $j++;
            }
        };
        is($heap->count, $j);
        # The strange 0-$j is for perl5.6.1 which otherwise passes -0
        my @v = map 0-$_->[0], $heap->values;
        ok(heapy(@v), "Is a heap: @v");
        is_deeply([map $_->[0], $heap->keys], \@v);
        is_deeply([sort {$a <=> $b } @v], [1-$j..0]);
        die "Keep failing" if $i >= 100;
        last unless $@;
        ok($@ =~ /^Wam at /, "Died properly: $@");
    }
    die "Too few failures: $i" if $i < 15;

    for my $p (7..14) {
        # Construct the heap shape we want to test on
        # (with a specific percolation path)
        my $n = 3;
        my $j = $p;
        my @v = (10) x 15;
        while ($j >= 0) {
            $v[$j] = $n--;
            $j = (($j+1) >> 1)-1;
        }
        $n = 4;
        for (@v) {
            $_ = $n++ if $_ == 10;
        }

        my $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order => sub {
                --$n || die "Wam";
                return shift() < shift },
                                   elements => "Array",
                                   can_die => 1,
                                   dirty => $dirty);
            $heap->insert(Canary->new($_)) for @v;
            my @o = map $_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->extract_top };
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
            $n = 0;
            is($heap->count, 15);
            @o = map $_->[0], $heap->values;
            is_deeply(\@o, \@v);
            is_deeply([$heap->keys], \@v);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;

        $i = 0;
        while (1) {
            my $n = 0;
            my $order = sub { --$n || die "Wam"; return shift() < shift };
            my $heap = Heap::Simple->new(order => "<",
                                   elements => [Function => sub {
                                       --$n || die "Wam";
                                       return 2*shift->[0] }],
                                   can_die => 1,
                                   dirty => $dirty);
            $heap->insert(Canary->new($_)) for @v;
            my @o = map $_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->extract_top };
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
            $n = 0;
            is($heap->count, 15);
            @o = map $_->[0], $heap->values;
            is_deeply(\@o, \@v);
            is_deeply([$heap->keys], [map $_*2, @v]);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 6;

        $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order => sub {
                --$n || die "Wam";
                return shift->[0] < shift->[0] },
                                   elements => "Any",
                                   can_die => 1,
                                   dirty => $dirty);
            $heap->key_insert(Canary->new($_), Canary->new(-$_)) for @v;
            my @o = map -$_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->extract_top };
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
            $n = 0;
            is($heap->count, 15);
            @o = map -$_->[0], $heap->values;
            is_deeply(\@o, \@v);
            is_deeply([map $_->[0], $heap->keys], \@v);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;

        # extract testing done. Now make one space
        next if $p == 14;
        pop @v;

        $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order	=> sub {
                --$n || die "Wam";
                return shift() < shift },
                                   elements	=> "Array",
                                   can_die	=> 1,
                                   dirty	=> $dirty,
                                   max_count	=> scalar @v);
            $heap->insert(Canary->new($_)) for @v;
            my @o = map $_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->insert(Canary->new(3.5)) };
            $n = 0;
            @o = map $_->[0], $heap->values;
            is($heap->count, 14);
            if (!$@) {
                is($o[$p], 3.5);
                last;
            }
            ok($@ =~ /^Wam at /, "Died properly: $@");
            is_deeply(\@o, \@v);
            is_deeply([$heap->keys], \@v);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;

        $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order => "<",
                                   elements	=> [Function => => sub {
                                       --$n || die "Wam"; return 2*shift->[0] }],
                                   can_die	=> 1,
                                   dirty	=> $dirty,
                                   max_count	=> scalar @v);
            $heap->insert(Canary->new($_)) for @v;
            my @o = map $_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->insert(Canary->new(3.5)) };
            $n = 0;
            @o = map $_->[0], $heap->values;
            is($heap->count, 14);
            if (!$@) {
                is($o[$p], 3.5);
                last;
            }
            ok($@ =~ /^Wam at /, "Died properly: $@");
            is_deeply(\@o, \@v);
            is_deeply([$heap->keys], [map $_*2, @v]);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;

        $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order	=> sub {
                --$n || die "Wam";
                return shift->[0] < shift->[0] },
                                   elements	=> "Any",
                                   can_die	=> 1,
                                   dirty	=> $dirty,
                                   max_count	=> scalar @v);
            $heap->key_insert(Canary->new($_), Canary->new(-$_)) for @v;
            my @o = map -$_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval { $heap->key_insert(Canary->new(3.5), Canary->new(-100)) };
            $n = 0;
            @o = map -$_->[0], $heap->values;
            is($heap->count, 14);
            if (!$@) {
                is($o[$p], 100);
                last;
            }
            ok($@ =~ /^Wam at /, "Died properly: $@");
            is_deeply(\@o, \@v);
            is_deeply([map $_->[0], $heap->keys], \@v);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;

        $i = 0;
        while (1) {
            my $n = 0;
            my $heap = Heap::Simple->new(order	=> sub {
                --$n || die "Wam";
                return shift->[0] < shift->[0] },
                                   elements	=> "Any",
                                   can_die	=> 1,
                                   dirty	=> $dirty,
                                   max_count	=> scalar @v);
            $heap->key_insert(Canary->new($_), Canary->new(-$_)) for @v;
            my @o = map -$_->[0], $heap->values;
            "@v" eq "@o" || die "Failed to seed heap correctly: '@v' vs '@o'";

            $n = ++$i;
            eval {
                Canary->inc;
                $heap->_key_insert(bless[Canary->new(3.5), Canary->new(-100)], "Canary");
            };
            $n = 0;
            @o = map -$_->[0], $heap->values;
            is($heap->count, 14);
            if (!$@) {
                is($o[$p], 100);
                last;
            }
            ok($@ =~ /^Wam at /, "Died properly: $@");
            is_deeply(\@o, \@v);
            is_deeply([map $_->[0], $heap->keys], \@v);
            die "Keep failing" if $i >= 100;
            last unless $@;
            ok($@ =~ /^Wam at /, "Died properly: $@");
        }
        die "Too few failures: $i" if $i < 5;
    }

    # Check that nothing gets lost on a partial absorb
    my $heap1 = Heap::Simple->new(order => sub { die "Waf1" },
                                  can_die => 1,
                                  dirty => $dirty,
                                  elements => "Any");
    my $n2 = 0;
    my $heap2 = Heap::Simple->new(order => sub {
        --$n2 || die "Waf2"; shift->[0] < shift->[0] },
                            elements => "Any",
                            dirty => $dirty);
    $heap2->key_insert(Canary->new(5), Canary->new(-5));
    $heap2->key_insert(Canary->new(6), Canary->new(-6));
    eval { $heap1->key_absorb($heap2) };
    ok($@ =~ /^Waf1 at/, "Proper error message $@");
    is($heap1->count, 1);
    is($heap2->count, 1);

    $heap1 = $heap2 = undef;
    die "You're leaking (dirty => $dirty)" if Canary->count;
}
