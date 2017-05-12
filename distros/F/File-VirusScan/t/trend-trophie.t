package TestVirusScan::Trend::Trophie;
use strict;
use warnings;

use lib qw( t/lib );
use base qw( TestVirusPlugin );

use Test::More;
use Test::Exception;
use File::Temp ();

use File::VirusScan::Engine::Daemon::Trend::Trophie;

sub under_test { 'File::VirusScan::Engine::Daemon::Trend::Trophie' };
sub required_arguments {
	{ socket_name => '/var/spool/MIMEDefang/trophie' }
}

sub testable_live
{
	my ($self) = @_;

	# Only testable live if the socket exists
	return ( -S $self->engine->{socket_name} && -r _ && -w _ );
}

sub constructor_failures : Test(2)
{
	my ($self) = @_;

	dies_ok { $self->under_test->new() } 'Constructor dies with no arguments';
	like( $@, qr/Must supply a 'socket_name' config value/, ' ... error as expected');
}

sub bogus_socket : Test(2)
{
	my ($self) = @_;

	my $s = $self->engine();

	$s->{socket_name} = '/dev/null';

	dies_ok { $s->_get_socket() } '_get_socket() dies (invalid socket_name given)';
	like( $@, qr{Could not connect to sophie daemon at /dev/null}, '... error as expected');
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
