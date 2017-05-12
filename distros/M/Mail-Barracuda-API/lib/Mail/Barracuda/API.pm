package Mail::Barracuda::API;

use 5.008008;
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use LWP::UserAgent;

our $VERSION = '0.01';


=head1 NAME

Mail::Barracuda::API - Manage Barracuda Antispam Appliance

=head1 SYNOPSIS

  use Mail::Barracuda::API;
  my $api = Mail::Barracuda::API->new(
  	server => 'mybarracuda.mydomain.com',
	port => 8000,
	api_key => 'my API key',
  );
  $api->domainAdd(domain => 'example.com', mailhost=> 'mail.example.com');
  $api->domainRemove(domain => 'example.com');

=head1 DESCRIPTION

This module provides a Perl interface to parts of the 
Barracuda Antispam Appliance API

=head2 Methods

=head3 new

	my $api = Mail::Barracuda::API->new(
		server => 'http://mybarracuda.mydomain.com',
		port => 8000,
		api_key => 'my API key',
	);
	
Sets up a Mail::Barracuda::API session. Port defaults to 8000. 
All other parameters are necessary..

=cut

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	
	my $self = {
		port => 8000,
		@_
	};
	
	return bless $self, $class;	
}

=head3 userChange

	my $response = $api->userChange(
		email => 'jane@example.com',
		var => 'user_password', 
		val=> '4321',
	);
	
Sets property user_password on account jane@example.com to 4321. See API 
manual for other valid vars. 
$response is a 0 if successful and a 1 if a error occured.

=cut

sub userChange {
	my ($class, %args) = @_;
	my $result = 0;
	
	my $email = $args{email};
	my $var = $args{var};
	my $val = $args{val};
	
	my $cmd = "config_set.cgi?account=$email&variable=$var&value=$val";
	my ($respcode, $status) = $class->_doRequest(command => $cmd);
	if ($respcode != 200) {
		print STDERR "$respcode: Could not change user $email var $var to $val\n";
		$result = 1;	
	}
	
	return $result;
}

=head3 domainAdd

	my $response = $api->domainAdd(
		domain => 'example.com', 
		mailhost => 'mail.example.com',
	);
	
Sets up a domain on the Barracuda Appliance. 
$response is a 0 if successful and a 1 if a error occured.

=cut

sub domainAdd {
	my ($class, %args) = @_;
	my $result = 0;
	
	my $domain = $args{domain};
	my $mailhost = $args{mailhost};
	
	my $cmd = "add_domain.cgi?domain=$domain";
	my ($respcode, $status) = $class->_doRequest(command => $cmd);
	
	if ($respcode != 200) {
		print STDERR "Could not add domain $domain: $status\n";
		$result = 1;
	} else {
		$cmd = "config_set.cgi?variable=mta_relay_advanced_host";
		$cmd .= "&domain=$domain&value=$mailhost";
		$class->_doRequest(command => $cmd);
		if ($respcode != 200) {
			print STDERR "$respcode: Could not set mailhost for $domain: $status\n";
			$result = 1;	
		} 
	}
	
	return $result;
}

=head3 domainRemove
	
	my $response = $api->domainRemove(domain => 'example.com');
	
Removes a domain from the Barracuda Appliance. 
$response is a 0 if successful and a 1 if a error occured.

=cut

sub domainRemove {
	my ($class, %args) = @_;
	my $result = 0;
	
	my $domain = $args{domain};
		
	my $cmd = "delete_domain.cgi?domain=$domain";
	my ($respcode, $status) = $class->_doRequest(command => $cmd);
	if ($respcode != 200) {
		print STDERR "$respcode: Could not remove domain $domain: $status\n";
		$result = 1;
	}
	return $result;
}

=head3 userAdd

	my $response = $api->userAdd(
		email => 'jane@example.com', 
		paassword => '12345',
	};
	
Adds a quarantine and personal settings login for the email address provided.
$response is a 0 if successful and a 1 if a error occured.

=cut

