#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 2;

my $num = 169;	# number of currencies stored

###########################################################

use Finance::Currency::Convert::XE;

my $obj = Finance::Currency::Convert::XE->new()
    || die "Failed to create object\n" ;

my @currencies1 = $obj->currencies;
is(@currencies1, $num);

my $obj2 = Finance::Currency::Convert::XE->new()
    || die "Failed to create object\n" ;

my @currencies2 = $obj2->currencies;
is(@currencies2, $num);

###########################################################

