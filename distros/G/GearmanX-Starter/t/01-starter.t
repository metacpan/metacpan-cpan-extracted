#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{GEARMAN_LIVE_TEST} ) {
  plan( skip_all => 'Set $ENV{GEARMAN_LIVE_TEST} to run this test' );
}

my $res = eval "use Net::Telnet::Gearman 0.02; 1";
unless ($res) {
  plan( skip_all => 'Net::Telnet::Gearman 0.02 required to run this test' );
}

plan tests => 5;

use_ok( 'GearmanX::Starter' );
use_ok( 'Gearman::XS', ':constants' );
use_ok( 'Gearman::XS::Client' );

my $gms = GearmanX::Starter->new;
my $f = sub {
  my $job = shift;

  my $workload = $job->workload();
  my $result   = reverse($workload);

  return $result;
};

$gms->start({
  name => 'GMXSReverseTest',
  func_list => [
    [ 'GMSXReverseTest', $f ],
  ],
});

my $client = Gearman::XS::Client->new();
my $ret = $client->add_server();
is($ret, Gearman::XS::GEARMAN_SUCCESS(), 'Add server to Gearman Client');
my $test_string = "foobar";
my $test_result = reverse $test_string;
($ret, my $result) = $client->do( 'GMSXReverseTest', $test_string );
is($result, $test_result, 'Reverse string');
