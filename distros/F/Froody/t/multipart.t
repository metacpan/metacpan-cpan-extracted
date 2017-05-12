#!/usr/bin/perl
use strict;
use Test::More tests => 8;

#######################################################################
# multipart upload
#######################################################################

use lib 't/lib';
use Froody::Dispatch;
use Froody::Server::Test;
use Testproject::Object;

use FindBin qw( $Bin );

# test that upload works the same for both remote and local
# implementations.

my $direct = Froody::Dispatch->config({modules=>['Testproject::Object']});

for my $client ( Froody::Server::Test->client("Testproject::Object"), $direct ) {

  ok(my $ret = $client->call('testproject.object.upload', file => [ "$Bin/multipart.t" ] ),
    "sent file upload using arrayref");

  is($ret, -s "$Bin/multipart.t", "file was recieved correctly.");

  open my $fh, "$Bin/multipart.t" or die $!;
  my $upload = Froody::Upload->new->fh($fh)->filename("$Bin/multipart.t");
  ok($ret = $client->call('testproject.object.upload', file => $upload ),
    "sent file upload using Froody::Upload");
  
  is($ret, -s "$Bin/multipart.t", "file was recieved correctly.");
}

