#!/usr/bin/perl -w

# $Id: 03-proxy.t,v 1.6 2002/12/22 21:25:49 m_ilya Exp $

# This script tests proxy support in HTTP::WebTest.

use strict;
use HTTP::Response;
use HTTP::Status;

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 2;

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1: proxy tests
{
    my $tests = [ { url => abs_url('http://proxy.test/', '/show-url'),
		    text_require => [ 'URL: <http://proxy.test/show-url>' ] },
		  { url => abs_url('ftp://proxy.test/', '/show-url'),
		    text_require => [ 'URL: <ftp://proxy.test/show-url>' ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => { proxies => [ http => $URL, ftp => $URL ] },
		  tests => $tests,
		  check_file => 't/test.out/proxy');
}

# 2: proxy authorization tests
{
    $WEBTEST->reset_user_agent;
    my $tests = [ { url => abs_url('http://proxy.test/',
				   '/pauth-test-user-passwd') },
		  { url => abs_url('http://proxy.test/',
				   '/pauth-test-user-passwd'),
		    pauth => [ 'user', 'wrong-passwd' ] },
		  { url => abs_url('http://proxy.test/',
				   '/pauth-test-user-passwd'),
		    pauth => [ 'wrong-user', 'passwd' ] },
		  { url => abs_url('http://proxy.test/',
				   '/pauth-test-user-passwd'),
		    pauth => [ 'user', 'passwd' ],
		    text_require => [ 'URL: <http://proxy.test/' .
				      'pauth-test-user-passwd>' ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => { proxies => [ http => $URL ] },
		  tests => $tests,
		  check_file => 't/test.out/pauth');
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    my $show_url_response = sub {
	my $content = '';
	$content .= 'URL: <' . $request->url . ">\n";

	# create response object
	my $response = new HTTP::Response(RC_OK);
	$response->header(Content_Type => 'text/plain');
	$response->content($content);

	return $response;
    };

    if($path eq '/show-url') {
	$connect->send_response($show_url_response->());
    } elsif($path =~ m|/pauth-(\w+)-(\w+)-(\w+)|) {
	my $realm = $1;
	my $user = $2;
	my $password = $3;

	# check if we have good credentials
	my $credentials = $request->header('Proxy-Authorization');
	my($user1, $password1) = parse_basic_credentials($credentials);
	if(defined($user1) and defined($password1) and
	   $user eq $user1 and $password eq $password1) {
	    # authorization is ok
	    $connect->send_response($show_url_response->());
	} else {
	    # authorization is either missing or wrong

	    # create response object
	    my $response = new HTTP::Response(RC_PROXY_AUTHENTICATION_REQUIRED);
	    $response->header(Proxy_Authenticate => "Basic realm=\"$realm\"");

	    # send it to browser
	    $connect->send_response($response);
	}
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
