#!/usr/bin/perl -w

# $Id: 11-delay.t,v 1.8 2003/01/03 22:32:32 m_ilya Exp $

# This script tests HTTP::WebTest::Plugin::Delay plugin

use strict;
use HTTP::Status;
use Time::HiRes qw(gettimeofday);

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 4;

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $OPTS = { plugins => [ '::Delay' ] };


# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

{
    # run non-empty test once to trigger loading of all modules;
    # otherwise next test run takes too much time (because of module
    # loading) and breaks delay test

    my $output = '';

    $WEBTEST->run_tests([ { url => abs_url($URL, '/test') } ],
			{ %$OPTS,
			  output_ref => \$output });
}

SKIP: {
    skip 'delay tests are disabled', 2 if defined $ENV{TEST_FAST};

    my $start = gettimeofday;

    my $tests = [ { url => abs_url($URL, '/test'),
                    delay => 2 } ];

    check_webtest(webtest => $WEBTEST,
                  server_url => $URL,
                  opts => $OPTS,
                  tests => $tests,
                  check_file => 't/test.out/delay');

    my $delay = gettimeofday - $start;
    ok(1 < $delay and $delay < 3);
}

SKIP: {
    skip 'delay tests are disabled', 2 if defined $ENV{TEST_FAST};

    my $start = gettimeofday;

    my $tests = [ { url => abs_url($URL, '/test'),
                    delay => 4 } ];

    check_webtest(webtest => $WEBTEST,
                  server_url => $URL,
                  opts => $OPTS,
                  tests => $tests,
                  check_file => 't/test.out/delay');

    my $delay = gettimeofday - $start;
    ok(3 < $delay and $delay < 5);
}

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    $connect->send_error(RC_NOT_FOUND);
}
