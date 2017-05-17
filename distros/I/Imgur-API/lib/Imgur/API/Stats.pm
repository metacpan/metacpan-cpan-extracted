package Imgur::API::Stats;

use strict;
use Mouse;
use DateTime;

has user_limit=>(is=>'rw',default=>sub {0;});
has user_remaining=>(is=>'rw',default=>sub{0;});
has user_reset=>(is=>'rw',default=>sub{0;});

has client_limit=>(is=>'rw',default=>sub{0;});
has client_remaining=>(is=>'rw',default=>sub {0;});

has post_limit=>(is=>'rw',default=>sub{0;});
has post_remaining=>(is=>'rw',default=>sub{0;});
has post_reset=>(is=>'rw',default=>sub{0;});

sub update {
	my ($self,$response) = @_;

	if (ref($response) eq "HTTP::Response") {
		foreach my $tp (
			['x-ratelimit-userlimit','user_limit'],['x-ratelimit-userremaining','user_remaining'],
			['x-ratelimit-userreset','user_reset'],['x-ratelimit-clientlimit','client_limit'],
			['x-ratelimit-clientlimit','c'],['x-post-rate-limit-limit','post_limit'],
			['x-post-rate-limit-remaining','post_remaining'],['x-ratelimit-clientlimit','post_limit']
		) {
			if ($response->header($tp->[0])) {
				$self->{$tp->[1]} =  $response->header($tp->[0]);
			}
		}
	} else {
		foreach my $k (keys %$response) {
			my $sub = lcfirst($k);
			$sub=~s/([A-Z])/"_".lc($1)/eg;
			$self->{$sub} = $response->{$k};
		}
	}
}

1;
	
		
