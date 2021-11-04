#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-client.t 101 2021-10-09 18:57:43Z minus $
#
#########################################################################
use Test::More;
use Mojo::File qw/path/;
use CTK::Util qw/dtf/;
use MToken::Const;
use MToken::Client;

use constant BASE_URLS => [
        'http://localhost:8642/',
        'https://localhost:8642/',
        'http://localhost/',
    ];

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

# Create the instance
my $client;
my $base_url;
for (@{(BASE_URLS)}) {
    $base_url = $_;
    $client = MToken::Client->new(
        url                 => $base_url,
        insecure            => 1, # IO::Socket::SSL::set_defaults(SSL_verify_mode => 0); # Skip verify for test only!
        pwcache             => PWCACHE_FILE,
        max_redirects       => 2,
        connect_timeout     => 3,
        inactivity_timeout  => 5,
        request_timeout     => 10,
    );
    last if $client->check(); # Check
}
plan skip_all => "Can't initialize the client" unless $client->status;
#note $client->trace;

# Start testing
plan tests => 5;

# Prepare file
my $filename = dtf(TARBALL_FORMAT, time());
my $filepath = path($filename);
path("LICENSE")->copy_to($filename);
die("Can't prepare test file") unless $filepath->stat->size;

# Upload (PUT method)
{
    my $status = $client->upload(test => $filename);
    ok($status, "Put file to test token server location")
        or diag($client->res->json("/message") || $client->res->message);
    note $status ? $client->res->body : $client->trace;
}
#note $client->trace;
#note $client->res->body;

# General info (GET method)
{
    my $status = $client->info();
    #my $url = $base_url->clone->path("/mtoken/test");
    #my $res = $ua->get($url)->result;
    ok($status, "Get list of tokens")
        or diag($client->res->json("/message") || $client->res->message);
    note $status ? explain($client->res->json("/tokens")) : $client->trace;

}

# General list (GET method)
{
    my $status = $client->info("test");
    #my $url = $base_url->clone->path("/mtoken/test");
    #my $res = $ua->get($url)->result;
    ok($status, "Get list files of test token")
        or diag($client->res->json("/message") || $client->res->message);
    note $status ? explain($client->res->json("/files")) : $client->trace;
}
$filepath->remove;

# Download file (GET method)
{
    my $status = $client->download(test => $filename);
    ok($status, "Download file from token server location")
        or $client->res->message;
    note $client->trace;
}

# DELETE method
{
    my $status = $client->remove(test => $filename);
    ok($status, "Delete file from token server location")
        or diag($client->res->json("/message") || $client->res->message);
    note $status ? $client->res->body : $client->trace;
    $filepath->remove if $status;
}

1;

__END__
