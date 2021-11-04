#!/usr/bin/env perl

# It would be really nice to use the package-manipulating
# facilities these modules provide for all this, but that
# would defeat the purpose of testing.

use t::setup;

use FindApp::Utils qw(function blessed);

our(@IMPORTS, @SIB_FUNCS, @SORT_FUNCS); BEGIN {
   @SIB_FUNCS  = <{sub,sib,top}package>; 
   @SORT_FUNCS = <sort_packages{,_{lex,numer}ically}>;
   @IMPORTS   = (@SIB_FUNCS, @SORT_FUNCS);
}

my $Module; BEGIN {
   $Module = "FindApp::Utils::Package";
   local @IMPORTS = (PACKAGE => @IMPORTS);
   use_ok($Module, @IMPORTS) 
       ? note("import $Module @IMPORTS")
       : die "can't continue if main module $Module won't import @IMPORTS correctly, bailing out";
}

my $WANTARRAY = qr/need.*list context/;
my $HATEVOID  = qr/useless use of \w+ in void context/;
my $LISTARGS  = qr/need list of \w+packages to generate/;
my $WANTHATE  = qr/$WANTARRAY|$HATEVOID/;

my %PREFIX_TO_PACKAGE = (
    top => "Rip",
    sib => "Rip::Van",
    sub => "Rip::Van::Winkle",
);

for my $PREFIX (sort keys %PREFIX_TO_PACKAGE) {
    my $SHORT_PACKAGE = $PREFIX_TO_PACKAGE{$PREFIX};
    my $FUNC_NAME = $PREFIX . "package";

    # BUILD: subpackage_tests, sippackage_tests, toppackage_tests
    function "${FUNC_NAME}_tests" => sub {
        my @pieces = qw(Fee Fie Foe Fum);
        throws_ok { 
            no strict "refs";
            my $scalar = $FUNC_NAME->(@pieces) 
        } $WANTARRAY, "asking for multiple ${PREFIX}packages in scalar context throws $WANTARRAY";
        my @some_packages = do {
            package Rip::Van::Winkle;
            use Test::More;
            import $Module $FUNC_NAME;
            ok(1, "imported $FUNC_NAME into Rip::Van::Winkle");
            no strict "refs";
            $FUNC_NAME->(@pieces);
        };
        ok !blessed, "$_ isn't blessed after $FUNC_NAME" for @some_packages;
        my %seen = map { $_ => 1 } @some_packages;
        for my $piece (@pieces) {
            my $pack = $SHORT_PACKAGE;
            my $mod  = $pack . "::$piece";
            cmp_ok($seen{$mod}, "==", 1, "found ${PREFIX}package $mod just once");
        }
    };

}

sub make_pack_list { map { map { join "::" => split } split /\R/ } @_ }

sub ordering_tests {

    # This list is actually in dictionary-sort order,
    # so it ignores the non-letters. That's the
    # default Unicode sort, and we don't want that.
    my @dict_sort = qw(
        ABBA
        ABBA::DABBA
        AB::CD
        A::B::C::D::E::F
        A::B::CD::EF
        A::B::CDEF
        A::BC::D::EF
        A::BCD::E::F
        AB::CD::EF
        ABC::DEF
    );

    note "resorting the dict-sorted  @dict_sort";

    my @lex_have = sort_packages_lexically(@dict_sort);
    my @lex_want = make_pack_list<<\SYZYGY;
        A       B       C       D       E       F
        A       B       CD      EF
        A       B       CDEF
        A       BC      D       EF
        A       BCD     E       F
        AB      CD
        AB      CD      EF
        ABBA
        ABBA    DABBA
        ABC     DEF
SYZYGY

    (is_deeply \(@lex_have, @lex_want) => "sort {cmp} packages: @lex_have vs @lex_want")
        || diag "failed lexical sort got @lex_have";

    my @num_have = sort_packages_numerically(@dict_sort);
    my @num_want = make_pack_list<<\XYLYLIC;
        ABBA
        AB      CD
        ABBA    DABBA
        ABC     DEF
        A       B       CDEF
        AB      CD      EF
        A       B       CD      EF
        A       BC      D       EF
        A       BCD     E       F
        A       B       C       D       E       F
XYLYLIC

    (is_deeply \(@num_have, @num_want) => "sort {<=>} packages: @num_want")
        || diag "failed spaceship sort got @num_have";

    ok !blessed, "resulting $_ isn't blessed after <=> sort" for @num_have;
    ok !blessed, "resulting $_ isn't blessed after cmp sort" for @lex_have;

}

sub scalar_exception_tests {
    for my $func (@IMPORTS) {
        throws_ok { 
            no strict "refs";
            my $oops = $func->(<BAD NEWS BEARS>);
        } $WANTARRAY, "calling $func in scalar context throws $WANTARRAY";
        throws_ok { 
            no strict "refs";
            $func->(<DIE DIE DIE>);
            1;
        } $WANTHATE, "calling $func in void context throws $WANTHATE";
    }

}

sub empty_args_exception_tests {
    for my $func (@SIB_FUNCS) {
        throws_ok { 
            no strict "refs";
            my @nada = $func->();
        } $WANTARRAY, "calling $func without args throws $WANTARRAY";
        throws_ok { 
            no strict "refs";
            $func->();
            1;
        } $HATEVOID, "calling $func without args in void context still throws $HATEVOID";
    }
}

# Not many OO tests here, just enough to show we got what
# we were supposed to.  The OO tests for these are elsewhere.
sub PACKAGE_tests {
    my $p = PACKAGE;
    is $p, __PACKAGE__, "PACKAGE is ".__PACKAGE__;

    package Not::Main;
    use Test::More;
    use FindApp::Utils qw(blessed);

    $Module->import("PACKAGE");
    $p = PACKAGE();
    is $p, __PACKAGE__, "PACKAGE is now ".__PACKAGE__;
    ok blessed($p), "$p is blessed";

    my $s = $p->unbless;
}

run_tests();
