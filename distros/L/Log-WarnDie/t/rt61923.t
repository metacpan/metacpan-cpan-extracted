#!perl -w

use strict;
use warnings;
use Test::Most;

# See https://rt.cpan.org/Public/Bug/Display.html?id=61932

if(!(-e 't/online.enabled')) {
	plan skip_all => 'On-line tests disabled';
} else {
	eval 'use Log::Dispatch::Buffer';

	if($@) {
		plan skip_all => "Log::Dispatch::Buffer required for checking RT39186";
	} else {
		plan tests => 7;

		use_ok('Log::WarnDie');
		use_ok('Net::SFTP::Foreign');

		my $dispatcher = new_ok('Log::Dispatch');

		can_ok('Log::WarnDie', qw(dispatcher import unimport));

		my $channel = Log::Dispatch::Buffer->new( qw(name default min_level debug));
		isa_ok( $channel,'Log::Dispatch::Buffer' );

		$dispatcher->add( $channel );
		is( $dispatcher->output( 'default' ),$channel,'Check if channel activated');

		Log::WarnDie->dispatcher( $dispatcher );

		# http://www.sftp.net/public-online-sftp-servers
		my $sftp = Net::SFTP::Foreign->new('demo@test.rebex.net', password => 'password');

		ok(defined($sftp->ls('.')));
	}
}
