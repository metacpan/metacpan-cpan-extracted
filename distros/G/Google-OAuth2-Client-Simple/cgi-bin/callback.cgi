#!/usr/bin/env perl

use strict;
use warnings;

use CGI;
use Data::Dumper;

use Path::Tiny;
use JSON;

my $json = path('../config.json')->slurp;
my $config = JSON::from_json($json);

use Google::OAuth2::Client::Simple;

my $client = Google::OAuth2::Client::Simple->new(
    client_id => $config->{client_id},
    client_secret => $config->{client_secret},
    redirect_uri => $config->{redirect_uri},
    scopes => $config->{scopes},
);

my $cgi = CGI->new();

print $cgi->header('text/html');

my $token_ref = $client->exchange_code_for_token($cgi->param('code'), $cgi->param('state'));

print Dumper($token_ref);
