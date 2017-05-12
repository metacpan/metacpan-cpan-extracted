package Dyns::Client;

use 5.006;
use strict;
use warnings;
use vars qw( $VERSION );
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use Sys::Hostname;
use Socket;
use Net::hostent;
use CGI::Util qw( escape );

$VERSION = '0.6';

=head1 NAME

Dyns::Client - A client for the dyns.cx dynamic DNS service

=head1 DESCRIPTION

A simple client for the dyns.cx dynamic DNS service. Allows you to post an
update to the dyns dynamic dns service, as documented on:
	
	http://www.dyns.cx/documentation/technical/protocol/v1.1.php

The dyns dynamic IP service is run by Stefaan Ponnet, who started this service more than 4 years ago.

=head1 METHODS

=over 4

=item B<new> - Constructor

=cut

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	my $self = { };

	bless $self, $class;

	return $self;
}

=item B<update> - Send an update to dyns.cx

	die unless $dyns->update(
			-username => 'mandatory username',
			-password => 'mandatory password',
			-hostname => 'mandatory hostname',
			-domain => 'optional domain',
			-ip => 'optional ip'
	  		);

=cut

sub update {
	my ($self, %args) = @_;

	my $username 	= $args{-username}	
			|| do { carp "username mandatory"; return undef; };
	my $password	= $args{-password}
			|| do { carp "password mandatory"; return undef; };
	my $hostname	= $args{-hostname}
			|| do { carp "hostname required"; return undef; };
	my $domain		= $args{-domain};
	my $ip			= $args{-ip};

	my $url = 'http://www.dyns.net/postscript011.php?';

	$url .= 'username=' . escape( $username );
	$url .= '&';

	$url .= 'password=' . escape( $password );
	$url .= '&';

	$url .= 'host=' . escape( $hostname );

	if ( $domain ) {
		$url .= '&';
		$url .= 'domain=' . escape( $domain );
	}

	if ( $ip ) {
		$url .= '&';
		$url .= 'ip=' . escape( $ip );
	}
	
	my $ua = LWP::UserAgent->new( env_proxy => 1 );
	my $req = HTTP::Request->new( "GET", $url );
	my $res = $ua->request($req);

	if ( $res->is_success ) {
		my ($code, $message) = ( $res->content =~ /(\d+)\s+(.+)$/i );
		return 1 if $code eq '200';
		carp "Update failed: $code - $message";
		return undef;
	}
	carp "Update failed: " . $res->status_line;
	
	return undef;
}

=item B<get_ip> - Return local IP of the machine

=cut

sub get_ip {
	my ($self, $interface) = @_;

	return undef unless $interface;

    my $win32 = 0;
	$win32 = 1 if  $^O =~ /win32|cygwin/i;

	my $ip;
	if ($win32) {
		my $ipconfig = `ipconfig`;
		$ipconfig =~ /IP.+?: ([0-9]{1,3}(\.[0-9]{1,3}){3})$/s;
		$ip = $1;
		warn "Cannot get IP address from ipconfig output:\n$ipconfig"
			unless $ip;
	} else {
		$ip = `/sbin/ifconfig $interface`;
		if ($ip !~ s/^.*inet (?:addr:)?([0-9]{1,3}(\.[0-9]{1,3}){3}).*$/$1/s) {
			warn "Cannot get IP address from ifconfig output:\n$ip";
			return undef;
		}
	}
	return $ip;
}

=back

=cut

1;
__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=cut
