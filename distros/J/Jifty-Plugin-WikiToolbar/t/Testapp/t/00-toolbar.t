#!/usr/bin/env perl
use Jifty::Test tests => 7;
use strict;
use warnings;
use Jifty::Test::WWW::Mechanize;
 
 
my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "get mainpage" );
$mech->content_contains('rows="15"','rows = 15 for wikitoolbar textarea');
$mech->content_contains("jQuery('#JAF-oldrender-texts-",'oldrender');
$mech->content_contains("jQuery('#JAF-newrender-texts-",'newrender');
$mech->get_ok( $URL . '/static/img/wt/bold.png' , "get share element" );
#print $mech->content;
