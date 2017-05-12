#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use Gerrit::Client::Test;
use Test::More;

sub run
{
  if (!$ENV{ GERRIT_WAR }) {
    plan skip_all => "Gerrit system tests are not enabled";
    return;
  }

  my $testdir = "$FindBin::Bin/gerrit";
  my $gerrit = Gerrit::Client::Test->ensure_gerrit_installed(
    war => $ENV{ GERRIT_WAR },
    dir => $testdir,
  );
  return unless $gerrit;

  $gerrit->ensure_gerrit_stopped();

  return;
}

if (!caller) {
  run;
  done_testing;
}
