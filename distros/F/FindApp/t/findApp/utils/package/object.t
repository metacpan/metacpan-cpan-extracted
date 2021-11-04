#!/usr/bin/env perl

use t::setup;

use FindApp::Utils qw(function blessed);

my $Module; BEGIN {
   $Module = __TEST_PACKAGE__;
   use_ok($Module) || die;
}

my $WANTARRAY = qr/need list context/;

my %PREFIX_TO_PACKAGE = (
    top => "Rip",
    sib => "Rip::Van",
    sub => "Rip::Van::Winkle",
);

sub identity_tests {
    my $sample = "Module::Build::Platform::EBCDIC";
    my $ob = $Module->new($sample);

    cmp_ok $ob,         "==", $ob,          "self identity test";
    cmp_ok $ob->object, "==", $ob,          "object identity test";
    cmp_ok $ob,         "==", $ob->object,  "flipped object identity test";

    my $ob1 = $ob;
    cmp_ok $ob1, "==", $ob,                 "copied identity test";

    # order immaterial, and normalized internally
    my $ob2 = $Module->new($sample);
    ok $ob2,                                "created new object with same initial values";

    cmp_ok $ob1, "!=", $ob2,                "ob1 and ob2 are distguishible";
    cmp_ok $ob2, "!=", $ob1,                "ob2 and ob1 are distguishible";

    ok !($ob1 == $ob2),                     "ob1 and ob2 aren't indistinguishible";
    ok !($ob2 == $ob1),                     "ob2 and ob1 aren't indistinguishible";

    cmp_ok $ob1, "eq", $ob2,                "ob1 and ob2 have same contents";
    cmp_ok $ob2, "eq", $ob1,                "ob2 and ob1 have same contents";

    ok !($ob1 ne $ob2),                     "ob1 and ob2 don't have different contents";
    ok !($ob2 ne $ob1),                     "ob2 and ob1 don't have different contents";
}

sub creation_tests {
    is PACKAGE, __PACKAGE__,                "PACKAGE is __PACKAGE__ " . __PACKAGE__;

    package One::Two::Three;
    use Test::More;
    BEGIN { use_ok $Module }

    is PACKAGE, __PACKAGE__,                    "PACKAGE is still __PACKAGE__, now " . __PACKAGE__;
    is PACKAGE("Over::Ride"), "Over::Ride",     "PACKAGE(Over::Ride) is Over::Ride";
    is $Module->new(<Over Ride>), "Over::Ride", "$Module->new(<Over Ride>) is also Over::Ride";
    is $Module->new(__PACKAGE__), __PACKAGE__,  ("$Module->new(" . __PACKAGE__ . ") is " . __PACKAGE__);
    is $Module->new(), "main",                  "$Module->new() is main";
}

