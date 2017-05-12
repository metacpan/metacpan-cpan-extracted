#!/usr/bin/perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;
use 5.10.1;

use Data::Dumper;
use Test::More;

# }}}
# {{{ variable declarations

my $tests;

my $es          = q{};

# }}}
# {{{ basic tests

BEGIN {
    use_ok('Lingua::Num2Word');
}

$tests++;

use Lingua::Num2Word     qw(preprocess_code
                            known_langs
                            get_interval
                            cardinal);

# }}}

# {{{ preprocess_code

my $o   = Lingua::Num2Word->new;

my $got = Lingua::Num2Word::preprocess_code($o, 'xx');
my $exp = undef;
is($got, $exp, 'prepare code for nonexisting language');
$tests++;

$got = Lingua::Num2Word::preprocess_code();
$exp = undef;
is($got, $exp, 'undef args');
$tests++;

# }}}
# {{{ known_langs - depends on installed modules

# my $konw_langs = [ces, zho, nor];

# $got = known_langs();
# is_deeply($got, $known_langs, 'known langs, scalar context');
# $tests++;

# my @bak = known_langs();
# is_deeply(\@bak, $known_langs, 'known langs, list context');
# $tests++;

# }}}
# {{{ get_interval

$got = get_interval('xx');
$exp = undef;
is($got, $exp, 'Nonexisting language -> got undef');
$tests++;

$got = get_interval();
$exp = undef;
is($got, $exp, 'undef args');
$tests++;

# }}}
# {{{ cardinal

$got = cardinal(undef, 708);
$exp = $es;
is($got, $exp, '708 in undef language');
$tests++;

$got = cardinal();
$exp = $es;
is($got, $exp, 'undef args');
$tests++;

# }}}

done_testing($tests);

__END__
