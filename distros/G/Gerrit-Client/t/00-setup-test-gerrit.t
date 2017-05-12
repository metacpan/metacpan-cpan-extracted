#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use Gerrit::Client::Test;
use Test::More;

sub run
{
  if (!$ENV{ GERRIT_WAR }) {
    plan skip_all =>
      "To run Gerrit system tests, set GERRIT_WAR to the URL of a gerrit.war "
     ."to use for testing, or set to 1 to automatically download gerrit.war";
    return;
  }

  if ($ENV{ GERRIT_WAR } eq '1') {
    delete $ENV{ GERRIT_WAR };
  }

  my $testdir = "$FindBin::Bin/gerrit";
  my $gerrit = Gerrit::Client::Test->ensure_gerrit_installed(
    war => $ENV{ GERRIT_WAR },
    dir => $testdir,
  );
  ok( $gerrit, "gerrit set up at $testdir" )
    || BAIL_OUT( 'gerrit installation failed; cannot continue' );
  ok( $gerrit->ensure_gerrit_running(), 'gerrit running' )
    || BAIL_OUT( "can't launch gerrit" );

  diag( 'test gerrit instance: ', explain( $gerrit ) );
  return;
}

run() unless caller;
done_testing;