sub left_tests {
    package One::Two::Three::Four::Five;
    use Test::More;
    BEGIN { use_ok $Module }

    my $p = PACKAGE;
    is $p, __PACKAGE__,  "PACKAGE is __PACKAGE__, now " . __PACKAGE__;

    is $p->left,       "One",                              "left is One";
    is $p->left(0),    "One",                              "left(0) is One";
    is $p->left(1),    "One",                              "left(1) is One";
    is $p->left(2),    "One::Two",                         "left(2) is One::Two";
    is $p->left(3),    "One::Two::Three",                  "left(3) is One::Two::Three";
    is $p->left(4),    "One::Two::Three::Four",            "left(4) is One::Two::Three::Four";
    is $p->left(5),    "One::Two::Three::Four::Five",      "left(5) is One::Two::Three::Four::Five";
    is $p->left(6),    "One::Two::Three::Four::Five",      "left(6) is One::Two::Three::Four::Five";
    is $p->left(100),  "One::Two::Three::Four::Five",      "left(100) is One::Two::Three::Four::Five";

    is $p->left(-1),   "One::Two::Three::Four",           "left(-1) is One::Two::Three::Four";      
    is $p->left(-2),   "One::Two::Three",                 "left(-2) is One::Two::Three";    
    is $p->left(-3),   "One::Two",                        "left(-3) is One::Two";    
    is $p->left(-4),   "One",                             "left(-4) is One";
    is $p->left(-5),   "main",                            "left(-5) is main";    
    is $p->left(-6),   "main",                            "left(-6) is main";    
    is $p->left(-100), "main",                            "left(-100) is main";    

    is $p->left_but,      "One::Two::Three::Four",        "left_but is One::Two::Three::Four"; 
    is $p->left_but(0),   "One::Two::Three::Four",        "left_but(0) is One::Two::Three::Four";    
    is $p->left_but(1),   "One::Two::Three::Four",        "left_but(1) is One::Two::Three::Four";      
    is $p->left_but(2),   "One::Two::Three",              "left_but(2) is One::Two::Three";    
    is $p->left_but(3),   "One::Two",                     "left_but(3) is One::Two";    
    is $p->left_but(4),   "One",                          "left_but(4) is One";
    is $p->left_but(5),   "main",                         "left_but(5) is main";    
    is $p->left_but(6),   "main",                         "left_but(6) is main";    
    is $p->left_but(100), "main",                         "left_but(100) is main";    

    is $p->left_but(-1),   "One",                         "left_but(-1) is One::Two::Three::Four";      
    is $p->left_but(-2),   "One::Two",                    "left_but(-2) is One::Two::Three";    
    is $p->left_but(-3),   "One::Two::Three",             "left_but(-3) is One::Two";    
    is $p->left_but(-4),   "One::Two::Three::Four",       "left_but(-4) is One";
    is $p->left_but(-5),   "One::Two::Three::Four::Five", "left_but(-5) is main";    
    is $p->left_but(-6),   "One::Two::Three::Four::Five", "left_but(-6) is main";    
    is $p->left_but(-100), "One::Two::Three::Four::Five", "left_but(-100) is main";    

    is $p, __PACKAGE__,  "p is still __PACKAGE__ " . __PACKAGE__;
}

