#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Identifier::PL::PESEL;


subtest 'constructor' => sub {
    plan 'tests' => 2;

    my $p;
    lives_ok { $p = Identifier::PL::PESEL->new() } 'constructor';
    isa_ok $p, 'Identifier::PL::PESEL';
};

subtest 'validate' => sub {
    plan 'tests' => 10;

    my $p;
    lives_ok { $p = Identifier::PL::PESEL->new() } 'constructor';

    ok $p->validate( '02070803628' ), 'correct pesel number';

    ok !$p->validate( '00000000000' ), 'incorrect pesel number';
    ok !$p->validate( '02070803627' ), 'incorrect pesel number';
    ok !$p->validate( '0207080362' ), 'incorrect pesel number';
    ok !$p->validate( 'abc' ), 'incorrect pesel number';
    ok !$p->validate( ' ' ), 'incorrect pesel number';
    ok !$p->validate( '' ), 'incorrect pesel number';
    ok !$p->validate( 0 ), 'incorrect pesel number';

    dies_ok { $p->validate( undef ) } 'incorrect pesel number';
};