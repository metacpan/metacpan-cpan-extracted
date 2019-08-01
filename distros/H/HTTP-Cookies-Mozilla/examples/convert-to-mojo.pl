#!/Users/brian/bin/perl

# This programs reads the Mozilla cookies file then converts the
# HTTP::Cookies object to a Mojo::UserAgent::CookieJar object. The
# end object isn't that important because you'd do the same thing.
#
use v5.10;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use HTTP::Cookies::Mozilla;
use Mojo::Util qw(dumper);
use Mojo::UserAgent::CookieJar;
use Mojo::Cookie::Response;

# on macOS,
my @cookies_files = glob(
	'~/Library/*/Firefox/Profiles/*/cookies.sqlite'
	);

say "Cookie files are:\n\t", join "\n\t", @cookies_files;

# We'll just assume that the first one is the right profile, but
# if there is more than one, you have to work harder
my $http_cookies = HTTP::Cookies::Mozilla->new(
	file => $cookies_files[0]
	);

# this is the jar where the cookies will end up and that you can use
# with Mojo::UserAgent.
my $jar = Mojo::UserAgent::CookieJar->new;

my $callback = make_callback( $jar );
$http_cookies->scan( $callback );

say dumper( $jar );

sub make_callback ($jar) {
	sub {
		my( $version, $key, $val, $path, $domain, $port,
			$path_spec, $secure, $expires, $discard, $hash ) = @_;

		# You might like to construct it differently.
		my $cookie = Mojo::Cookie::Response->new
			->name(    $key     )
			->value(   $val     )
			->domain(  $domain  )
			->path(    $path    )
			->expires( $expires )
			->secure(  $secure  );

		$jar->add( $cookie );
		}
	}
