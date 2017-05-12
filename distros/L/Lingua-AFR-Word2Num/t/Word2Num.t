#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::AFR::Word2Num');
    $tests++;
}

use Lingua::AFR::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $got = w2n('een honderd, drie en twintig');
my $exp = 123;
is($got, $exp, '123 in Afrinkans');
$tests++;

$got = w2n('nege honderd, nege en negentig');
$exp = 999;
is($got, $exp, '999 in Afrikans');
$tests++;

$got = w2n('nonexisting');
$exp = undef;
is($got, $exp, 'nonexisting char -> 0');
$tests++;

# }}}

done_testing($tests);

__END__
