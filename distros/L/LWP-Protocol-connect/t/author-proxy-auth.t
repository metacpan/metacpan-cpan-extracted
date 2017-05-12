#!/usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

BEGIN { $ENV{LANG} = $ENV{LC_MESSAGES} = $ENV{LC_ALL} = "C" }

use Test::More;
use Test::Exception;

use version;
use LWP::UserAgent;

my $lwp = LWP::UserAgent->new();
isa_ok($lwp, 'LWP::UserAgent');

# TEST - with out auth (should fail)

lives_ok { $lwp->proxy('https', 'connect://localhost:3128/') } 'can set connect:// proxy';

my $response;
lives_ok { $response = $lwp->get('https://www.google.com/') } 'GET https://www.google.com/';

if( $response->status_line =~ /^500 Net::HTTP: connect:/ ) {
	done_testing();
	diag('seems like we have no connectivity. no futher tests...aborting');
	exit 0;
}
ok( $response->is_error, 'negative response');
like( $response->status_line, qr/407 Proxy Authentication Required/, 'proxy auth required');

# TEST with auth in proxy URL
$lwp = LWP::UserAgent->new();
lives_ok { $lwp->proxy('https', 'connect://testuser:testpw@localhost:3128/') } 'can set auth within connect:// proxy url';
lives_ok { $response = $lwp->get('https://www.google.com/') } 'GET https://www.google.com/';

ok( $response->is_success, 'positive response');
if( $response->is_error) {
	diag('request failed with: '.$response->status_line);
}

# TEST with auth thru ->credentials
# does not work with current LWP::Authen::Basic
# retry when a new version is released
if( version->parse($LWP::UserAgent::VERSION) > version->parse('6.05') ) {
	$lwp = LWP::UserAgent->new();
	lives_ok { $lwp->proxy('https', 'connect://localhost:3128/') } 'can set connect:// proxy';
	lives_ok { $lwp->credentials("localhost:3128", "Squid proxy-caching web server", "testuser", "testpw") } 'set credentials';
	lives_ok { $response = $lwp->get('https://www.google.com/') } 'GET https://www.google.com/';

	ok( $response->is_success, 'positive response');
	if( $response->is_error) {
		diag('request failed with: '.$response->status_line);
	}
}

done_testing();

