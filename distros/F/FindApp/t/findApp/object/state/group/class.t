#!/usr/bin/env perl

use t::setup;
use Scalar::Util        qw(blessed reftype refaddr);
use FindApp::Utils      ":package";

my $NOT_OBJECT   = qr/not an object/;
my $INVALID_ARGS = qr/invalid arguments/;

use_ok my $Subclass = __TEST_PACKAGE__;
use_ok my $Class    = PACKAGE($Subclass)->super->unbless;
run_tests();

sub erasure_tests {
    my @erasures = qw(
        dir_field   
        dir_fields 
        dir_types 
        field_map
        type_map
    );
    for my $missing (@erasures) {
        ok(!$Class->can($missing),  "$Class has been cleaned of $missing")
            || diag "apparently for $missing it can call " . $Class->can($missing);
    }
}

sub class_tests {
    my $subclass = $Class . "::Class";
    ok $Class->isa($subclass), "$Class isa $subclass";
    ok $Class->can("new"),     "$Class can new";

    my $ob1 = $Class->new("dirset1");
    ok $ob1, "class->constructor:  ob1 = new $Class dirset1";

    my $ob2 = $ob1->new("dirset2");
    ok $ob2, "object->constructor: ob2 = new ob1 dirset2";

    ok blessed($ob1),   "new class  method created new ob1 object";
    ok blessed($ob2),   "new object method created new ob2 object";

    throws_ok { $Class->new } $INVALID_ARGS, "class  new w/o args throws $INVALID_ARGS";
    throws_ok { $ob1->new   } $INVALID_ARGS, "object new w/o args throws $INVALID_ARGS";

    cmp_ok $Class->class, "eq", $Class,  "class isa $Class";
    cmp_ok $ob1->class, "eq", $Class,    "object eq $Class";
    ok $ob1->isa($Class),                "object isa $Class";
    cmp_ok $ob1->class, "eq", $Class,    "class method returns $Class";
    ok $ob1->isa($ob1->class),           "class method returns something to isa";
    ok $ob1->object,                     "ob1->object returns true";
    
    throws_ok { $Class->object } $NOT_OBJECT,  "class->object throws $NOT_OBJECT";
}

sub identity_tests {
    my $ob1 = $Class->new("dirset1");
    my $ob2 = $ob1->new("dirset2");

    cmp_ok $ob1, "==", $ob1, "ob1 == ob1";
    cmp_ok $ob2, "==", $ob2, "ob2 == ob2";

    cmp_ok $ob1, "!=", $ob2, "ob1 != ob2";
    cmp_ok $ob2, "!=", $ob1, "ob2 != ob1";
}

sub copy_tests {
    local $TODO = "These are yet to be written";
    ok 0 => "write some tests";
}

sub param_tests {
    local $TODO = "These are yet to be written";
    ok 0 => "write some tests";
}
