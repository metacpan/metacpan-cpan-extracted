package Imgur::API::Endpoint::OAuth;

use strict;
use Mouse;
use feature qw(say);
extends 'Imgur::API::Endpoint';

sub auth_url {
	my ($this,%options) = @_;

	$options{state}||='';

	return $this->path("oauth2/authorize",[],[],{})."?response_type=$options{grant_type}&client_id=".$this->dispatcher->client_id."&state=$options{state}";
}


sub token {
    my ($this,%p) = @_;

	$p{client_id} = $this->dispatcher->client_id;
	$p{client_secret} = $this->dispatcher->client_secret;


    my $url = $this->path("oauth2/token",[],[],\%p);

	say $url;
	
	return $this->dispatcher->request($url,'post',\%p);
		
}

1;
__PACKAGE__->meta->make_immutable;

