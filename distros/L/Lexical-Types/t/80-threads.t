#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Lexical::Types' => 'Lexical::Types::LT_THREADSAFE()' ],
);

use Test::Leaner;

my $threads = 10;
my $runs    = 2;

{
 package Lexical::Types::Test::Tag;

 sub TYPEDSCALAR {
  my $tid = threads->tid();
  my ($file, $line) = (caller(0))[1, 2];
  my $where = "at $file line $line in thread $tid";
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::Leaner::is($_[0], __PACKAGE__, "base type is correct $where");
  Test::Leaner::is($_[2], 'Tag', "original type is correct $where");
  $_[1] = $tid;
  ();
 }
}

{ package Tag; }

use Lexical::Types as => 'Lexical::Types::Test::';

sub try {
 my $tid = threads->tid();

 for (1 .. $runs) {
  my Tag $t;
  is $t, $tid, "typed lexical correctly initialized at run $_ in thread $tid";

  eval <<'EVALD';
   use Lexical::Types as => "Lexical::Types::Test::";
   my Tag $t2;
   is $t2, $tid, "typed lexical correctly initialized in eval at run $_ in thread $tid";
EVALD
  diag $@ if $@;

SKIP:
  {
   skip 'Hints aren\'t propagated into eval STRING below perl 5.10' => 3
                                                           unless "$]" >= 5.010;
   eval <<'EVALD';
    my Tag $t3;
    is $t3, $tid, "typed lexical correctly initialized in eval (propagated) at run $_ in thread $tid"
EVALD
  }
 }
}

my @t = map spawn(\&try), 1 .. $threads;

$_->join for @t;

pass 'done';

done_testing;
