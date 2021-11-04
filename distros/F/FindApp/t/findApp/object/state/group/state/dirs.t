#!/usr/bin/env perl

use t::setup;

use Scalar::Util qw(blessed reftype refaddr);

my $Class = __TEST_PACKAGE__;

my @Libs = qw(lib t/lib);
my $Libs = @Libs;

sub shiny(;$) {
    my $reason = @_ ? "for @_" : "";
    my $ob = $Class->new(@Libs);
    ok blessed($ob), "made shiny new object $reason";
    cmp_ok $ob->count, "==", $Libs, "shiny new object has $Libs elts";
    return $ob;
}

my $INVALID_ARGS = qr/invalid arguments/;
my $UNDEF_ARGS   = qr/undefined arguments/;
my $LAME_ARGS    = qr/$INVALID_ARGS|$UNDEF_ARGS/;
my $NOT_OBJECT   = qr/not an object/;

use_ok $Class;
run_tests();

################################################################

sub class_tests { 
    cmp_ok $Class->class, "eq", $Class, "class isa $Class";

    my $dir_count = @Libs;

    my $ob = $Class->new(@Libs);
    ok blessed($ob),                    "new class method created new object";
    is $ob->count, $dir_count,          "found expected number of items: $dir_count";

    ok $ob->has(@Libs),                 "and all the libs (@Libs) are accounted for";
    ok $ob->has(@Libs, @Libs),          "even when they are doubled";
    ok !$ob->has("fie"),                "no false positives for non-existent dirs";

    is $ob->class, $Class,              "object eq $Class";
    ok $ob->isa($Class),                "object isa $Class";
    is $ob->class, $Class,              "class method returns $Class";
    ok $ob->isa($ob->class),            "class method returns something to isa";

    ok $ob->object,                     '$ob->object returns true';
    
    throws_ok { $Class->object }  $NOT_OBJECT,  "$Class->object throws $NOT_OBJECT";

    my $ob2 = $ob->new("fie");
    ok blessed($ob2),                   "new object method created new object";
    is $ob2->count, 1+$dir_count,       "found expected number of items: ".(1+$dir_count);

    ok $ob2->has(fie => @Libs),         "checking copy for fie plus @Libs";
}

sub overload_tests {
    my $ob = $Class->new(@Libs);
    like($ob->as_string, qr/bless.*ARRAY/,  "as_string to blessed array");
    like("$ob",          qr/bless.*ARRAY/,  "stringifies to blessed array");

    my @ops = qw( 
        ""  0+
        ==  !=
        eq  ne
    );

    for my $op (@ops) {
        ok $Class->can("($op"), "$Class has an overloaded $op operator";
    }
}

sub identity_tests {
    my $ob = $Class->new(@Libs);

    cmp_ok $ob,         "==", $ob,          "self identity test";
    cmp_ok $ob->object, "==", $ob,          "object identity test";
    cmp_ok $ob,         "==", $ob->object,  "flipped object identity test";

    my $ob1 = $ob;
    cmp_ok $ob1, "==", $ob,                 "copied identity test";

    # order immaterial, and normalized internally
    my $ob2 = $Class->new(reverse @Libs);
    ok $ob2,                                "created new object with initial values flipped";

    cmp_ok $ob1, "!=", $ob2,                "ob1 and ob2 are distguishible";
    cmp_ok $ob2, "!=", $ob1,                "ob2 and ob1 are distguishible";

    ok !($ob1 == $ob2),                     "ob1 and ob2 aren't indistinguishible";
    ok !($ob2 == $ob1),                     "ob2 and ob1 aren't indistinguishible";

    cmp_ok $ob1, "eq", $ob2,                "ob1 and ob2 have same contents";
    cmp_ok $ob2, "eq", $ob1,                "ob2 and ob1 have same contents";

    ok !($ob1 ne $ob2),                     "ob1 and ob2 don't have different contents";
    ok !($ob2 ne $ob1),                     "ob2 and ob1 don't have different contents";
}

################################################################

