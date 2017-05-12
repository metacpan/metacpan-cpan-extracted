#!/usr/bin/env perl
use Jifty::Test tests => 6;
use strict;
use warnings;
use Jifty::Test::WWW::Mechanize;


my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "get mainpage" );
$mech->get_ok( $URL . '/media_manage_page' , "get media_manage_page" );
$mech->content_contains('collapseSpeed: 300',"write js");
$mech->get_ok( $URL . '/static/css/FTimages/folder_add.png' , "get share element" );
#print $mech->content;
