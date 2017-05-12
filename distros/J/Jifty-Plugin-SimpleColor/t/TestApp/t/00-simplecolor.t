#!/usr/bin/env perl
use Jifty::Test tests => 5;
use strict;
use warnings;
use Jifty::Test::WWW::Mechanize;


my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "get mainpage" );
$mech->content_contains('.colorPicker()');
$mech->get_ok( $URL . '/static/css/colorPicker/arrow.gif' , "get share element" );
#print $mech->content;
