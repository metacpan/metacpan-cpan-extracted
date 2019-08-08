use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    package Ex;
    use parent 'Export::XS';
    use 5.012;

    use Export::XS { map { ("CONST$_" => $_) } 1..10 };

    sub folded () { 42 }
    sub pizda {state $a = 10; return $a++; }
}

subtest 'exporting all constants' => sub {
    package P1;
    BEGIN { Ex->import }
    main::is CONST1, 1;
    main::is CONST2, 2;
};

subtest 'exporting list' => sub {
    package P2;
    BEGIN { Ex->import(qw/CONST1 CONST3 folded pizda/) }
    main::is CONST1, 1;
    main::is CONST3, 3;
    main::is folded, 42;
    main::dies_ok { CONST2() };
    main::is pizda(), 10;
    main::is pizda(), 11;
    main::is pizda(), 12;
};

subtest 'exporting list + all consts' => sub {
    package P3;
    BEGIN { Ex->import(qw/pizda :const/) }
    main::is CONST9, 9;
    main::is CONST8, 8;
    main::is pizda(), 13;
};

subtest 'no function error' => sub {
    dies_ok { Ex->import('nonexistent') };
};

done_testing();
