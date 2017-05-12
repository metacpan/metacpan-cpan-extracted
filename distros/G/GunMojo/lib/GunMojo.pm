package GunMojo;

use warnings;
use strict;
use Mojo::Base 'Mojolicious';
use DBI;

my ( $self, $class ) = @_;
bless $self, $class;
our $VERSION = '0.01';

# This method will run once at server start
sub startup {
	my $self = shift;

	my $conf = $self->plugin('Config');
	$self->plugin('PODRenderer');

	# Core helpers
	$self->helper( 'db' => sub {
		$conf->{db}->{dbd} = $conf->{db}->{dbd} ? $conf->{db}->{dbd} : 'mysql';
		$conf->{db}->{name} = $conf->{db}->{name} ? $conf->{db}->{name} : 'guns';
		$conf->{db}->{host} = $conf->{db}->{host} ? $conf->{db}->{host} : '127.0.0.1';
		$conf->{db}->{user} = $conf->{db}->{user} ? $conf->{db}->{user} : 'guns';
		$conf->{db}->{pass} = $conf->{db}->{pass} ? $conf->{db}->{pass} : 'guns';
		$conf->{db}->{rerr} = $conf->{db}->{rerr} ? $conf->{db}->{rerr} : 1;
		DBI->connect( 'dbi:'. $conf->{db}->{dbd} .':'. $conf->{db}->{name} .';host='. $conf->{db}->{host}, $conf->{db}->{user}, $conf->{db}->{pass}, { RaiseError => $conf->{db}->{rerr} } ) or die "Failed to connect to database: ", DBI->errstr, "\n";
	});
	$self->helper( 'is_iphone' => sub {
		my $self = shift;
                return $self->req->headers->user_agent =~ /iphone|ipad/i ? 1 : undef;
	});

	# Router
	my $r = $self->routes;

	# Nested routes for GunMojo::OAuth2 controller
	my $oac = $r->route( '/oauth2' )->to( controller => 'OAuth2' );
	$oac->route( '/login' )->to( action => 'login' );
	$oac->route( '/callback' )->to( action => 'callback' );
	$oac->route( '/fail' )->to( action => 'fail' );

	# Nested routes for GunMojo::Admin controller
	my $ac = $r->route( '/admin' )->to( controller => 'Admin' );
	$ac->route( '' )->to( action => 'adminpanel' );
	$ac->route( '/pingdom' )->to( action => 'pingdom' );

	# Catchall routes for GunMojo::Content controller
	my $cc = $r->route( '/' )->to( controller => 'content' );
	$cc->route( '' )->to( action => 'normalroute' );
	$cc->route( '/custom/*' )->to( action => 'normalroute' );
	$cc->route( '/services/*' )->to( action => 'normalroute' );
}

1;
