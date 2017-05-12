#!/usr/bin/perl -w

# $Id: 01-api.t,v 1.15 2003/01/25 17:48:05 m_ilya Exp $

# This script tests public API of HTTP::WebTest.

use strict;
use HTTP::Status;

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 19;

# init test
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1: get default user agent object
{
    ok(defined $WEBTEST->user_agent->can('request'));
}

# 2: set our user agent
{
    my $user_agent = new LWP::UserAgent;
    $WEBTEST->user_agent($user_agent);
    is($WEBTEST->user_agent, $user_agent);
}

# 3: reset to default user agent
{
    $WEBTEST->user_agent(undef);
    ok(defined $WEBTEST->user_agent->can('request'));
}

# 4: check what returns method tests (should be reference on empty array)
{
    my $aref = $WEBTEST->tests;
    is(@$aref, 0);
}

# 5-6: run single test and check last response and last request
{
    my $url = abs_url($URL, '/test-file1');
    my $test = { url => $url };
    $WEBTEST->run_test($test);
    my $request = $WEBTEST->current_request;
    my $response = $WEBTEST->current_response;
    is($request->uri->as_string, $url->as_string);
    ok($response->is_success);
}

# 7: run several tests
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/status-forbidden') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/status');
}

# 8: check what returns method tests now
{
    my $aref = $WEBTEST->tests;
    is(@$aref, 3);
}

# 9-10: parse wt script
{
    my $data = read_file('t/simple.wt');

    my ($tests, $opts) = $WEBTEST->parse($data);
    is($tests->[0]{test_name}, 'Some name here');
    is($opts->{text_require}[0], 'Require some');
}

# 11: run tests defined in wt script
{
    generate_testfile(file => 't/real.wt', server_url => $URL);

    my $output = '';

    $WEBTEST->run_wtscript('t/real.wt', { output_ref => \$output });

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(output_ref => \$output,
		   check_file => 't/test.out/run-wtscript');
}

# 12: run inlined wtscript
{
    my $output = '';

    $WEBTEST->run_wtscript(<<WTSCRIPT, { output_ref => \$output });
text_forbid = ( FAILED TEST )

test_name = Some name here
    url = ${URL}test-file1
    regex_require = ( TEST TEST )
end_test

test_name = Another name
    url = ${URL}no-such-file
end_test
WTSCRIPT

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(output_ref => \$output,
		   check_file => 't/test.out/run-wtscript');
}

# 13-14: test num_fail and num_succeed
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/status-forbidden') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    my $output = '';

    $WEBTEST->run_tests($tests, { output_ref => \$output });
    is($WEBTEST->num_fail, 2);
    is($WEBTEST->num_succeed, 1);
}

# 15: test current_test after running $WEBTEST->run_tests
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    my $output = '';

    $WEBTEST->run_tests($tests, { output_ref => \$output });
    is($WEBTEST->current_test->request->uri->as_string,
       abs_url($URL, '/doesnt-exist')->as_string);
}

# 16-19: test $WEBTEST->parser_package
{
    is($WEBTEST->parser_package, 'HTTP::WebTest::Parser');
    {
        package TestParser;

        sub parse { [ x => 'z' ], { 1 => 2 } };
    };
    # set non default parser
    $WEBTEST->parser_package('TestParser');
    is($WEBTEST->parser_package, 'TestParser');
    is_deeply([ [ x => 'z' ], { 1 => 2 } ],
              [ $WEBTEST->parse('a = b') ]);
    # reset to default
    $WEBTEST->parser_package(undef);
    is_deeply([ [ ], { a => 'b' } ],
              [ $WEBTEST->parse('a = b') ]);
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
    } elsif($path eq '/status-forbidden') {
	$connect->send_error(RC_FORBIDDEN);
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
