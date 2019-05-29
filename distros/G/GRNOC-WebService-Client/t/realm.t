use Test::More tests => 6;

use strict;
use GRNOC::WebService::Client;
use Data::Dumper;
use FindBin;

my $config_file = $FindBin::Bin . '/conf/config.xml';

my $realm;

#pick realm from the config file
my $svc = GRNOC::WebService::Client->new( url => "http://localhost:8529/test.cgi",      
                                           config_file => $config_file );
                                            
ok(defined $svc ,"Creating new Client");
                                        
$svc->test();  

#verify default realm is set
$realm = $svc->get_realm();
is($realm, "Default ECP URL", "Default realm is set");

#override default realm from config file
$svc = GRNOC::WebService::Client->new( url => "http://localhost:8529/test.cgi",
                                       realm => "bar",
                                       config_file => $config_file );

$svc->test();
$realm = $svc->get_realm();
is($realm, "bar", "Default realm overwrite");


$svc = GRNOC::WebService::Client->new( url => "http://localhost:8529/test.cgi",
                                       uid => 'test@FOO.ORG',
                                       config_file => $config_file );

$svc->test();
$realm = $svc->get_realm();
is($realm, "FOO ECP URL", "FOO ECP URL Default realm");

$svc = GRNOC::WebService::Client->new( url => "http://localhost:8529/test.cgi",
                                       uid =>  'test@BAR.NET',
                                       config_file => $config_file );

$svc->test();
$realm = $svc->get_realm();
is($realm, "BAR ECP URL", "BAR ECP URL Default realm");

$svc = GRNOC::WebService::Client->new( url   => "http://localhost:8529/test.cgi",
                                       uid   => 'test@FOO.ORG',
                                       config_file => $config_file,
                                       realm => "test" );

$svc->test();
$realm = $svc->get_realm();
is($realm, "test", "Specific realm passed to wsc");

