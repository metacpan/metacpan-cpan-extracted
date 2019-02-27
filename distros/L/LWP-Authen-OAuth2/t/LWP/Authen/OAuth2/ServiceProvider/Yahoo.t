#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";

BEGIN {
  use_ok("LWP::Authen::OAuth2::ServiceProvider::Yahoo") || print "Bail out!\n";
  use LWP::Authen::OAuth2;

  my $oauth2 = LWP::Authen::OAuth2->new(
                                        client_id => "test",
                                        client_secret => "test",
                                        service_provider => "Yahoo",
                                        redirect_url => "oob",
                                       );
  isa_ok($oauth2, "LWP::Authen::OAuth2");
}

done_testing();