sub method_tests { 
    my $ob1 = $Class->new(@Libs);
    my $ob2 = $Class->new(@Libs);

    cmp_ok $ob1->count, "==", 2,            "count ob1 is two elements";
    cmp_ok $ob2->count, "==", 2,            "count ob2 is two elements";

    my @list = $ob1->get;
    cmp_ok 0+@list, "==", 2,                "list get returns list of two items";

    my $scalar = $ob1->get;
    ok $scalar,                             "scalar get returns true item";
    like($scalar, qr/\blib\b/,              "scalar get returns something with lib in it");
    ok grep($_ eq $scalar, @list),          "found scalar in list";
    ok !(grep {$_ eq "bad$scalar" } @list), "didn't find bad scalar in list";

    ok $ob1->has(@Libs),                    "ob1 has liblist";
    ok $ob1->has(reverse @Libs),            "ob1 has reverse liblist";
    ok $ob1->has($ob1->get),                "ob1 has its own get";
    ok $ob1->has($ob2->get),                "ob1 has ob2 get";

    my $old_count = $ob2->count;
    my $ob2_alias = $ob2->add("lib");
    cmp_ok $ob2, "==", $ob2_alias,          "adding returns original object";
    cmp_ok($ob2_alias->count, "==", 2, 
      "adding something that's already there doesn't increase element count")
        || diag("ob2_alias has wrong elt count: $ob2_alias");

    ok $ob2->add($ob1->get), "add ob1 to ob2";
    cmp_ok $ob1, "eq", $ob2, "ob1 and ob2 still have same contents";
    cmp_ok $ob1, "!=", $ob2, "ob1 and ob2 still are different objects";

    ok $ob2->add($ob1->get), "set ob2 to ob1";
    cmp_ok $ob1, "eq", $ob2, "ob1 and ob2 still have same contents, again";
    cmp_ok $ob1, "!=", $ob2, "ob1 and ob2 still are different objects, again";

    my $ob3 = $Class->new(@Libs);
    cmp_ok $ob3->count, "==", 2, "count ob3 is two elements";
    cmp_ok $ob3->reset, "==", 2, "reset ob3 cleared two elements";
    cmp_ok $ob3->reset, "==", 0, "reset ob3 again cleared zero elements";

    # idempotent adds
    ok !(grep { $_ eq "testlib" } @Libs),       "testlib not already in liblist";
    ok($ob3->set(@Libs, "testlib"),             "adding @Libs testlib try $_") for 1..3;
    cmp_ok $ob3->count, "==", 3,                "count ob3 now three elements";

    ok $ob3->has("testlib"),                    "ob3 has testlib";
    ok $ob3->has(@Libs),                        "ob3 has @Libs";
    ok $ob3->has(testlib => @Libs),             "ob3 has testlib @Libs";
    ok $ob3->has(qw(testlib testlib)),          "ob3 has testlib testlib";
    ok !$ob3->has("libtest"),                   "ob3 hasn't libtest";
    cmp_ok $ob3->count, "==", 3,                "count ob3 still three elements";

    cmp_ok scalar $ob3->del("testlib"), "==", 1, "del ob3 testlib == 1";
    cmp_ok $ob3->count, "==", 2,                 "count ob3 is two elements again";
    cmp_ok scalar $ob3->del("testlib"), "==", 0, "del ob3 testlib == 0";
    cmp_ok $ob3->count, "==", 2,                 "count ob3 is still two elements";
    cmp_ok scalar $ob3->del(@Libs), "==", scalar(@Libs), "del ob3 @Libs == ".@Libs;
    cmp_ok $ob3->count, "==", 0,                 "count ob3 is zero elements";
}

sub exception_tests {
    my @argless_methods = qw(
        class
        count
        first
        get
        last
        object
        reset
    );

    for my $meth (@argless_methods) {
        my $ob = shiny($meth);

        throws_ok { $ob->$meth(2016)  }  $INVALID_ARGS, "$meth(2016) with one arg dies right";
        throws_ok { $ob->$meth(1..9)  }  $INVALID_ARGS, "$meth(1..9) with nine args dies right";
        lives_ok  { $ob->$meth        }                 "$meth with no args lives";
    }

    my @argfull_methods = qw(
        add
        del
        has
    );

    for my $meth (@argfull_methods) {
        my $ob = shiny($meth);

        throws_ok { $ob->$meth        }  $INVALID_ARGS,  "$meth() with no args dies right";
        lives_ok  { $ob->$meth("etc") }                  "$meth(etc) with one arg lives";
        lives_ok  { $ob->$meth(@Libs) }                  "$meth(@Libs) with more args lives";
    }

    my @dont_care_methods = qw(
        new
        set
    );

    for my $meth (@dont_care_methods) {
        my $ob = shiny($meth);
        lives_ok { $ob->$meth        } "$meth() with no args lives";
        lives_ok { $ob->$meth("etc") } "$meth(etc) with one arg lives";
        lives_ok { $ob->$meth(@Libs) } "$meth(@Libs) with more args lives";
    }

    my @undef_haters = (
        @argless_methods,
        @argfull_methods, 
        @dont_care_methods,
    );

    for my $meth (@undef_haters) {
        my $ob = shiny("$meth(undef)");
        throws_ok { $ob->$meth(undef) } $LAME_ARGS, "$meth(undef) dies of $LAME_ARGS";
    }
}
