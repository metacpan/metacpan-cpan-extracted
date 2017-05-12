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

my $lwp = LWP::UserAgent->new();
isa_ok($lwp, 'LWP::UserAgent');

lives_ok { $lwp->proxy('http', 'connect://localhost:8888/') } 'can set connect:// proxy';

my $response;
lives_ok { $response = $lwp->get('http://www.google.com/') } 'GET http://www.google.com/';

if( $response->status_line =~ /^500 Net::HTTP: connect:/ ) {
	done_testing();
	diag('seems like we have no connectivity. no futher tests...aborting');
	exit 0;
}
ok( $response->is_success, 'successful response');

done_testing();

