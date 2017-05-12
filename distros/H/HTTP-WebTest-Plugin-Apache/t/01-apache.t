#!/usr/bin/perl -w

# $Id: 01-apache.t,v 1.3 2002/12/16 21:14:00 m_ilya Exp $

# This script tests local web files test mode

use strict;
use Config;
use File::Copy;
use File::Path;
use IO::File;
use HTTP::Status;
use Test;
use Time::HiRes qw(time);

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(copy_dir);

use vars qw($HOSTNAME $PORT $URL $TEST_NUM %CONFIG);

do '.config';
my $APACHE_EXEC = $CONFIG{APACHE_EXEC};

BEGIN { $TEST_NUM = 19; plan tests => $TEST_NUM }

# init tests
my $WEBTEST = HTTP::WebTest->new;
my $APACHE_DIR = 'http-webtest';
my $TEST = { file_path => [ 't/test1.txt', '.' ],
	     text_require => [ 'abcde', '123' ] };
my %OPTS = (plugins => [ '::Apache' ],
            apache_exec => $APACHE_EXEC, apache_dir => $APACHE_DIR);
my $ERROR_LOG = 't/error_log';
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
{
    my $file = $ERROR_LOG;
    my $fh = new IO::File;
    $fh->open("> $file") or die "Can't open file $file: $!";
    $fh->close;
}

