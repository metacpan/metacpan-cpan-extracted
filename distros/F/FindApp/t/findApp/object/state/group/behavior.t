#!/usr/bin/env perl

use t::setup;
use FindApp::Vars  qw(:all);
use FindApp::Utils qw(:package BLM);

my $NOT_OBJECT   = qr/not an object/;
my $INVALID_ARGS = qr/invalid arguments/;
my $NO_CLASS_OBJ = qr/Can't use string .* as a HASH ref while "strict refs"/;
my $NOT_A_GROUP  = qr/group.*is not a.*group/;
my @PIECES       = (root => +BLM);

use_ok my $Subclass = __TEST_PACKAGE__;
use_ok my $Class    = PACKAGE($Subclass)->super->unbless;

sub expected_name_tests {
    my $name = "good";
    my $ob = $Class->new($name);

    lives_ok  { $ob->expected_name($name) }                       "expected_name '$name' lives";
    throws_ok { $ob->expected_name("crap-$name") } $NOT_A_GROUP,  "expected_name 'crap-$name' throws $NOT_A_GROUP";
    throws_ok { $ob->expected_name }               $INVALID_ARGS, "name w/o args throws throws $INVALID_ARGS";
    throws_ok { $ob->expected_name(1,2,3) }        $INVALID_ARGS, "name 1,2,3 args throws throws $INVALID_ARGS";
    throws_ok { $Class->expected_name($name) }     $NO_CLASS_OBJ, "can't use expected_name as a class method, throws $NO_CLASS_OBJ";
}

sub negative_export_to_env_tests {
    my $nongroup = "bogotic";
    my $ob = $Class->new($nongroup);
    my $BAD_GROUP = qr/Can't locate object .* "export_${nongroup}_to_env"/;

    throws_ok { $ob->export_to_env    }            $BAD_GROUP,    "export_to_env on ob $nongroup throws $BAD_GROUP";
    throws_ok { $Class->export_to_env }            $NO_CLASS_OBJ, "can't use export_to_env as a class method, throws $NO_CLASS_OBJ";

    for my $piece (@PIECES) {
        my $meth  = "export_${piece}_to_env";
        my $ERROR = qr/group $nongroup is not a $piece group/;
        throws_ok { $ob->$meth }                  $ERROR,         "$meth ob throws $ERROR";
        throws_ok { $Class->$meth }               $NO_CLASS_OBJ,  "can't use $meth as a class method, throws $NO_CLASS_OBJ";
    }
}

sub positive_export_to_env_tests {
    for my $piece (@PIECES) {
        no strict "refs";
        "export_my_$piece"->($piece);
    }
}

sub selfnote($) {
    my($self) = @_;
    note "... $self export tests ...";
}

sub export_my_root {
    my $me = shift;
    selfnote $me;
    ok !defined $APP_ROOT, "APP_ROOT is undef";
    my $path = "/tmp/whatever";
    my $op = $Class->new($me);
    lives_ok { $op->found($path) }      "$me found $path";
    lives_ok { $op->export_to_env }     "$me export_to_env";
    is $APP_ROOT, $path,                "APP_ROOT=$path";
    is $ENV{APP_ROOT}, $APP_ROOT,       "ENV{APP_ROOT}=APP_ROOT";
}

sub export_my_bin {
    my $me = shift;
    selfnote $me;
    my $path = "/tmp/fake_binny";
    cmp_ok scalar grep($_ eq $path, @PATH), "==", 0,    "path doesn't have $path yet";
    my $op = $Class->new($me);
    lives_ok { $op->found($path) }                      "$me found $path";
    lives_ok { $op->export_to_env }                     "$me export_to_env";
    cmp_ok(scalar grep($_ eq $path, @PATH), "==", 1,    "path now has $path in it, once")
        || diag "path is @PATH";
}

sub export_my_lib {
    my $me = shift;
    selfnote $me;
    local @INC = @INC; # This doesn't work for the env stuff
    my $path = "/tmp/bibliofake";
    cmp_ok scalar grep($_ eq $path, @INC), "==", 0,     "INC doesn't have $path yet";
    my $op = $Class->new($me);
    lives_ok { $op->found($path) }                      "$me found $path";
    lives_ok { $op->export_to_env }                     "$me export_to_env";
    cmp_ok(scalar grep($_ eq $path, @INC), "==", 1,     "INC now has $path in it, once")
        || diag "path is @INC";
}

sub export_my_man {
    my $me = shift;
    selfnote $me;
    my $path = "/tmp/fake_manny";
    cmp_ok scalar grep($_ eq $path, @MANPATH), "==", 0, "MANPATH doesn't have $path yet";
    my $op = $Class->new($me);
    lives_ok { $op->found($path) }                      "$me found $path";
    lives_ok { $op->export_to_env }                     "$me export_to_env";
    cmp_ok(scalar grep($_ eq $path, @MANPATH), "==", 1, "MANPATH now has $path in it, once")
        || diag "MANPATH is @MANPATH";
}

run_tests();
