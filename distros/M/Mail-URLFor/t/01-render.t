#!perl
use strict;
use warnings;
use Test::More tests => 9;

use Data::Dumper;

use Mail::URLFor;

# We'll assume that all plugins load OK here, even though they haven't
# been written by ourselves
my $links = Mail::URLFor->new();

my @distributed_clients = (qw(
    Gmail Thunderlink OSX RFC2392
));

my $c = $links->clients;
cmp_ok 0+@$c, '>=', 0+@distributed_clients, "We load the included plugins";

my $messageid = '12345.abcdef@example.com';
my $urls = $links->urls_for($messageid);

is $urls->{'Gmail'}, 'https://mail.google.com/mail/#search/rfc822msgid%3A12345.abcdef%40example.com', "Gmail plugin renders"
    or diag Dumper $urls;
is $urls->{'Thunderlink'}, 'thunderlink://messageid=12345.abcdef%40example.com', "Thunderlink plugin renders"
    or diag Dumper $urls;
is $urls->{'OSX'}, 'message:%3C12345.abcdef@example.com%3E', "OSX plugin renders"
    or diag Dumper $urls;
is $urls->{'RFC2392'}, 'mid:12345.abcdef@example.com', "RFC 2392 plugin renders"
    or diag Dumper $urls;

for my $client (@distributed_clients) {
    is $links->url_for($messageid, $client), $urls->{$client}, "->url_for(..., $client) works identically to ->urls_for";
};

done_testing;