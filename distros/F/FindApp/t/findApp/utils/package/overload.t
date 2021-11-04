#!/usr/bin/env perl

# There's some redundancy here due to writing the various
# tests at different times, but I figure that's ok because
# overloaded operators are so easy to mess up that I don't
# mind the duplication.

use t::setup;

use FindApp::Utils qw(
    blessed
    function 
);

my $Module; BEGIN {
   $Module = "FindApp::Utils::Package::Object";
   use_ok($Module) || die;
}

sub equals_tests {
    my $ob1 = $Module->new("A::B::C");
    my $ob2 = $Module->new(<A  B  C>);

    cmp_ok $ob1, "!=", $ob2,    "two objects have different identities";
    cmp_ok $ob1, "eq", $ob2,    "two objects have equal contents";
}

sub op_nummify_tests {
    my $ob1 = $Module->new("A::B::C");
    my $ob2 = $Module->new(<A  B  C>);

    cmp_ok 0+$ob1, "==", 3,             "first object has three elements to start with ($ob1)";
    cmp_ok 0+$ob2, "==", 3,             "second object has three elements to start with ($ob2)";

    cmp_ok 0+$ob1, "==", 0+$ob2,        "0+ob1 == 0+ob2";
    cmp_ok $ob1+0, "==", 0+$ob2,        "ob1+0 == 0+ob2";
    cmp_ok 0+$ob1, "==", $ob2+0,        "0+ob1 == ob2+0";
    cmp_ok $ob1+0, "==", $ob2+0,        "ob1+0 == ob2+0";

    my $num = sprintf "%d", $ob1;
    is $num, 3,                         "sprintf(%d, $ob1) is 3";
}

sub op_plus_tests {
    my $ob1 = $Module->new("A::B::C");
    my $ob2 = $Module->new(<A  B  C>);

    my $ob3 = $ob1 + "D";
    is $ob3, "A::B::C::D",      "A::B::C + D = A::B::C::D";

    cmp_ok 0+$ob3, "==", 4,     "$ob3 has four elements";

    $ob3 += "E";
    is $ob3, "A::B::C::D::E",   "A::B::C::D + E = A::B::C::D::E";
    cmp_ok 0+$ob3, "==", 5,     "$ob3 has five elements";

    cmp_ok 0+$ob2, "==", 3,     "$ob2 has three elements to start with";
    $ob2 += "D::E";
    cmp_ok 0+$ob2, "==", 5,     "$ob2 now has five elements after += D::E";
}

sub op_minus_tests {
    my $ob1 = $Module->new("A::B::C");
    my $ob2 = $Module->new(<A  B  C>);

    is $ob2-1, "A::B",          "A::B::C - 1 = A::B";
    is $ob2, "A::B::C",         "ob2 still A::B::C (not changed by regular minus)";
    is 0+($ob2-1), 2,           "0 + (A::B::C - 1) is 2";
    is $ob2, "A::B::C",         "ob2 still A::B::C (again unchanged by regular minus)";

    $ob2--;
    is $ob2, "A::B",            "A::B::C-- = A::B";

    $ob2--;
    is $ob2, "A",               "A::B-- = A";

    $ob2--;
    is $ob2, "main",            "A-- = main";

    $ob2 += $ob1;
    is $ob2, "A::B::C",         "main += A::B::C = A::B::C";

    $ob2 -= 2;
    is $ob2, "A",               "A::B::C -= 2 == A";
}

sub comparison_op_tests {
    my $ob0 = $Module->new(<AB        >);
    my $ob1 = $Module->new(<AB  CD  EF>);
    my $ob2 = $Module->new(<ABC    DEF>);

    is $ob0, "AB",              "ob0 is AB";
    is $ob1, "AB::CD::EF",      "ob1 is AB::CD::EF";
    is $ob2, "ABC::DEF",        "ob2 is ABC::DEF";

    cmp_ok $ob1 <=> $ob1, "==", 0, "$ob1 <=> $ob1 == 0";
    cmp_ok $ob2 <=> $ob2, "==", 0, "$ob2 <=> $ob2 == 0";

    cmp_ok $ob1 cmp $ob1, "==", 0, "$ob1 cmp $ob1 == 0";
    cmp_ok $ob2 cmp $ob2, "==", 0, "$ob2 cmp $ob2 == 0";

    # Numerically, ob2 follows ob1
    cmp_ok $ob1 <=> $ob2, "==", +1, "$ob1 <=> $ob2 == +1";
    cmp_ok $ob2 <=> $ob1, "==", -1, "$ob2 <=> $ob1 == -1";
    # Numerically, ob1 follows ob0
    cmp_ok $ob0 <=> $ob1, "==", -1, "$ob0 <=> $ob1 == -1";

    # Same for explicit nummification 
    cmp_ok 0+$ob1 <=> 0+$ob2, "==", +1, "0+$ob1 <=> 0+$ob2 == +1";
    cmp_ok 0+$ob2 <=> 0+$ob1, "==", -1, "0+$ob2 <=> 0+$ob1 == -1";

    # Lexically, ob1 follows ob2
    cmp_ok  $ob1  cmp  $ob2,  "==", -1,    "$ob1 cmp $ob2 == -1";
    cmp_ok  $ob2  cmp  $ob1,  "==", +1,    "$ob2 cmp $ob1 == +1";
    # Lexically, ob1 follows ob0
    cmp_ok  $ob0  cmp  $ob1,  "==", -1,    "$ob0 cmp $ob1 == -1";

    # Same for explicit stringification
    cmp_ok "$ob1" cmp "$ob2", "==", -1, qq("$ob1" cmp "$ob2" == -1);
    cmp_ok "$ob2" cmp "$ob1", "==", +1, qq("$ob2" cmp "$ob1" == +1);
    cmp_ok "$ob0" cmp "$ob1", "==", -1, qq("$ob0" cmp "$ob1" == -1);

}

