#!perl -w

use Test;
use IPC::Run3::ProfArrayBuffer;
use strict;

my $b = IPC::Run3::ProfArrayBuffer->new;

my @tests = (
  sub {
      $b->app_call( 1 );
      ok 0+$b->get_events, 1;
  },

  sub {
      ok( ($b->get_events)[0]->[1], 1 );
  },
);

plan tests => 0+@tests;

$_->() for @tests;
