#!/usr/bin/env perl

use t::setup;
use Scalar::Util qw(blessed reftype refaddr);
use FindApp::Utils ":package";

my $NOT_OBJECT   = qr/not an object/;
my $INVALID_ARGS = qr/invalid arguments/;
my $NO_CLASS_OBJ = qr/Can't use string .* as a HASH ref while "strict refs"/;

my @ATTRS = map {uc} qw(name exported allowed wanted found);

use_ok my $Parent = __TEST_CLASS__;
use_ok my $Class   = $Parent - 1;

UNPACKAGE for $Parent, $Class;

run_tests();

sub class_tests {
    ok $Class->isa($Parent), "$Class isa $Parent";
    ok $Class->can("new"),   "$Class can new";
}

sub attribute_tests {
    my $ob = $Class->new("binset");
    for my $attr (@ATTRS) {
        ok $Class->can($attr),                       "Class can $attr";
        ok $Parent->can($attr),                      "Parent can $attr";
        ok $ob->can($attr),                          "ob can $attr";
        is $Class->$attr, "${Parent}::${attr}",      "Class->$attr eq ${Parent}::${attr}";
        is $ob->$attr, "${Parent}::${attr}",         "ob->$attr eq ${Parent}::${attr}";
        is $ob->$attr, $Class->$attr,                "Class->$attr eq ob->$attr"; 
        ok exists $ob->{$ob->$attr},                 "$attr exists";
    }
}

sub exported_tests {
    my $ob = $Class->new("libset");
    ok !$ob->have_exported,     "haven't exported yet";
    ok $ob->unexported,         "unexported agrees, returning true";

    throws_ok { $ob->have_exported("arg") } $INVALID_ARGS, "ob have_exported(arg) throws $INVALID_ARGS";
    throws_ok { $ob->bump_exports("arg") }  $INVALID_ARGS, "ob bump_exports(arg) throws $INVALID_ARGS";

    is $ob->bump_exports, 1,    "bumped exports to 1";
    ok $ob->have_exported,      "have exported now";

    is $ob->exported,    1,     "exported at 1";
    is $ob->exported(2), 3,     "exported at 3";
    is $ob->exported,    3,     "exported still at 3";

    ok !$ob->unexported,        "unexported now false";
    ok  $ob->unexported(1),     "reset unexported";
    ok  $ob->unexported,        "unexported true again";
    ok !$ob->have_exported,     "have_exported agrees";

    is $ob->exported,    0,     "exported at 0";

    throws_ok { $ob->exported(undef) } qr/uninitialized/, "incrementing exports by undef throws uninitialized";

    my @methods = qw(
        bump_exports
        exported
        have_exported 
        unexported 
    );
    for my $method (@methods) {
        throws_ok { $ob->$method(1,2,3) } $INVALID_ARGS,  "passing $method too many args throws $INVALID_ARGS";
        throws_ok { $Class->$method }     $NO_CLASS_OBJ,  "can't use $method as a class method, throws $NO_CLASS_OBJ";
    }
}

sub name_tests {
    my $name1 = "bingo";
    my $name2 = "bongo";

    my $ob = $Class->new($name1);

    is $ob->name, $name1,                         "new Class $name1 has ob name of $name1";
    is $ob->name($name2), $name1,                 "setting to $name2 returns old name of $name1";
    is $ob->name, $name2,                         "and it's still $name2 later";

    throws_ok { $ob->name(1,2,3) } $INVALID_ARGS, "name ob 1,2,3 throws throws $INVALID_ARGS";
    throws_ok { $Class->name }     $NO_CLASS_OBJ, "can't use name as a class method, throws $NO_CLASS_OBJ";

    my $BOGUS = qr/name cannot/;

    throws_ok { $ob->name(undef) }   $BOGUS,      "name ob undef throws $BOGUS";
    throws_ok { $ob->name('') }      $BOGUS,      "name ob '' throws $BOGUS";
    throws_ok { $ob->name([]) }      $BOGUS,      "name ob [] throws $BOGUS";
    throws_ok { $ob->name($ob) }     $BOGUS,      "name ob ob throws $BOGUS";
    throws_ok { $ob->name("\0") }    $BOGUS,      "name ob \\0 throws $BOGUS";
    throws_ok { $ob->name("a\0") }   $BOGUS,      "name ob a\\0 throws $BOGUS";
    throws_ok { $ob->name("\0a") }   $BOGUS,      "name ob \\0a throws $BOGUS";
    throws_ok { $ob->name("a\0b") }  $BOGUS,      "name ob a\\0b throws $BOGUS";

}

sub accessor_tests {
    my @flavors = qw(allowed found wanted);
    my $ob = $Class->new("whatever");
    my @dirs;
    for my $meth (@flavors) {
        is $ob->$meth->count, 0,                "ob->$meth->count initially 0";
        lives_ok { @dirs = $ob->$meth }         "\@dirs = $meth ob lives ok";
        is  scalar(@dirs), 0,                   "ob->$meth returned empty list";
        my @input = qw(one two three);
        my $count = @input;
        lives_ok { $ob->$meth(@input) }         "$meth ob @input lives ok";
        is         $ob->$meth->count, $count,   "ob->$meth->count now $count";
        lives_ok { $ob->$meth->reset }          "reset $meth ob lives ok";
        is         $ob->$meth->count, 0,        "ob->$meth->reset to 0";
        throws_ok { $Class->$meth } $NO_CLASS_OBJ, "can't use $meth as a class method, throws $NO_CLASS_OBJ";
    }
}

__END__

