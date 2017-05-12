#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::Exception;
use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::CES::Num2Word');
    $tests++;
}

use Lingua::CES::Num2Word           qw(:ALL);

# }}}

# {{{ num2ces_cardinal

my $got = num2ces_cardinal(1);
my $exp = 'jedna';
is($got, $exp, 'one in Czech');
$tests++;

$got = num2ces_cardinal(10);
$exp = 'deset';
is($got, $exp, '10 in Czech');
$tests++;

$got = num2ces_cardinal(13);
$exp = 'třináct';
is($got, $exp, '13 in Czech');
$tests++;

$got = num2ces_cardinal(20);
$exp = 'dvacet';
is($got, $exp, '20 in Czech');
$tests++;

$got = num2ces_cardinal(88);
$exp = 'osmdesát osm';
is($got, $exp, '88 in Czech');
$tests++;

$got = num2ces_cardinal(111);
$exp = 'sto jedenáct';
is($got, $exp, '111 in Czech');
$tests++;

$got = num2ces_cardinal(175);
$exp = 'sto sedmdesát pět';
is($got, $exp, '175 in Czech');
$tests++;

$got = num2ces_cardinal(777);
$exp = 'sedm set sedmdesát sedm';
is($got, $exp, '777 in Czech');
$tests++;

$got = num2ces_cardinal(293_002);
$exp = 'dvě stě devadesát tři tisíce dva';
is($got, $exp, '293 002 in Czech');
$tests++;

$got = num2ces_cardinal(4_000_500);
$exp = 'čtyři miliony pět set';
is($got, $exp, '4 000 500 in Czech');
$tests++;

$got = num2ces_cardinal(999_999_999);
$exp = 'devět set devadesát devět milionů devět set devadesát devět tisíc devět set devadesát devět';
is($got, $exp, '999 999 999 in Czech');
$tests++;

dies_ok(sub { num2ces_cardinal(10_000_000_000_000); }, 'too big');
$tests++;

# }}}

done_testing($tests);

__END__
