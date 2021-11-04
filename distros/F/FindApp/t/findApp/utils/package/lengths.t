#!/usr/bin/env perl

# It would be really nice to use the package-manipulating
# facilities these modules provide for all this, but that
# would defeat the purpose of testing.

use t::setup;

use FindApp::Utils qw(function blessed);

my $Module; BEGIN {
   $Module = "FindApp::Utils::Package::Object";
   use_ok($Module) || die;
}

sub length_tests {
    package One::Two::Three::Four::Five;
    use Test::More;
    BEGIN { use_ok $Module }

    my $p = PACKAGE;
    is $p, __PACKAGE__,  "PACKAGE is __PACKAGE__, now " . __PACKAGE__;

    cmp_ok $p->length, "==", 5,           "$p has five elements";
    cmp_ok $p->super->length, "==", 4,    "$p->super has four elements";
    cmp_ok $p->super(2)->length, "==", 3, "$p->super(2) has three elements";
    cmp_ok $p->super(3)->length, "==", 2, "$p->super(3) has two elements";
    cmp_ok $p->super(4)->length, "==", 1, "$p->super(4) has one element";

    $p = $Module->new("Uno::Dos", "Tres::Quatro");
    cmp_ok $p->length, "==", 4,           "$p has four elements";

}

sub main_normalization_tests {

    my @mains = qw(
        main
        main::
        ::main::
        ::
        ::::
        ::main::main
        ::main::main::
        ::main::main::::
        main::main::::
        ::::::main::main::::
    );

    for my $main (@mains) {
        my $p = $Module->new($main);
        is $p, "main", "$main is main";
    }

}


run_tests();
