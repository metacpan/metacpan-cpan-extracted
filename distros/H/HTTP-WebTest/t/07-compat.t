#!/usr/bin/perl -w

# $Id: 07-compat.t,v 1.8 2002/12/22 21:25:49 m_ilya Exp $

# This script tests backward compatiblity with HTTP::WebTest 1.xx

use strict;
use HTTP::Status;

use HTTP::WebTest qw(run_web_test);
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 10;

# init test
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1-4: run tests defined in wt script (check web_test method)
{
    generate_testfile(file => 't/real.wt', server_url => $URL);

    my $output = '';
    my ($num_fail, $num_succeed);

    my $ret = $WEBTEST->web_test('t/real.wt',
				 \$num_fail,
				 \$num_succeed,
				 { output_ref => \$output });

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(output_ref => \$output,
		   check_file => 't/test.out/run-wtscript');

    ok($num_fail == 2);
    ok($num_succeed == 3);
    ok(not $ret);
}

# 5: check web_test method
{
    generate_testfile(file => 't/good.wt', server_url => $URL);

    my $output = '';

    my $ret = $WEBTEST->web_test('t/good.wt',
				 undef,
				 undef,
				 { output_ref => \$output });

    ok($ret);
}

# 6-9: check run_web_test sub
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    my $output = '';
    my ($num_fail, $num_succeed);

    my $ret = run_web_test($tests,
			   \$num_fail,
			   \$num_succeed,
			   { output_ref => \$output });

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(output_ref => \$output,
		   check_file => 't/test.out/run-web-test');

    ok($num_fail == 1);
    ok($num_succeed == 1);
    ok(not $ret);
}

# 10: check run_web_test sub
{
    my $tests = [ { url => abs_url($URL, '/test-file1') } ];

    my $output = '';

    my $ret = run_web_test($tests,
			   undef,
			   undef,
			   { output_ref => \$output });

    ok($ret);
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
