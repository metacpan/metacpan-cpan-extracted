package TestVirusScan::Symantec::CSS;
use strict;
use warnings;

use lib qw( t/lib );
use base qw( TestVirusPlugin );

use Test::More;
use Test::Exception;
use File::Temp ();

use File::VirusScan::Engine::Daemon::Symantec::CSS;

sub under_test { 'File::VirusScan::Engine::Daemon::Symantec::CSS' };
sub required_arguments {
	{ 
		host => '127.0.0.1',
		port => 7779
	}
}

sub testable_live
{
	my ($self) = @_;

	# Only testable if socket is a CSS server
	eval { $self->engine->_get_socket() };
	return ( ! $@ );
}

sub constructor_failures : Test(2)
{
	my ($self) = @_;

	dies_ok { $self->under_test->new() } 'Constructor dies with no arguments';
	like( $@, qr/Must supply a 'host' config value/, ' ... error as expected');
}

sub bogus_socket : Test(2)
{
	my ($self) = @_;

	my $s = $self->engine();

	$s->{port} = 1;

	dies_ok { $s->_get_socket() } '_get_socket() dies (invalid port given)';
	like( $@, qr/Error: Could not connect to CarrierScan Server on 127.0.0.1, port 1: Connection refused/, '... error as expected');
}

sub good_socket : Test(1)
{
	my ($self) = @_;
	my $s = $self->engine();

	return "Could not run live test" if ! $self->testable_live;

	my $sock;
	lives_ok { $sock = $s->_get_socket() } 'Real socket can be spoken to';
	$sock->close;
}

__PACKAGE__->runtests() unless caller();
1;