sub has_overload_tests {
    my $P   = __PACKAGE__;
    my $obj = $Module->new($P);
    my @ops = qw( 
        ""  0+
        ==  !=
        eq  ne
        + - neg
        cmp <=>
    );

    for my $op (@ops) {
        ok $Module->can("($op"), "the $Module class has an overloaded $op operator";
        ok $obj->can("($op"),    "an $Module object has an overloaded $op operator";
    }
}

sub operator_tests { 
    # need to (re-)import functions in new test module
    package Alpha::Beta::Gamma::Delta;
    use Test::More;
    BEGIN { use_ok $Module }
    use FindApp::Utils qw(n_times);

    my $P  = __PACKAGE__;
    my $ob = $Module->new($P);

    my $op_test = sub($) { note("Testing @_ operator:") };

    $op_test->("stringification");
    is "$ob", $P,       "stringification works";

    $op_test->("numeric addition");
    is  0  + $ob, 4,        "nummification works:     0+$ob == 4";
    is  1  + $ob, 5,        "nummification works:     1+$ob == 5";
    is $ob + 1,   5,        "nummification works:     $ob+1 == 5";
    is -2  + $ob, 2,        "adding negatives works: -2+$ob == 2";

    $op_test->("rootification");
    is -$ob, "Alpha",   "rootification works: -$ob is Alpha";

    $op_test->("subtraction");
    is $ob-1, "Alpha::Beta::Gamma",     "subtracting 1 works";
    is $ob-2, "Alpha::Beta",            "subtracting 2 works";
    is $ob-3, "Alpha",                  "subtracting 3 works";
    is $ob-4, "main",                   "subtracting 4 works";

    $op_test->("string addition");
    is $ob + "Epsilon",       "Alpha::Beta::Gamma::Delta::Epsilon",   "adding Epsilon works";
    is $ob + "Epsilon" + 1,   6,                                      "adding Epsilon nummifies correctly";

    $op_test->("postfix autodecrement");

    is "$ob", $P,                       "ob wasn't mutated";
    is $ob--, $P,                       "ob still wasn't mutated -- yet";
    is "$ob", "Alpha::Beta::Gamma",     "postfix autodecrement worked";
    is $ob--, "Alpha::Beta::Gamma",     "ob still wasn't mutated -- yet";
    is "$ob", "Alpha::Beta",            "postfix autodecrement worked";
    is $ob--, "Alpha::Beta",            "ob still wasn't mutated -- yet";
    is "$ob", "Alpha",                  "postfix autodecrement worked";
    is $ob--, "Alpha",                  "ob still wasn't mutated -- yet";
    is "$ob", "main",                   "we're down to main now";

    for my $i (1..5) {
        my $times = n_times($i);
        is $ob--, "main",               "postfix autodecrementing main ${times}leaves main";
        is "$ob", "main",               "we're down to main after running -- on main $times";
        is 0+$ob, 1,                    "still 1 element after postfix autodecrementing main $times";
    }

    $op_test->("prefix autodecrement");

    $ob = $Module->new($P);
    is --$ob, "Alpha::Beta::Gamma",     "prefix autodecrement worked";
    is --$ob, "Alpha::Beta",            "prefix autodecrement worked";
    is --$ob, "Alpha",                  "prefix autodecrement worked";
    is --$ob, "main",                   "we're down to main now";

    for my $i (1..5) {
        my $times = n_times($i);
        is --$ob, "main",               "prefix autodecrementing main ${times}leaves main";
        is "$ob", "main",               "we're down to main after running -- on main $times";
        is 0+$ob, 1,                    "still 1 element after prefix autodecrementing main $times";
    }
}

#################################################################

run_tests();

__END__