sub userAdd {
	my ($class, %args) = @_;
	my $result = 0;	

	my $email = $args{email};
	my $pass = $args{password};
	
	my $cmd = "config_add.cgi?account=$email&create=1";	
	my ($respcode, $status) = $class->_doRequest(command => $cmd);
	
	if ($respcode != 708) {
		print STDERR "$respcode: Could not add user $email: $status\n";
		$result = 1;
	} else {
		my $resp = $class->userChange(
			email => $email,
			var => 'user_password',
			val => $pass,
		);
		if ($resp != 0) {
			print STDERR "$respcode: Could not set password for user $email: $status\n";
			$result = 1;
		}
	}
		
	return $result;
}

=head3 userRemove

	my $response = $api->userRemove(email => 'jane@example.com');

Removes the user from quarantine and personal settings from the Appliance.
$response is a 0 if successful and a 1 if a error occured.

=cut

sub userRemove {
	my ($class, %args) = @_;
	my $result = 0;
	
	my $email = $args{email};
	
	my $cmd = "config_delete.cgi?account=$email&remove=1";
	my ($respcode, $status) = $class->_doRequest(command => $cmd);

	if ($respcode != 607) {
		print STDERR "$respcode: Could not remove user $email: $status\n";
		$result = 1;
	}
	
	return $result;
}

# Extract response code from XML response, returns status number and 
# a brief explanation
sub _parseResponse{
	my $res = pop(@_);
		
	my $xs = XML::Simple->new();
	my $ref = $xs->XMLin($res);
		
	my ($code, $result);
		
	if (exists($ref->{Result})) {
		if (ref($ref->{Result}) eq "HASH") {
			$code = $ref->{Result}->{Code};
			$result = $ref->{Result}->{String};
		} else {
			($code, $result) = split(/:/, $ref->{Result});
		}
	
	} elsif (exists($ref->{Error})) {		
		if (exists($ref->{Error}->{Code})) {
			$code = $ref->{Error}->{Code};
			$result = $ref->{Error}->{String};
		}
		
	} else {
		print Dumper($ref);
		die "Unmatched response from Appliance. Cannot continue.\n";
	}
		
	return ($code, $result);
}

sub _doRequest {
	my ($class, %args) = @_;
	my $cmd = $args{command};
	
	my @response;
	
	my $precmd = $class->{server} . ":" . $class->{port} . "/cgi-bin/";
	my $postcmd = "&password=" . $class->{api_key};
	$cmd = $precmd . $cmd . $postcmd;
		
	my $ua = LWP::UserAgent->new;
	$ua->agent("Mail::Barracuda::API/$VERSION ");
	
	my $req = HTTP::Request->new(GET => $cmd);
	my $res = $ua->request($req);
	
	if ($res->is_success) {
		@response = $class->_parseResponse($res->content);	
	} else {
		die "Error contacting Appliance: " . $res->status_line, "\n";
	}
		
	$class->_doApply();
	return @response;
}

sub _doApply {
	my ($class, %args) = @_;
	my $result = 0;
	my @response;
	
	my $cmd = "config_reload.cgi?";
	my $precmd = $class->{server} . ":" . $class->{port} . "/cgi-bin/";
	my $postcmd = "password=" . $class->{api_key};
	$cmd = $precmd . $cmd . $postcmd;
		
	my $ua = LWP::UserAgent->new;
	$ua->agent("Mail::Barracuda::API/$VERSION ");
	
	my $req = HTTP::Request->new(GET => $cmd);
	my $res = $ua->request($req);
		
	if ($res->is_success) {
		@response = $class->_parseResponse($res->content);	
	} else {
		$result = 1;
		die "Error contacting Appliance: " . $res->status_line, "\n";
	}
		
	return $result;
}

=head1 SEE ALSO

Barracuda API For 3.x firmware.

http://www.barracudanetworks.com/ns/downloads/BarracudaAPI-v3x.pdf

=head1 AUTHOR

Jonathan Auer, E<lt>jda@tapodi.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Jonathan Auer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
