#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

my %on;
sub my_exit (;$) {
  my $sub = $on{exit} or return CORE::exit(@_);
  $sub->(@_);
}
BEGIN {
  *CORE::GLOBAL::exit = \&my_exit;
}

require Devel::NoGlobalSig;

{
  no warnings 'redefine';
  my $was = \&Carp::carp;
  *Carp::carp = sub {
    my $sub = $on{carp} or goto $was;
    $sub->(@_);
  };
}

# deletion explodes
{
  my $msg;
  my $exit;
  local $on{exit} = sub {$exit = 1};
  local $on{carp} = sub {$msg = join("\n", @_)};
  delete($SIG{__WARN__});
  Devel::NoGlobalSig->import('warn');
  ok(exists($SIG{__WARN__}));
  delete($SIG{__WARN__});
  ok($exit);
  like($msg, qr/^BZZT: .*{__WARN__}/);
}

# overwriting explodes
{
  my $msg;
  my $exit;
  local $on{exit} = sub {$exit = 1};
  local $on{carp} = sub {$msg = join("\n", @_)};
  delete($SIG{__WARN__});
  Devel::NoGlobalSig->import('warn');
  ok(exists($SIG{__WARN__}));
  $SIG{__WARN__} = sub {print "puppies!\n"};
  ok($exit);
  like($msg, qr/^BZZT: .*{__WARN__}/);
}

# no explosion with local
{
  my $msg;
  my $exit;
  local $on{exit} = sub {$exit = 1};
  local $on{carp} = sub {$msg = join("\n", @_)};
  delete($SIG{__WARN__});
  Devel::NoGlobalSig->import('warn');
  ok(exists($SIG{__WARN__}));
  {
    local $SIG{__WARN__} = sub {print "puppies!\n"};
    ok(1)
  }
  ok(! $exit);
  ok(! $msg);
  delete($SIG{__WARN__});
  ok($exit);
  like($msg, qr/^BZZT: .*{__WARN__}/);
}


# vim:ts=2:sw=2:et:sta
