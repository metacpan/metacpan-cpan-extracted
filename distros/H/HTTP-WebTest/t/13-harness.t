#!/usr/bin/perl -w

# $Id: 13-harness.t,v 1.3 2003/01/18 10:14:55 m_ilya Exp $

# This script tests core plugins of HTTP::WebTest.

use strict;
use HTTP::Status;

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $TEST = { url => abs_url($URL, '/test-file1'),
	     text_require => [ '987654' ] };

require Test::Builder::Tester;
import Test::Builder::Tester tests => 2;

# 1: test HTTP::WebTest::Plugin::HarnessReport plugin (with some
# tests failing)
{
    my $tests = [ $TEST,
		  { url       => abs_url($URL, '/non-existent') },
		  { test_name => 'BlaBla',
		    url       => abs_url($URL, '/non-existent') },
		];

    my $opts = { plugins => [ '::HarnessReport' ],
		 default_report => 'no' };

    test_out(map "# $_",
             '-' x 60,
             'URL: ' . abs_url($URL, '/test-file1'),
             'STATUS CODE CHECK',
             '  Expected \'200\' and got: 200 OK: SUCCEED',
             'REQUIRED TEXT',
             '  987654: SUCCEED');
    test_out('ok 1');
    test_out(map "# $_",
             '-' x 60,
             'URL: ' . abs_url($URL, '/non-existent'),
             'STATUS CODE CHECK',
             '  Expected \'200\' and got: 404 Not Found: FAIL');
    test_out('not ok 2');
    test_fail(10);
    test_out(map "# $_",
             '-' x 60,
             'URL: ' . abs_url($URL, '/non-existent'),
             'Test Name: BlaBla',
             'STATUS CODE CHECK',
             '  Expected \'200\' and got: 404 Not Found: FAIL');
    test_out('not ok 3');
    test_fail(2);

    $WEBTEST->run_tests($tests, $opts);
    test_test('test HarnessReport plugin (with some tests failing)');
}

# 2: test HTTP::WebTest::Plugin::HarnessReport plugin (with all tests
# passing)
{
    my $tests = [ $TEST, $TEST ];

    my $opts = { plugins => [ '::HarnessReport' ],
		 default_report => 'no' };

    test_out(map "# $_",
             '-' x 60,
             'URL: ' . abs_url($URL, '/test-file1'),
             'STATUS CODE CHECK',
             '  Expected \'200\' and got: 200 OK: SUCCEED',
             'REQUIRED TEXT',
             '  987654: SUCCEED');
    test_out('ok 1');
    test_out(map "# $_",
             '-' x 60,
             'URL: ' . abs_url($URL, '/test-file1'),
             'STATUS CODE CHECK',
             '  Expected \'200\' and got: 200 OK: SUCCEED',
             'REQUIRED TEXT',
             '  987654: SUCCEED');
    test_out('ok 2');

    $WEBTEST->run_tests($tests, $opts);
    test_test('test HarnessReport plugin (with all tests passing)');
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path eq '/test-file1' ) {
	$connect->send_file_response('t/test1.txt');
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
