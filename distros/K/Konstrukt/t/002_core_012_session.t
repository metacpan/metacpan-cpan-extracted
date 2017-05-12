# check core module: session

#TODO: Apache/Apache2 session handling not testable when not running in an apache

use strict;
use warnings;

use Test::More tests => 2;

#=== Dependencies
use Konstrukt::Settings;
$Konstrukt::Handler->{filename} = "test";
$Konstrukt::Handler->{request} = Konstrukt::Test::Session::Request->new();

#Session
$Konstrukt::Settings->set('session/use' => 1);
$Konstrukt::Settings->set('session/store' => 'File');
$Konstrukt::Settings->set('debug/warn_debug_messages' => '1');
$Konstrukt::Settings->set('debug/warn_error_messages' => '1');

#mod_perl 1
SKIP: {
    eval {
		require Apache::Request;
		require Apache::Cookie;
		die "TODO: not testable";
    };

    skip "Apache::Request and/or Apache::Cookie not installed but needed to test for mod_perl ($@)", 1 if $@;
    
	$ENV{MOD_PERL} = 1;
	require Konstrukt::Session;
	
	$Konstrukt::Session->init();
	
	#print $Konstrukt::Session->session_id();
	is(1,1,"foo");
}

#mod_perl 2
SKIP: {
    eval {
		require Apache2::RequestRec;
		require Apache2::Cookie;
		die "TODO: not testable";
    };

    skip "Apache2::RequestRec and/or Apache2::Cookie not installed but needed to test for mod_perl 2 ($@)", 1 if $@;
    
	$ENV{MOD_PERL} = 2;
	$ENV{MOD_PERL_API_VERSION} = 2;
	require Konstrukt::Session;
	
	$Konstrukt::Session->init();
	
	#print $Konstrukt::Session->session_id();
	is(1,1,"bar");
}

package Konstrukt::Test::Session::Request;

sub new { bless {}, $_[0] }

sub subprocess_env { { REMOTE_ADDR => '1.2.3.4' } }

1;


exit;

#Cache
use Konstrukt::Cache;
$Konstrukt::Cache->init();

#DBI
use Konstrukt::DBI;

#Handler
use Konstrukt::Handler;

#Create file handler
use Konstrukt::Handler::File;

my $filehandler = Konstrukt::Handler::File->new('t/data', 'foo.txt');
#$Konstrukt::Settings->load_settings('/konstrukt.settings');
#my $result = $filehandler->process();
#print $result;

#Apache Handler
#use Konstrukt::Handler::Apache;

#CGI Handler
use Konstrukt::Handler::CGI;

#File Handler
use Konstrukt::Handler::File;
