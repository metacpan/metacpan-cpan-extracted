#!/usr/local/bin/perl
#################################################################
#
#   $Id: 02_test_irr_errors.t,v 1.2 2007/07/11 09:01:12 erwan_lemonnier Exp $
#
#   @author       erwan lemonnier
#   @description  test xirr against garbage input
#   @system       pluto
#   @function     base
#   @function     vf
#

use strict;
use warnings;
use Test::More tests => 20;
use lib "../lib/";

use_ok('Finance::Math::IRR');

#local $Finance::Math::IRR::DEBUG = 1;

my $v;

# test error handling
eval { xirr(); };
ok( (defined $@ && $@ =~ /odd number of arguments/), "test check of argument number");

eval { xirr(1,2,3); };
ok( (defined $@ && $@ =~ /odd number of arguments/), "test check of argument number");

eval { xirr('bob' => undef); };
ok( (defined $@ && $@ =~ /contains undefined values/), "test check of undefined arguments in cashflow");

eval { xirr('precision' => undef, '2001-01-01' => 5, '2002-01-02'=> -6); };
ok( (defined $@ && $@ =~ /precision is not a valid number/), "test check of undefined precision");

eval { xirr('precision' => 1.32); };
ok( (defined $@ && $@ =~ /you provided an empty cash flow/), "test check of empty cashflow");

eval { xirr('precision' => 1.32, 'bilou' => 1); };
ok( (defined $@ && $@ =~ /invalid date/), "test check of dates in cashflow");

eval { xirr('precision' => 1.32, '2001-11-01' => 'abc'); };
ok( (defined $@ && $@ =~ /invalid amount/), "test check of amounts in cashflow");

# small cashflow => undef or 0% if amount = 0
eval { $v = xirr('precision' => 1.32, '2001-11-01' => 0); };
ok( !$@, "cashflow with only one 0 transaction => does not die");
is( $v, 0, "cashflow with only one 0 transaction => irr = 0");

eval { $v = xirr('precision' => 1.32, '2001-11-01' => -12.3); };
ok( !$@, "cashflow with only 1 non 0 transaction => does not die");
is( $v, undef, "cashflow with only 1 non 0 transaction => irr = undef");

# a working case
eval { $v = xirr('precision' => 1.32, '2001-01-01' => 10, '2002-01-01' => -20); };
ok( (!defined $@ || $@ eq ''), "test with valid arguments");
is($v,1,"and this simple cashflow has a 100% growth");

# check last transaction
eval { $v = xirr('precision' => 1.32, '2001-01-01' => 10, '2002-01-01' => 20); };
ok( !defined $@ || $@ eq "", "last transaction has positive amount");
is($v,-3, "correct answer");

# cashflows with end transaction 0
eval { $v = xirr('precision' => 0.001,
		 '2001-01-01' => 0,
		 '2001-03-01' => 0,
		 '2001-06-01' => 0
		 ); };
ok( (!defined $@ || $@ eq ''), "cashflow made of only 0 transactions [$@]");
is($v,0,"irr = 0%");

# cashflows with start transactions 0
eval { $v = xirr('precision' => 0.001,
		 '2001-01-01' => 0,
		 '2001-03-01' => 0,
		 '2001-06-01' => 0,
		 '2002-01-01' => 10,
		 '2002-06-20' => 0,
		 '2003-01-01' => -20);
   };

ok( (!defined $@ || $@ eq ''), "a valid cashflow");
is($v,1,"heading 0 transactions were properly filtered away");










