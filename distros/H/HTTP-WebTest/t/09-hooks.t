#!/usr/bin/perl -w

# $Id: 09-hooks.t,v 1.9 2002/12/22 21:25:49 m_ilya Exp $

# This script tests HTTP::WebTest::Plugin::Hooks plugin

use strict;
use CGI::Cookie;
use HTTP::Status;

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 13;

# init tests
my $COUNTER_FILE = 't/counter';
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $OPTS = { plugins => [ '::Hooks' ], default_report => 'no' };

# 1-3: test on_request parameter
{
    init_counter();

    my $counter_value = undef;

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		    on_request => sub { $counter_value = counter() } } ];

    $WEBTEST->run_tests($tests1, $OPTS);
    ok($counter_value == 0);
    ok(counter() == 1);

    init_counter();

    my $tests2 = [ { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { inc_counter() } } ];

    $WEBTEST->run_tests($tests2, $OPTS);

    ok(counter() == 2);
}

# 4-6: test on_response parameter which doesn't returns any test results
{
    init_counter();

    my $counter_value = undef;

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		     on_response => sub { $counter_value = counter(); [] } }
		 ];

    $WEBTEST->run_tests($tests1, $OPTS);
    ok($counter_value == 1);
    ok(counter() == 1);

    init_counter();

    my $tests2 = [ { url => abs_url($URL, '/inc_counter'),
		     on_response => sub { inc_counter(); [] } } ];

    $WEBTEST->run_tests($tests2, $OPTS);
    ok(counter() == 2);
}

# 7: test on_response parameter returning some test results
{
    my $tests = [ { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'yes', 'Test 1' ] },
		  { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'no', 'Test 2' ] },
		  { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'yes', 'Test 3',
				     'no', 'Test 4' ] },
		  { url =>  abs_url($URL, '/inc_counter'),
		    on_response => [] } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => { plugins => [ '::Hooks' ] },
		  check_file => 't/test.out/on_response');
}

# 8-10: test on_start parameter
{
    init_counter();

    my $counter_value1 = undef;
    my $counter_value2 = undef;

    my $opts = { %$OPTS,
	         on_start => sub { inc_counter() } };

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { $counter_value1 = counter() } },
		   { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { $counter_value2 = counter() } }
		 ];

    $WEBTEST->run_tests($tests1, $opts);
    # this counter is set to one as it is increased by on_start hook
    ok($counter_value1 == 1);
    # this counter get ++ because it is increased by '/inc_counter' request
    ok($counter_value2 == 2);
    # this counter get ++ because it is increased by second
    # '/inc_counter' request
    ok(counter() == 3);
}

# 11-13: test on_finish parameter
{
    init_counter();

    my $counter_value1 = undef;
    my $counter_value2 = undef;

    my $opts = { %$OPTS,
	         on_finish => sub { inc_counter() } };

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { $counter_value1 = counter() } },
		   { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { $counter_value2 = counter() } }
		 ];

    $WEBTEST->run_tests($tests1, $opts);
    # this counter is set to zero as no '/inc_counter' request and no
    # hook that increase counter are run
    ok($counter_value1 == 0);
    # this counter get ++ because it is increased by '/inc_counter' request
    ok($counter_value2 == 1);
    # this counter get += 2 because it is increased by second
    # '/inc_counter' request and by on_finish hook
    ok(counter() == 3);
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# remove counter file
unlink $COUNTER_FILE;

# sets counter to zero
sub init_counter {
    write_file($COUNTER_FILE, 0);
}

# increase counter
sub inc_counter {
    my $counter = counter();
    $counter ++;
    write_file($COUNTER_FILE, $counter);
}

# get counter
sub counter {
    return read_file($COUNTER_FILE, 1) || 0;
}

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path eq '/inc_counter' ) {
	# count requests
	inc_counter();

	$connect->send_file_response('t/test1.txt');
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
