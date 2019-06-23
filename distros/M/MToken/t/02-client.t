#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-client.t 75 2019-06-19 15:23:53Z minus $
#
#########################################################################
use Test::More;

use MToken::Client;
use MToken::Const;

plan skip_all => "Currently a developer-only test" unless (-d DIR_ETC);

# Create client
my $client = new MToken::Client(
        url         => "http://localhost/mtoken",
        timeout     => 10, # default: 180
        verbose     => 1, # Show req/res data
    );
#note(explain($client));

plan skip_all => sprintf("Can't initialize the client: %s", $client->error)
    unless $client->status;
plan skip_all => sprintf("Server not running or not configured: %s", $client->error)
    unless $client->check;

# Start testing
plan tests => 3;

# Get list
my $first;
{
    my @list = $client->list();
    ok($client->status, "Get list") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        exit 1;
    };
    $first = shift @list;
}
#note(explain($first));
my $filename = ($first && ref($first) eq 'HASH') ? $first->{filename} : "";

# Get list
my %info = ();
{
    %info = $client->info($filename);
    ok($client->status, "Get info for \"$filename\"") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        exit 1;
    };
    is($filename, $info{filename}, "Filename is valid");
}
#note(explain(\%info));

1;

__END__

EXAMPLE:

    cd altair
    perl ../t/02-client.t

