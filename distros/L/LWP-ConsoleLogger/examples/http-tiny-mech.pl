#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Tiny::Mech;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use MetaCPAN::Client;
use WWW::Mechanize;

my $ua
    = WWW::Mechanize->new( headers => { 'Accept-Encoding' => 'identity' } );
my $logger = debug_ua($ua);

my $wrapped_ua = HTTP::Tiny::Mech->new( mechua => $ua );

my $mcpan  = MetaCPAN::Client->new( ua => $wrapped_ua );
my $author = $mcpan->author('XSAWYERX');

=pod

Use HTTP::Tiny::Mech for objects which are expecting an HTTP::Tiny object.  Set
the 'Accept-Encoding' header as above.  See
https://github.com/kentnl/HTTP-Tiny-Mech/pull/2#issuecomment-49833651 for
further discussion.

=cut