# 1: test error_log param
{
    my $tests = [ { url => abs_url($URL, '/error-log-0') },
		  { url => abs_url($URL, '/error-log-5') },
		  { url => abs_url($URL, '/error-log-0') },
		  { url => abs_url($URL, '/error-log-1') } ];

    check_webtest(webtest => $WEBTEST,
		  opts => { plugins => [ '::Apache' ],
                            error_log => $ERROR_LOG },
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/apache8');
}

# 2: test error_log and ignore_error_log params
{
    my $tests = [ { url => abs_url($URL, '/error-log-0') },
		  { url => abs_url($URL, '/error-log-1'),
		    ignore_error_log => 'yes' },
		  { url => abs_url($URL, '/error-log-0') },
		  { url => abs_url($URL, '/error-log-3') } ];

    check_webtest(webtest => $WEBTEST,
		  opts => { plugins => [ '::Apache' ],
                            error_log => $ERROR_LOG },
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/apache9');
}

unlink $ERROR_LOG;

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

unless(defined $APACHE_EXEC) {
    for my $i (3 .. $TEST_NUM) {
	skip('skip: local webfiles test mode tests are disabled', 1);
    }
    exit 0;
}

# 3: test apache_exec and apache_dir params
{
    $WEBTEST->reset_plugins;
    check_webtest(webtest => $WEBTEST,
		  opts => \%OPTS,
		  tests => [ $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache1');
}

# 4: test apache_exec and apache_dir params
{
    $WEBTEST->reset_plugins;

    my $apache_dir = 't/http-webtest';
    copy_dir($APACHE_DIR, $apache_dir);

    check_webtest(webtest => $WEBTEST,
		  opts => { %OPTS,
			    apache_dir => $apache_dir },
		  tests => [ $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache1');

    rmtree($apache_dir);
}

# 5: test apache_exec and apache_dir params
{
    $WEBTEST->reset_plugins;

    my $apache_exec = 't/apache';
    copy($APACHE_EXEC, $apache_exec);
    chmod +(stat $APACHE_EXEC)[2], $apache_exec;

    check_webtest(webtest => $WEBTEST,
		  opts => { %OPTS,
			    apache_exec => $apache_exec },
		  tests => [ $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache1');

    unlink $apache_exec;
}

# 6-7: test apache_options param
{
    $WEBTEST->reset_plugins;

    check_webtest(webtest => $WEBTEST,
		  opts => { %OPTS,
			    apache_options => '-c "ServerTokens Prod"' },
		  tests => [ $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache1');
    my $response = $WEBTEST->tests->[-1]->response;
    ok($response->header('Server') eq 'Apache');
}

# 8-9: test apache_options param
{
    $WEBTEST->reset_plugins;

    check_webtest(webtest => $WEBTEST,
		  opts => { %OPTS,
			    apache_options => '-c "ServerTokens Min"' },
		  tests => [ $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache1');
    my $response = $WEBTEST->tests->[-1]->response;
    ok($response->header('Server') =~ m|^Apache/\d+(?:\.\d+)*$|x);
}

# 10-13: test apache_max_wait param
{
    # use some process instead of apache which will wait forever doing
    # nothing. Obviously HTTP::WebTest will timeout waiting for this
    # process to start serving. We will use this fact in our tests.
    my $apache_exec = "$Config{perlpath} -e 'sleep 1 while 1' --";

    for my $timeout (1, 2, 4, 8) {
	if(defined $ENV{TEST_FAST}) {
	    skip('skip: long apache_max_wait param tests are disabled', 1);
	} else {
	    $WEBTEST->reset_plugins;

	    my $opts = { %OPTS,
			 apache_max_wait => $timeout,
			 apache_exec => $apache_exec };
	    my $ok = 0;
	    my $start = time;
	    eval {
		$WEBTEST->run_tests([ $TEST ], $opts);
	    };
	    if($@) {
		if($@ =~ /^HTTP::WebTest/) {
		    my $time = time - $start;
		    $ok = (($timeout - 0.75) < $time and
			   $time < ($timeout + 0.75));
		} else {
		    die $@;
		}
	    }
	    ok($ok);
	}
    }
}

# 14: test include_file_path param
{
    $WEBTEST->reset_plugins;

    my $test = { file_path => [ 't/test.shtml', '.' ],
 		 include_file_path => [ 't/test1.txt', '/inc',
 				        't/test2.txt', '/inc' ],
 		 text_require => [ 'abcde', '123',
 				   'begin', '644' ],
 		 text_forbid => [ '#include', 'virtual', 'error' ] };

    check_webtest(webtest => $WEBTEST,
 		  opts => \%OPTS,
 		  tests => [ $test ],
 		  server_hostname => 'localhost',
 		  check_file => 't/test.out/apache2');
}

# 15: several local web file tests in raw test
{
    $WEBTEST->reset_plugins;

    check_webtest(webtest => $WEBTEST,
		  opts => \%OPTS,
		  tests => [ $TEST, $TEST, $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache3');
}

# 16: error log checking test
{
    $WEBTEST->reset_plugins;

    # test.shtml contains SSI directives which should cause some error
    # log records
    my $test = { file_path => [ 't/test.shtml', '.' ] };

    check_webtest(webtest => $WEBTEST,
		  opts => \%OPTS,
		  tests => [ $test ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache4');
}

# 17: ignore_error_log param test
{
    $WEBTEST->reset_plugins;

    my $opts = { %OPTS, ignore_error_log => 'yes' };

    check_webtest(webtest => $WEBTEST,
		  opts => $opts,
		  tests => [ $TEST, $TEST, $TEST ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache5');
}

# 18: ignore_error_log param test
{
    $WEBTEST->reset_plugins;

    my $opts = { %OPTS, ignore_error_log => 'yes' };
    my $test = { file_path => [ 't/test.shtml', '.' ] };

    check_webtest(webtest => $WEBTEST,
		  opts => $opts,
		  tests => [ $test ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache6');
}

# 19: test apache_loglevel param
{
    $WEBTEST->reset_plugins;

    my $opts = { %OPTS, apache_loglevel => 'crit' };
    my $test = { file_path => [ 't/test.shtml', '.' ] };

    check_webtest(webtest => $WEBTEST,
		  opts => $opts,
		  tests => [ $test ],
		  server_hostname => 'localhost',
		  check_file => 't/test.out/apache7');
}

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path =~ m|^/error-log-(\d+)|) {
	my $num = $1;

	if($num) {
	    # write some pseudo error log entries
	    my $file = $ERROR_LOG;
	    my $fh = new IO::File;
	    $fh->open(">> $file") or die "Can't open file $file: $!";
	    $fh->print("ERROR\n") for(1 .. $num);
	    $fh->close;
	}

	$connect->send_file_response('t/test1.txt');
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
