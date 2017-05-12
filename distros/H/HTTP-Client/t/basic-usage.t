#!perl

use strict;
use warnings;
use LWP::Online ':skip_all';
use Test::More 0.88 tests => 3;

require_ok('HTTP::Client');

SKIP: {

    ok(client_test(), "check that GET works");
    ok(header_test(), "check headers");

}

sub client_test {
   my $client = HTTP::Client->new("Bot/1.0");
   my $site = $client->get("http://www.cpan.org/");
   return 1 if ($client->status_message =~ /200 OK/);
}

sub header_test {
   my $client = HTTP::Client->new("NewBot/1.0");
   my $site = $client->get("http://www.cpan.org/");
   my @headers = $client->response_headers;
   return 1 if (@headers);
}

