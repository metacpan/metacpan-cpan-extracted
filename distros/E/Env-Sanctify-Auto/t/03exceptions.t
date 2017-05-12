#!/usr/bin/perl -T

# t/03exceptions.t
#  Tests fast errors produced with obvious mistakes
#
# $Id: 03exceptions.t 8622 2009-08-18 04:46:41Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Env::Sanctify::Auto;

# Incorrectly called methods
{
  my $obj = Env::Sanctify::Auto->new();
  eval { $obj->new(); };
  ok($@, '->new called as an object method');

  eval {
    Env::Sanctify::Auto->new([ 'Blah' ]);
  };
  ok($@, '->new called with an ARRAY ref');
}
