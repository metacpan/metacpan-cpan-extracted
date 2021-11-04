#!/usr/bin/env perl 

use t::setup;
use_ok my $MODULE = __TEST_PACKAGE__;

sub import_tests {
    my @tags = map ":$_", qw(app env all);
    for my $tag (@tags) { 
        ok(eval { $MODULE->import("$tag"); 1 }, "use $MODULE qw($tag);")
            || diag "couldn't import $tag from $MODULE";
    }
}

sub BLM_tests {
    my @blm_vars = qw(
        $Root
        $Bin @Bin
        @Lib $Lib
        @Man $Man
    );
    for my $var (@blm_vars) {
        no warnings "void";
        ok(eval qq{ $var ; 1 },                 "ok to access $var") 
            || diag "$var is not accessible: $@";
    }
}

sub debug_var_tests {
    my @debug_vars = qw(
        $Debugging
        $Tracing
    );
    for my $var (@debug_vars) {
        no warnings "void";
        ok(eval qq{ $var ; 1 },                 "ok to access $var") 
            || diag "$var is not accessible: $@";
    }
}

sub unvar_tests {
    my @unvars = qw( $ROOT @Root );
    my $toss   = qr/is not imported|requires explicit package name/; 
    for my $var (@unvars) {
        no warnings "void";
        ok !eval qq{ $var ; 1 },                "$var is not a thing";
        like $@, $toss,                         "accessing $var throws $toss";
    }
}

# zzz to make this test run last so the rest work ok
sub zzz_envar_tests {
    require_ok "FindApp";

    local our  $APP_ROOT;
    ok !length $APP_ROOT,                       "found no APP_ROOT yet";
    lives_ok { FindApp->findapp_and_export }    "findapp_and_export lives ok";

    my @envars = qw(
        APP_ROOT 
        MANPATH
    );

    for my $var (@envars) {
        ok eval qq{ length \$$var },            "\$$var variable found";
        ok length $ENV{$var},                   "\$ENV{$var} variable, too";
    }
}

run_tests();

__END__
