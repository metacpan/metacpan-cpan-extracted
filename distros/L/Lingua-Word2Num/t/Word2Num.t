#!/usr/bin/perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;
use 5.10.0;

use Test::More;

# }}}
# {{{ variable declarations

my $tests;
# my $known_langs = [qw(afr ces deu eng eus fra ind
#                      ita jpn nld nor pol por rus spa swe zho)];

# }}}
# {{{ basic tests

BEGIN {
   use_ok('Lingua::Word2Num');
}

$tests++;

use Lingua::Word2Num     qw(:ALL);

# }}}
# {{{ preprocess_code

my $got      = Lingua::Word2Num::preprocess_code();
my $expected = undef;
is($got, $expected, 'undef args');
$tests++;

$got      = Lingua::Word2Num::preprocess_code(undef, 'xx'),
$expected = undef;
is($got, $expected, 'nonexisting language');
$tests++;

# }}}
# {{{ known_langs - depends on installed modules

# my $bak = known_langs();
# is_deeply($bak, $known_langs, 'known langs');
# $tests++;

# }}}
# {{{ cardinal

$got      = cardinal(undef, 'five');
$expected = q{};
is($got, $expected, 'five in undef language');
$tests++;

$got      = cardinal();
$expected = q{};
is($got, $expected, 'undef args');
$tests++;

# }}}

done_testing($tests);

__END__

