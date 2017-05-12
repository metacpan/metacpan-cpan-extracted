#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);

use_ok('Metaweb');
can_ok('Metaweb', 'new');

my $mw = Metaweb->new();
isa_ok($mw, 'Metaweb');

my $mw_with_login = Metaweb->new({ username => 'foo', password => 'bar'});
is($mw_with_login->username, 'foo', 'set username via new');
is($mw_with_login->password, 'bar', 'set password via new');

$mw_with_login->username('baz');
is($mw_with_login->username, 'baz', 'set username with accessor');

# not testing login because, duh, I don't want to hand around my
# credentials.  But we don't need it any more, w00t.

$mw->json_query({
    type => 'read',
    query => q(
        {
          "albums": {
            "query": {
              "type":"/music/artist",
              "name":"The Police",
              "album":[]
            }
          }
        }
    ),
});
my $raw_result = $mw->raw_result();

# this will fail if the Police's first album changes.  It seems unlikely.
like($raw_result, qr("album": \[\s+"Outlandos d'Amour",), 
    "picked up first album from raw results");

my $res = $mw->query({
    name => 'albums',
    query => {
        type => "/music/artist",
        name => "The Police",
        album => [],
    },
});
isa_ok($res, 'Metaweb::Result');

# this will fail if the Police's first album changes.  It seems unlikely.
is($res->{content}->{album}->[0], "Outlandos d'Amour", 
    "picked up first album from results");

