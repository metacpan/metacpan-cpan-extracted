#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Carp 'confess';
use Log::Any;
use Log::Any::Adapter;
use Log::Any::Adapter::Util ':levels';

use_ok( 'Log::Any::Adapter::Daemontools' ) || BAIL_OUT;

my $cfg= Log::Any::Adapter::Daemontools->new_config;
my $log= Log::Any->get_logger(category => 'testing');
Log::Any::Adapter->set({ category => qr/^testing$/ }, 'Daemontools', config => $cfg );


my ($method, $level, $message, @message);
$cfg->writer(sub {
	is( $_[0]->category, 'testing', 'correct category' );
	is( $_[1], $level, 'correct level' );
	$message= $_[2];
});

my @tests= (
	[ 'info', 'info',    "info-message" ],
	[ 'warn', 'warning', "aliased" ],
	[ 'err',  'error',   "with\nnewlines\n" ],
	[ 'err',  'error',   "multiple", "parts" ],
);
for (@tests) {
	($method, $level, @message)= @$_;
	my $message_pattern= qr/^@{[ join(' ?', @message) ]}$/;
	subtest $message_pattern => sub {
		$log->$method(@message);
		like( $message, $message_pattern, 'writer received message' );
	};
}

done_testing;
