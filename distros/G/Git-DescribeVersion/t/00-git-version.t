# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use inc::GitVersion ();

subtest sanity_check => sub {
  ok( inc::GitVersion->check_minimum("1.5.5"), 'exact version' );
  ok( inc::GitVersion->check_minimum("1.5.6"), 'greater version' );
  ok(!inc::GitVersion->check_minimum("1.5.4"), 'lesser version' );
  ok(!inc::GitVersion->check_minimum("1.4.4"), 'much lesser version' );
  ok( inc::GitVersion->check_minimum("2.2.2"), 'much greater version' );
};

my $version = inc::GitVersion->version;

diag $version;

ok( inc::GitVersion->check_minimum($version), 'minimum version' );

done_testing;
