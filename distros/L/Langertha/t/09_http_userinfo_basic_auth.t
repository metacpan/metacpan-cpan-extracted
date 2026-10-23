#!/usr/bin/env perl
# ABSTRACT: Basic-Auth from URL userinfo keeps colons, decodes %-escapes, accepts "0"
use strict;
use warnings;
use Test2::Bundle::More;

{
  package TestHTTP;
  use Moose;
  with 'Langertha::Role::JSON', 'Langertha::Role::HTTP';
  has url => ( is => 'ro' );
}

# karr k377: the userinfo of an engine URL became a Basic header via
# split /:/ without limit, no unescape and a truth test. A password with ':'
# was cut, a %-encoded one went out encoded, and user/password "0" sent the
# request unauthenticated with the userinfo already stripped from the URL.

my $t = TestHTTP->new( url => 'x' );

my @cases = (
  [ 'http://user:pa:ss@h/x',   'user', 'pa:ss', 'colon in the password survives' ],
  [ 'http://user:p%40ss@h/x',  'user', 'p@ss',  'percent-encoded password is decoded' ],
  [ 'http://user:0@h/x',       'user', '0',     'password "0" still authenticates' ],
  [ 'http://0:secret@h/x',     '0',    'secret', 'user "0" still authenticates' ],
);
for my $case (@cases) {
  my ( $url, $user, $pass, $name ) = @$case;
  my $req = $t->generate_http_request( GET => $url, sub {} );
  my ( $got_user, $got_pass ) = $req->authorization_basic;
  is $got_user, $user, "$name: user";
  is $got_pass, $pass, "$name: password";
  unlike $req->uri->as_string, qr/\@/, "$name: userinfo is stripped from the URL";
}

my $plain = $t->generate_http_request( GET => 'http://h/x', sub {} );
ok !defined $plain->header('Authorization'), 'no userinfo, no Authorization header';

done_testing;
