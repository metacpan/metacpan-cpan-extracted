#!perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::Transaction::Single;
use Test::More tests => 4;

use_ok('DayDayUp');

# Prepare client and transaction
my $client = Mojo::Client->new;
my $tx     = Mojo::Transaction::Single->new_get('/');

# Process request
$client->process_app('DayDayUp', $tx);

# Test response
is($tx->res->code, 200);
is($tx->res->headers->content_type, 'text/html');
ok($tx->res->content->body_contains('DayDayUp'));
