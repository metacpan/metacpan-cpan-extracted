package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

BEGIN {
    local $@ = undef;
    eval {
	require Test::Pod::LinkCheck::Lite;
	Test::Pod::LinkCheck::Lite->import( ':const' );
	1;
    } or plan skip_all => 'Unable to load Test::Pod::LinkCheck::Lite';
}

Test::Pod::LinkCheck::Lite->new(
    # We ignore the following URL because it returns 403 to a HEAD
    # request. A GET request succeeds, but there is no way to tell
    # Test::Pod::LinkCheck::Lite this. Yet.
    ignore_url	=> 'https://epqs.nationalmap.gov/v1/docs',
    prohibit_redirect	=> sub {
	my ( undef, undef, $url ) = @_;
	'https://nationalmap.gov' =~ $url
	    and return;
	return ALLOW_REDIRECT_TO_INDEX;
    },
)->all_pod_files_ok(
    qw{ blib eg },
);

done_testing;

1;

# ex: set textwidth=72 :
