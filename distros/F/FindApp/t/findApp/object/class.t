#!/usr/bin/env perl 

use t::setup;

use FindApp::Utils qw(
    :foreign 
    :list
    :package 
    BLM
);

my $NO_METHOD = qr/Can't locate object method/;

use_ok(my $Subclass = __TEST_PACKAGE__);
use_ok(my $Class    = PACKAGE($Subclass)->super->unbless);
use_ok(my $Root     = PACKAGE($Subclass)->left->unbless);

run_tests();

sub class_method_tests {
    my @methods = qw(
        adopts_children
        adopts_parents
        class
        copy
        init
        new
        object
        old
        params
        renew
    );

    for my $class ($Root, $Class, $Subclass) {
        note "testing class methods against $class";
        for my $method (reverse @methods) {
            ok $class->can($method),   "can $method $class";
        }
    }
}

sub constructor_tests {
    my($this_class, $root_class) = map { $_->new->class } $Class, $Root;
    cmp_ok $this_class, "ne", $root_class,      "new $Root and new $Class produce different classes";

    my ($this, $root);
    for my $constructor (qw(new old)) {
        ($this, $root) = map { $_->$constructor } $Class, $Root;
        ok blessed($this),                      "class method: $Class->$constructor makes object";
        ok blessed($root),                      "class method: $Root->$constructor makes object";
    }

    my($this2, $root2) = map { $_->new->new } $Class, $Root;
    ok blessed($this2),                         "instance method: $Class->new->new makes object";
    ok blessed($root2),                         "instance method: $Root->new->new makes object";

    my($this3, $root3) = map { $_->old->new } $Class, $Root;
    ok blessed($this3),                         "instance method: $Class->old->new makes object";
    ok blessed($root3),                         "instance method: $Root->old->new makes object";

    my($this4, $root4) = map { $_->new->old } $Class, $Root;
    ok blessed($this4),                         "instance method: $Class->new->old makes object";
    ok blessed($root4),                         "instance method: $Root->new->old makes object";
}

sub copied_constructor_tests {
    my $ob0 = $Root->new;
    my $ob1 = $ob0->new;

    my($EG, $MK) = qw(examples Makefile.PL);
    my @BOTH     = ($MK, $EG);
    my $BOTH     = commify_and(@BOTH);

    # Now do something to make it different from the normal starting state:
    $ob1->add_bindirs_allowed($EG);
    $ob1->add_rootdir_wanted(@BOTH);

    my $ob2 = $ob1->new;

    cmp_ok $ob0, "!=", $ob1,    "ob0 and ob1 have different addresses";
    cmp_ok $ob0, "ne", $ob1,    "ob0 and ob1 have different contents";
    cmp_ok $ob0, "!=", $ob2,    "ob0 and ob2 have different addresses";
    cmp_ok $ob1, "!=", $ob2,    "ob1 and ob2 have different addresses";
    cmp_ok $ob0, "ne", $ob2,    "ob0 and ob2 have different contents";
    cmp_ok $ob1, "eq", $ob2,    "ob1 and ob2 have same contents";

    my @obs = ($ob0, $ob1, $ob2);
    for my $dir (+BLM) {
        for my $i (0 .. $#obs) {
            ok $obs[$i]->group($dir)->allowed->has($dir),       "ob$i has $dir in its group($dir)->allowed";
        }
    }

    note("bin group allows $EG");
    ok!$ob0->group("bin")->allowed->has($EG),                   "ob0 lacks $EG in its group(bin)->allowed";
    ok $ob1->group("bin")->allowed->has($EG),                   "ob1 has $EG in its group(bin)->allowed";
    ok $ob2->group("bin")->allowed->has($EG),                   "ob2 has $EG in its group(bin)->allowed";

    ok!$ob0->bindirs->allowed->has($EG),                        "ob0 lacks $EG in its bindirs->allowed";
    ok $ob1->bindirs->allowed->has($EG),                        "ob1 has $EG in its bindirs->allowed";
    ok $ob2->bindirs->allowed->has($EG),                        "ob2 has $EG in its bindirs->allowed";

    ok!$ob0->bindirs_allowed->has($EG),                         "ob0 lacks $EG in its bindirs_allowed";
    ok $ob1->bindirs_allowed->has($EG),                         "ob1 has $EG in its bindirs_allowed";
    ok $ob2->bindirs_allowed->has($EG),                         "ob2 has $EG in its bindirs_allowed";

    for my $it (@BOTH) {
        note("root group wants $it");

        ok!$ob0->group("root")->wanted->has($it),               "ob0 lacks $it in its group(root)->wanted";
        ok $ob1->group("root")->wanted->has($it),               "ob1 has $it in its group(root)->wanted";
        ok $ob2->group("root")->wanted->has($it),               "ob2 has $it in its group(root)->wanted";

        ok!$ob0->rootdir->wanted->has($it),                     "ob0 lacks $it in its rootdir->wanted";
        ok $ob1->rootdir->wanted->has($it),                     "ob1 has $it in its rootdir->wanted";
        ok $ob2->rootdir->wanted->has($it),                     "ob2 has $it in its rootdir->wanted";

        ok!$ob0->rootdir_wanted->has($it),                      "ob0 lacks $it in its rootdir_wanted";
        ok $ob1->rootdir_wanted->has($it),                      "ob1 has $it in its rootdir_wanted";
        ok $ob2->rootdir_wanted->has($it),                      "ob2 has $it in its rootdir_wanted";
    }

    note("root group wants $BOTH");
    ok!$ob0->group("root")->wanted->has(@BOTH),                 "ob0 lacks $BOTH in its group(root)->wanted";
    ok $ob1->group("root")->wanted->has(@BOTH),                 "ob1 has $BOTH in its group(root)->wanted";
    ok $ob2->group("root")->wanted->has(@BOTH),                 "ob2 has $BOTH in its group(root)->wanted";

    ok!$ob0->rootdir->wanted->has(@BOTH),                       "ob0 lacks $BOTH in its rootdir->wanted";
    ok $ob1->rootdir->wanted->has(@BOTH),                       "ob1 has $BOTH in its rootdir->wanted";
    ok $ob2->rootdir->wanted->has(@BOTH),                       "ob2 has $BOTH in its rootdir->wanted";

    ok!$ob0->rootdir_wanted->has(@BOTH),                        "ob0 lacks $BOTH in its rootdir_wanted";
    ok $ob1->rootdir_wanted->has(@BOTH),                        "ob1 has $BOTH in its rootdir_wanted";
    ok $ob2->rootdir_wanted->has(@BOTH),                        "ob2 has $BOTH in its rootdir_wanted";

}

