# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN { plan tests => 4 };
use Lingua::TR::Hyphenate;
ok(1); # If we made it this far, we're ok.

#########################

my @syllables = Lingua::TR::Hyphenate::hyphenate('bilgisayar');
ok('bil.gi.sa.yar', join('.', @syllables));

my $hyphenated = Lingua::TR::Hyphenate::hyphenate('kusturucu',
                                {Separator=>'#'});
ok('kus#tu#ru#cu', $hyphenated);

$hyphenated = Lingua::TR::Hyphenate::hyphenate('sssss');
ok(!defined($hyphenated));