sub right_tests {
    package Uno::Dos::Tres::Cuatro::Cinco;
    use Test::More;
    BEGIN { use_ok $Module }

    my $p = PACKAGE;
    is $p, __PACKAGE__,  "PACKAGE is __PACKAGE__, now " . __PACKAGE__;

    is $p->right,                               "Cinco",    "right is Cinco";
    is $p->right(0),                            "Cinco",    "right(0) is Cinco";
    is $p->right(1),                            "Cinco",    "right(1) is Cinco";
    is $p->right(2),                    "Cuatro::Cinco",    "right(2) is Cuatro::Cinco";
    is $p->right(3),              "Tres::Cuatro::Cinco",    "right(3) is Tres::Cuatro::Cinco";
    is $p->right(4),         "Dos::Tres::Cuatro::Cinco",    "right(4) is Dos::Tres::Cuatro::Cinco";
    is $p->right(5),    "Uno::Dos::Tres::Cuatro::Cinco",    "right(5) is Uno::Dos::Tres::Cuatro::Cinco";
    is $p->right(6),    "Uno::Dos::Tres::Cuatro::Cinco",    "right(6) is Uno::Dos::Tres::Cuatro::Cinco";
    is $p->right(100),  "Uno::Dos::Tres::Cuatro::Cinco",    "right(100) is Uno::Dos::Tres::Cuatro::Cinco";

    is $p->right(-1),        "Dos::Tres::Cuatro::Cinco",    "right(-1) is Dos::Tres::Cuatro::Cinco";
    is $p->right(-2),             "Tres::Cuatro::Cinco",    "right(-2) is Tres::Cuatro::Cinco";
    is $p->right(-3),                   "Cuatro::Cinco",    "right(-3) is Cuatro::Cinco";
    is $p->right(-4),                           "Cinco",    "right(-4) is Cinco";
    is $p->right(-5),   "main",                             "right(-5) is main";
    is $p->right(-6),   "main",                             "right(-6) is main";
    is $p->right(-100), "main",                             "right(-100) is main";

    is $p->right_but(1),        "Dos::Tres::Cuatro::Cinco", "right_but(1) is Dos::Tres::Cuatro::Cinco";
    is $p->right_but(2),             "Tres::Cuatro::Cinco", "right_but(2) is Tres::Cuatro::Cinco";
    is $p->right_but(3),                   "Cuatro::Cinco", "right_but(3) is Cuatro::Cinco";
    is $p->right_but(4),                           "Cinco", "right_but(4) is Cinco";
    is $p->right_but(5),   "main",                          "right_but(5) is main";
    is $p->right_but(6),   "main",                          "right_but(6) is main";
    is $p->right_but(100), "main",                          "right_but(100) is main";

    is $p->right_but(-1),                          "Cinco", "right_but(-1) is Cinco";
    is $p->right_but(-2),                  "Cuatro::Cinco", "right_but(-2) is Cuatro::Cinco";
    is $p->right_but(-3),            "Tres::Cuatro::Cinco", "right_but(-3) is Tres::Cuatro::Cinco";
    is $p->right_but(-4),       "Dos::Tres::Cuatro::Cinco", "right_but(-4) is Dos::Tres::Cuatro::Cinco";
    is $p->right_but(-5),  "Uno::Dos::Tres::Cuatro::Cinco", "right_but(-5) is Uno::Dos::Tres::Cuatro::Cinco";
    is $p->right_but(-6),  "Uno::Dos::Tres::Cuatro::Cinco", "right_but(-6) is Uno::Dos::Tres::Cuatro::Cinco";
    is $p->right_but(-100),"Uno::Dos::Tres::Cuatro::Cinco", "right_but(-100) is Uno::Dos::Tres::Cuatro::Cinco";

    is $p, __PACKAGE__,  "p is still __PACKAGE__ " . __PACKAGE__;
}

sub super_tests {
    package One::Two::Three::Four::Five;
    use Test::More;
    BEGIN { use_ok $Module }

    my $p = PACKAGE;
    is $p, __PACKAGE__,  "PACKAGE is __PACKAGE__, now " . __PACKAGE__;

    is $p->super,         "One::Two::Three::Four",        "super is One::Two::Three::Four";      
    is $p->super(0),      "One::Two::Three::Four",        "super(0) is One::Two::Three::Four";      
    is $p->super(1),      "One::Two::Three::Four",        "super(1) is One::Two::Three::Four";      
    is $p->super(2),      "One::Two::Three",              "super(2) is One::Two::Three";    
    is $p->super(3),      "One::Two",                     "super(3) is One::Two";    
    is $p->super(4),      "One",                          "super(4) is One";
    is $p->super(5),   "main",                            "super(5) is main";    
    is $p->super(6),   "main",                            "super(6) is main";    
    is $p->super(100), "main",                            "super(100) is main";    

    is $p->super(-1),     "One",                          "super(-1) is One";
    is $p->super(-2),     "One::Two",                     "super(-2) is One::Two";
    is $p->super(-3),     "One::Two::Three",              "super(-3) is One::Two::Three";
    is $p->super(-4),     "One::Two::Three::Four",        "super(-4) is One::Two::Three::Four";
    is $p->super(-5),     "One::Two::Three::Four::Five",  "super(-5) is One::Two::Three::Four::Five";
    is $p->super(-6),     "One::Two::Three::Four::Five",  "super(-6) is One::Two::Three::Four::Five";
    is $p->super(-100),   "One::Two::Three::Four::Five",  "super(-100) is One::Two::Three::Four::Five";

    is $p, __PACKAGE__,  "p is still __PACKAGE__ " . __PACKAGE__;
}

#################################################################

run_tests();

__END__
