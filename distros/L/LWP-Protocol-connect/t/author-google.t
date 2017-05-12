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

use LWP::UserAgent;

my $lwp = LWP::UserAgent->new(
        ssl_opts => {
                verify_hostname => 1,
        },
);
isa_ok($lwp, 'LWP::UserAgent');

lives_ok { $lwp->proxy('https', 'connect://localhost:8888/') } 'can set connect:// proxy';

my $response;
lives_ok { $response = $lwp->get('https://www.google.com/') } 'GET https://www.google.com/';

if( $response->status_line =~ /^500 Net::HTTP: connect:/ ) {
	done_testing();
	diag('seems like we have no connectivity. no futher tests...aborting');
	exit 0;
}
ok( $response->is_success, 'successful response');

# check if hostname is verified

lives_ok { $response = $lwp->get('https://googlemail.l.google.com/') } 'GET https://googlemail.l.google.com/ certificate for mail.google.com';

ok( $response->is_error, 'negative response');
like( $response->status_line, qr/certificate verify failed/, 'ssl verify should fail');

# check if we fail with unknown CA

$lwp->ssl_opts( 'SSL_ca_file' => 't/empty-ca-bundle.crt' );

lives_ok { $response = $lwp->get('https://www.google.com/') } 'GET https://www.google.com/';

ok( $response->is_error, 'negative response');
like( $response->status_line, qr/certificate verify failed/, 'ssl verify should fail');

done_testing();

