#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Func::Util qw(
    is_array is_hash is_code is_defined is_ref
    is_scalar_ref is_glob is_regex is_blessed
);

# Warmup
for (1..10) {
    is_array([]);
    is_hash({});
}

subtest 'is_array' => sub {
    my $arr = [1, 2, 3];
    no_leaks_ok {
        for (1..1000) {
            my $r = is_array($arr);
            my $r2 = is_array("string");
            my $r3 = is_array(undef);
        }
    } 'is_array does not leak';
};

subtest 'is_hash' => sub {
    my $hash = { a => 1, b => 2 };
    no_leaks_ok {
        for (1..1000) {
            my $r = is_hash($hash);
            my $r2 = is_hash([]);
            my $r3 = is_hash(undef);
        }
    } 'is_hash does not leak';
};

subtest 'is_code' => sub {
    my $code = sub { 42 };
    no_leaks_ok {
        for (1..1000) {
            my $r = is_code($code);
            my $r2 = is_code("string");
            my $r3 = is_code({});
        }
    } 'is_code does not leak';
};

subtest 'is_defined' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_defined(1);
            my $r2 = is_defined(undef);
            my $r3 = is_defined("");
        }
    } 'is_defined does not leak';
};

subtest 'is_ref' => sub {
    my $ref = \my $scalar;
    no_leaks_ok {
        for (1..1000) {
            my $r = is_ref($ref);
            my $r2 = is_ref([]);
            my $r3 = is_ref("string");
        }
    } 'is_ref does not leak';
};

subtest 'is_scalar_ref' => sub {
    my $ref = \my $scalar;
    no_leaks_ok {
        for (1..1000) {
            my $r = is_scalar_ref($ref);
            my $r2 = is_scalar_ref([]);
        }
    } 'is_scalar_ref does not leak';
};

subtest 'is_blessed' => sub {
    my $obj = bless {}, 'MyClass';
    no_leaks_ok {
        for (1..1000) {
            my $r = is_blessed($obj);
            my $r2 = is_blessed({});
            my $r3 = is_blessed("string");
        }
    } 'is_blessed does not leak';
};

subtest 'is_glob' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_glob(*STDOUT);
            my $r2 = is_glob("string");
            my $r3 = is_glob([]);
        }
    } 'is_glob does not leak';
};

subtest 'is_regex' => sub {
    my $regex = qr/test/;
    no_leaks_ok {
        for (1..1000) {
            my $r = is_regex($regex);
            my $r2 = is_regex("string");
            my $r3 = is_regex({});
        }
    } 'is_regex does not leak';
};

done_testing();
