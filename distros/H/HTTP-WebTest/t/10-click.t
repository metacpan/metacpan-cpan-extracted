#!/usr/bin/perl -w

# $Id: 10-click.t,v 1.13 2003/04/26 15:12:14 m_ilya Exp $

# This script tests HTTP::WebTest::Plugin::Click plugin

use strict;
use HTTP::Status;

use HTTP::WebTest;
use HTTP::WebTest::SelfTest;
use HTTP::WebTest::Utils qw(start_webserver stop_webserver);

use Test::More tests => 9;

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $OPTS = { plugins => [ '::Click' ] };

# 1: test following links in HTML files
{
    generate_testfile(file => 't/test2.html', server_url => $URL);

    my $tests = [ { url => abs_url($URL, '/test1.html'),
		    text_require => [ '<title>Test File 1</title>' ] },
		  # link which points back to test1.html
		  { click_link => 'Self Reference',
		    text_require => [ '<title>Test File 1</title>' ] },
		  # link to test2.html
		  { click_link => 'Test 2',
		    text_require => [ '<title>Test File 2</title>' ] },
		  # link on text file from test2.html (note that it
		  # has <base> tag)
		  { click_link => 'Text File',
		    text_require => [ 'TEST TEST' ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_link1');
}

# 2: test that click_link doesn't work with text files
{
    my $tests = [ { url => abs_url($URL, '/test3.txt'),
		    text_require => [ '<a href="test2.html">Test 2</a>' ] },
		  { click_link => 'Test 2',
		    text_forbid => [ '<title>Test File 2</title>' ] },
		];

    catch_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_link2');
}

# 3: test missing link
{
    my $tests = [ { url => abs_url($URL, '/test1.html'),
		    text_require => [ '<title>Test File 1</title>' ] },
		  # missing link
		  { click_link => 'No such link',
		    text_require => [ '<title>Test File 1</title>' ] }
		];

    catch_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_link3');
}

# 4: test clicking submit buttons in forms
{
    my $tests = [ { url => abs_url($URL, '/test3.html'),
		    text_require => [ '<title>Test File 3</title>' ] },
		  # click button to submit form to /test1.txt
		  { click_button => 'Button1',
		    text_require => [ 'abcde' ] },
		  { url => abs_url($URL, '/test3.html'),
		    text_require => [ '<title>Test File 3</title>' ] },
		  # click another button to submit form to /test2.txt
		  { click_button => 'Button2',
		    text_require => [ 'begin 644' ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_button1');
}

# 5: clicking submit buttons in non HTML pages should not work
{
    my $tests = [ { url => abs_url($URL, '/test3.txt'),
		    text_require => [ '<a href="test2.html">Test 2</a>' ] },
		  { click_button => 'Button1',
		    text_forbid => [ 'abcde' ] },
		];

    catch_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_button2');
}

# 6: clicking non-existing button
{
    my $tests = [ { url => abs_url($URL, '/test3.html'),
		    text_require => [ '<title>Test File 3</title>' ] },
		  # try to specify non-submit input control
		  { click_button => 'NonButton',
		    text_require => [ 'abcde' ] },
		];

    catch_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_button3');
}

# 7: submit form and pass some parameters
{
    my $tests = [ { url => abs_url($URL, '/test4.html'),
		    text_require => [ '<title>Test File 4</title>' ] },
		  # click button to submit form to /show-request
		  { click_button => 'Button',
		    method => 'get',
		    params => [ param1 => 'value1' ],
		    text_require => [ 'Method: <GET>',
				      'Query: <param1=value1>',
				      'Content: <>' ],
		  },
		  # click button to submit form to /show-request
		  { url => abs_url($URL, '/test4.html'),
		    text_require => [ '<title>Test File 4</title>' ] },
		  { click_button => 'Button',
		    method => 'post',
		    params => [ param1 => 'value1' ],
		    text_require => [ 'Method: <POST>',
				      'Query: <>',
				      'Content: <param1=value1>' ],
		  }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_button4');
}

# 8: test 'form_name' test parameter
{
    my $tests = [ { url => abs_url($URL, '/test5.html'),
		    text_require => [ '<title>Test File 5</title>' ] },
		  # click button to submit form to /show-request
		  { form_name => 'yy',
		    params => [ param1 => 'value1' ],
		    text_require => [ 'Method: <GET>',
				      'Query: <param1=value1>',
				      'Content: <>' ],
		  },
		  { url => abs_url($URL, '/test5.html'),
		    text_require => [ '<title>Test File 5</title>' ] },
		  # click button to submit form to /bad-request
		  { form_name => 'xx',
		    params => [ param1 => 'value1' ],
		    status_code => 404,
		  },
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/form_name');
}

# 9: test 'click_button' with images
{
    my $tests = [ { url => abs_url($URL, '/test6.html'),
		    text_require => [ '<title>Test File 6</title>' ] },
		  # click button to submit form to /show-request
		  { click_button => 'Button2',
		    params => [ param1 => 'value1' ],
		    text_require => [ 'Method: <GET>',
				      'Query: <param1=value1>',
				      'Content: <>' ],
		  },
		  { url => abs_url($URL, '/test6.html'),
		    text_require => [ '<title>Test File 6</title>' ] },
		  # click button to submit form to /show-request
		  { click_button => 'y.gif',
		    params => [ param1 => 'value1' ],
		    text_require => [ 'Method: <GET>',
				      'Query: <param1=value1>',
				      'Content: <>' ],
		  },
		  { url => abs_url($URL, '/test6.html'),
		    text_require => [ '<title>Test File 6</title>' ] },
		  # click button to submit form to /bad-request
		  { click_button => 'Button1',
		    params => [ param1 => 'value1' ],
		    status_code => 404,
		  },
		  { url => abs_url($URL, '/test6.html'),
		    text_require => [ '<title>Test File 6</title>' ] },
		  # click button to submit form to /bad-request
		  { click_button => 'x.gif',
		    params => [ param1 => 'value1' ],
		    status_code => 404,
		  },
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => $OPTS,
		  check_file => 't/test.out/click_button_image');
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path =~ m(/test1.txt|/dir/alttest1.txt)) {
	$connect->send_file_response('t/test1.txt');
    } elsif($path =~ m|^/test\d+.\w+$|) {
	$connect->send_file_response('t' . $path);
    } elsif($path eq '/show-request') {
	my $content = '';
	$content .= 'Method: <' . $request->method . ">\n";
	$content .= 'Query: <' . ($request->url->query || '') . ">\n";
	$content .= 'Content: <' . $request->content . ">\n";

	# create response object
	my $response = new HTTP::Response(RC_OK);
	$response->header(Content_Type => 'text/plain');
	$response->content($content);

	# send it to browser
	$connect->send_response($response);
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}

# run test inside eval and test for raised exception
sub catch_webtest {
    my %param = @_;

    my $webtest    = $param{webtest};
    my $tests      = $param{tests};
    my $opts       = $param{opts};
    my $check_file = $param{check_file};

    my $output = '';

    eval {
	$webtest->run_tests($tests, { %$opts, output_ref => \$output });
    };
    if($@) {
	my $text = $@;
	my $out_filter = sub {
	    $_[0] =~ s/at .*?API.pm line \d+/at path-to-API.pm line NN/;
	};
	canonical_output(output_ref => \$text,
			 out_filter => $out_filter);
	compare_output(check_file => $check_file,
		       output_ref => \$text);
    } else {
	fail('Was expecting an exception - did not get any');
    }
}
