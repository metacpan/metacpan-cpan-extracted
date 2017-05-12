use strict;

package Device::Hue;
{
  $Device::Hue::VERSION = '0.4';
}

use warnings;
use common::sense;

use Moo;

has 'bridge' => ( is => 'rw' );
has 'key' => ( is => 'rw' );
has 'agent' => ( is => 'rw' );
has 'debug' => ( is => 'rw' );

use Device::Hue::UPnP;
use Device::Hue::Light;

use LWP::UserAgent;
use LWP::Protocol::https;

use JSON::XS;

use Data::Dumper;
use Carp;

sub BUILD
{
	my ($self) = @_;

	$self->agent(new LWP::UserAgent);
	$self->init;
}

sub init
{
	my ($self) = @_;

	$self->bridge($ENV{'HUE_BRIDGE'})
		if defined $ENV{'HUE_BRIDGE'};

	$self->key($ENV{'HUE_KEY'})
		if defined $ENV{'HUE_KEY'};

	croak "missing hue bridge"
		unless defined $self->bridge;
	
	croak "missing hue key"
		unless defined $self->key;
}

sub process
{
	my ($self, $res) = @_;

	if ($res->is_success) {

		say $res->status_line
			if $self->debug;

		say Dumper(decode_json($res->decoded_content))
			if $self->debug;

		return decode_json($res->decoded_content);
	}  else {
		say "Request failed: " . $res->status_line if $self->debug;
	}
	
	return;
}

sub get
{
	my ($self, $uri) = @_;

	say "GET $uri" if $self->debug;
	
	my $req = HTTP::Request->new('GET', $uri);

	$req->content_type('application/json');

	return $self->process($self->agent->request($req));
}

sub put
{
	my ($self, $uri, $data) = @_;

	my $req = HTTP::Request->new('PUT', $uri);

	$req->content_type('application/json');
	$req->content(encode_json($data));

	return $self->process($self->agent->request($req));
}

sub config
{
	my ($self) = @_;

	return $self->get($self->path_to(''));
}

sub schedules
{
	my ($self) = @_;

	return $self->get($self->path_to('schedules'));
}

sub lights
{
	my ($self) = @_;

	my $config = $self->config
		or return undef;

	my @lights = ();

	foreach my $key (sort keys %{$config->{'lights'}}) {

		my $light = $config->{'lights'}{$key};

		push @lights, Device::Hue::Light->new({ 'hue' => $self, 'id' => $key, 'data' => $light });
	}

	return \@lights;
}

sub discovery
{
	my ($self) = @_;

	my $devices = $self->nupnp;

	return scalar @$devices ? $devices : $self->upnp;
}

sub nupnp
{
	my $data = (shift)->get('https://www.meethue.com/api/nupnp')
		or return [];

	return [ map { $_->{'internalipaddress'} } @$data ];
}

sub upnp
{
	return Device::Hue::UPnP::upnp();
}

sub path_to
{
	my ($self, @endp) = @_;

	my $uri = join('/', $self->bridge, 'api', $self->key, @endp);

	say $uri
		if $self->debug;

	return $uri;
}

sub light
{
	my ($self, $id) = @_;

	return Device::Hue::Light->new({ 'hue' => $self, 'id' => $id });
}

1;

# ABSTRACT: Perl module for the Philips Hue light system

__END__

=pod

=head1 NAME

Device::Hue - Perl module for the Philips Hue light system

=head1 VERSION

version 0.4

=head1 AUTHOR

Alessandro Zummo <a.zummo@towertech.it>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alessandro Zummo.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
