# -*- mode: Perl; -*-
package SupportArgumentsTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Eve::Exception;
use Eve::Support;

sub test_no_arguments : Test {
    Eve::Support::arguments({});
    ok(1);
}

sub test_1_argument : Test {
    Eve::Support::arguments({a => 1}, my $a);
    ok($a == 1);
};

sub test_2_arguments : Test {
    Eve::Support::arguments({a => 1, b => 2}, my ($a, $b));
    ok($a == 1 and $b == 2);
};

sub test_default_value : Test {
    Eve::Support::arguments({}, my $a = 1);
    ok($a == 1);
};

sub test_default_value_undef : Test {
    Eve::Support::arguments({}, my $a = \undef);
    ok(not defined($a));
};

sub test_default_value_reassing : Test {
    Eve::Support::arguments({a => 2}, my $a = 1);
    ok($a == 2);
};

sub test_default_value_reassing_2nd : Test {
    Eve::Support::arguments({a => 2, b=> 3}, my $a, my $b = 1);
    ok($a == 2 and $b == 3);
};

sub test_default_value_reassing_after_group : Test {
    Eve::Support::arguments(
        {a => 2, b=> 3, c => 4}, my ($a, $b), my $c = 1);
    ok($a == 2 and $b == 3 and $c = 4);
};

sub test_required_argument : Test {
    throws_ok(
        sub { Eve::Support::arguments({}, my $a) },
        qr/Required argument: a/);
};

sub test_redundant_argument : Test(2) {
    throws_ok(
        sub { Eve::Support::arguments({a => 1}) },
        'Eve::Error::Attribute');
    ok(Eve::Error::Attribute->caught()->message =~
       /Redundant argument\(s\): a/);
};

sub test_redundant_arguments_mixed : Test(2) {
    throws_ok(
        sub { Eve::Support::arguments({a => 1, b => 2, c => 3}, my $a) },
        'Eve::Error::Attribute');
    ok(Eve::Error::Attribute->caught()->message =~
       qr/Redundant argument\(s\): b, c/);
};

sub test_wrong_variable : Test(2) {
    throws_ok(
        sub { Eve::Support::arguments({}, 1) },
        'Eve::Error::Attribute');
    ok(Eve::Error::Attribute->caught()->message =~
       qr/Could not get a variable for a named argument/);
}

sub test_array : Test {
    Eve::Support::arguments({a => [1, 2]}, my $a);
    ok($a->[0] == 1 and $a->[1] == 2);
};

sub test_rest_hash : Test {
    my $rest_hash = Eve::Support::arguments(
        {a => 1, b => 2, c => 3}, my $a);
    ok($rest_hash->{'b'} == 2 and $rest_hash->{'c'} == 3);
};

1;
