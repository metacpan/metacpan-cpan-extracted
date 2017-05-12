#!/usr/bin/env perl

BEGIN { $ENV{email}='agositin@u.fr'; 
  $ENV{displayName}="Y. Agostini";
  $ENV{eppn}='agositin@u.fr';
  $ENV{primary_affiliation}='employee'; }

use Jifty::Test tests => 10;
use strict;
use warnings;
use Jifty::Test::WWW::Mechanize;


my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "get mainpage" );
$mech->get_ok( $URL . '/protected' , "get protected page" );
$mech->content_contains('<strong>displayName</strong> : Y. Agostini',"displayName set");
#print $mech->content;

#use Data::Dumper;

my $col = TestApp::Model::UserCollection->new();
$col->unlimit();
while ( my $user = $col->next ) {
  is ($user->email, $ENV{email}, "user email set");
  is ($user->name, $ENV{displayName}, "user name set");
  is ($user->shibb_id, $ENV{eppn}, "user shibb_id set");
};

$mech->get_ok( $URL . '/shibblogout' , "logout" );
$mech->content_contains('not currently signed in.',"back to home");
#print $mech->content;
