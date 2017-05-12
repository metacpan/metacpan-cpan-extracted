use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::BumpedVersion;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use version 0.86;
use namespace::autoclean;

with qw(Dist::Inkt::Role::Test);

after BUILD => sub {
	my $self = shift;
	
	$self->setup_prebuild_test(sub {
		require HTTP::Tiny;
		require JSON::PP;
		
		my $url = "https://api.metacpan.org/v0/release/".$self->name;
		my $res = HTTP::Tiny::->new->get($url);
		return $self->log("Could not fetch $url") unless $res->{success};
		
		my $nfo = JSON::PP::->new->decode($res->{content});
		my $ver = $nfo->{version}
			or return $self->log("Could not find version from $url");
		
		if (version::->parse($ver) >= version::->parse($self->version))
		{
			$self->log("Already released $ver; this build is ".$self->version);
			die("try bumping the version before release");
		}
		else
		{
			$self->log("Current version on CPAN is: $ver");
		}
	});
};

1;

