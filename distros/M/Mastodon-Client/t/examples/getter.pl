#!/usr/bin/env perl

binmode STDOUT, ':utf8';

use warnings;
use strict;
use diagnostics;

use Mastodon::Client;
use Config::Tiny;

use Log::Any::Adapter;
my $log = Log::Any::Adapter->set( 'Stderr',
  category => 'Mastodon',
  log_level => 'warn',
);

unless (scalar @ARGV) {
  print "  Missing arguments
  USAGE: $0 <CONFIG>

  <CONFIG> should be an INI file with a valid 'client_secret', 'client_id', and
  'access_token', and an 'instance' key with the URL to a Mastodon instance.\n";
  exit(1);
}

my $config = (scalar @ARGV) ? Config::Tiny->read( $ARGV[0] )->{_} : {};
my $client = Mastodon::Client->new({
  %{$config},
  coerce_entities => 0,
});

use Data::Dumper;
print Dumper($client->get( $ARGV[1] )), "\n";
