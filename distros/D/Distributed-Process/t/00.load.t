#!perl -T
use Test::More tests => 9;

BEGIN {
use_ok( 'Distributed::Process' );
use_ok( 'Distributed::Process::Server' );
use_ok( 'Distributed::Process::Interface' );
use_ok( 'Distributed::Process::Master' );
use_ok( 'Distributed::Process::BaseWorker' );
use_ok( 'Distributed::Process::LocalWorker' );
use_ok( 'Distributed::Process::RemoteWorker' );
use_ok( 'Distributed::Process::Worker' );
use_ok( 'Distributed::Process::Client' );
}

diag( "Testing Distributed::Process $Distributed::Process::VERSION" );