sub identity_tests {
    for my $class ($Root, $Class) {

        note("testing $class for identity properties");

        my $ob = $class->new;
        ok blessed $ob,                         "created $class object";

        cmp_ok $ob,         "==", $ob,          "self identity test";
        cmp_ok $ob->object, "==", $ob,          "object identity test";
        cmp_ok $ob,         "==", $ob->object,  "flipped object identity test";

        my $ob1 = $ob;
        cmp_ok $ob1, "==", $ob,                 "copied identity test";
        cmp_ok $ob,  "==", $ob1,                "copied identity test, flipped";

        my $ob2 = $class->new;
        ok $ob2,                                "created a second $class object";
        is blessed $ob2, $class,                "blessed into $class";
        is $ob2->class, $class,                 "whose ->class is $class";

        cmp_ok $ob1, "!=", $ob2,                "ob1 and ob2 are distguishible";
        cmp_ok $ob2, "!=", $ob1,                "ob2 and ob1 are distguishible";

        ok !($ob1 == $ob2),                     "ob1 and ob2 aren't indistinguishible";
        ok !($ob2 == $ob1),                     "ob2 and ob1 aren't indistinguishible";

        cmp_ok $ob1, "eq", $ob2,                "ob1 and ob2 have same contents";
        cmp_ok $ob2, "eq", $ob1,                "ob2 and ob1 have same contents";

        ok !($ob1 ne $ob2),                     "ob1 and ob2 don't have different contents";
        ok !($ob2 ne $ob1),                     "ob2 and ob1 don't have different contents";

    }
}

# One and Two should be the same.
# Three and Four should be the same.
# But One and Two should not be the same as Three and Four.
sub singleton_tests {
    my $one =  $Class->new;
    lives_ok { $Class->old($one) }      "interred singleton via $Class->old";

    my $two =  $Class->old;
    cmp_ok $one, "==", $two,            "fetched back interred singleton";

    my $three = $Class->new;
    lives_ok { $one->old($three) }      "interred new singleton via object->old";

    my $four = $Class->old;
    cmp_ok $four, "==", $three,         "fetched back singleton is the one just interred";
    cmp_ok $four, "!=", $one,           "which is not the same as the original first one";
}

sub class_object_tests {
    for my $class ($Root, $Class) { 
        my $old = $class->old($class->new);
        is $class->class,         $old->class,         "$class->class is old->class is " . $class->class;
        is $old->class->object,   $old,                "old->class->object is old";
        is $class->class->object, $old,                "$Class->class->object is old";
        is $old->object,          $old,                "old->object is old";
        is $class->object,        $old,                "$Class->object is old";
        is $class->object,        $old->object,        "$Class->object is old->object";
    }
}

sub upchuck_tests {
    throws_ok { $Subclass->new } $NO_METHOD,   "new $Subclass throws $NO_METHOD";
}

__END__
