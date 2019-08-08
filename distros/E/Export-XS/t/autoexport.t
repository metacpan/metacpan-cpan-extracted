use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    package Ex;
    use 5.012;

    use Export::XS::Auto
        CONST1 => 1,
        CONST2 => 2,
    ;
    use Export::XS::Auto CONST3 => 3; # check for no warnings with double autoexport

    sub folded () { 42 }
}

subtest 'constants auto exported' => sub {
    package P1;
    BEGIN { Ex->import }
    main::is CONST1, 1;
    main::is CONST2, 2;
    main::dies_ok { folded() } "functions not exported";
};

subtest 'custom export' => sub {
    package P2;
    BEGIN { Ex->import(qw/folded CONST2/) }
    main::is CONST2, 2;
    main::is folded, 42;
    main::dies_ok { CONST1() };
};

done_testing();
