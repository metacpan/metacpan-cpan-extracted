# $Id: API.pm,v 1.29 2003/03/02 11:52:10 m_ilya Exp $

# note that it is not package HTTP::WebTest::API.  That's right
package HTTP::WebTest;

=head1 NAME

HTTP::WebTest::API - API of HTTP::WebTest

=head1 SYNOPSIS

    use HTTP::WebTest;

    my $webtest = new HTTP::WebTest;

    # run test from file
    $webtest->run_wtscript('script.wt');

    # or (to pass test parameters as method arguments)
    $webtest->run_tests($tests);

=head1 DESCRIPTION

This document describes Perl API of C<HTTP::WebTest>.

=head1 METHODS

=cut

use 5.005;
use strict;

use IO::File;
use LWP::UserAgent;
use Time::HiRes qw(time);

use HTTP::WebTest::Cookies;
use HTTP::WebTest::Utils qw(make_access_method load_package);
use HTTP::WebTest::Plugin;
use HTTP::WebTest::Request;
use HTTP::WebTest::Test;

# BACKWARD COMPATIBILITY BITS - exporting this subroutine is a part of
# HTTP-WebTest 1.xx API

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(run_web_test);

=head2 new ()

Constructor.

=head3 Returns

A new C<HTTP::WebTest> object.

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return $self;
}

=head2 run_tests ($tests, $optional_params)

Runs a test sequence.

=head3 Parameters

=over 4

=item * $test

A reference to an array that contains test objects.

=item * $optional_params

A reference to a hash that contains optional global parameters for test.

=back

=cut

sub run_tests {
    my $self = shift;
    my $tests = shift;
    my $params = shift || {};

    $self->reset_plugins;

    # reset current test object
    $self->current_test(undef);

    # convert tests to canonic representation
    my @tests = $self->convert_tests(@$tests);

    $self->tests([ @tests ]);
    $self->_global_test_params($params);

    # start tests hook; note that plugins can load other plugins and
    # modify $self->plugins in start tests hook
    my %initialized = ();
    {
	my $done = 1;

	my @plugins = @{$self->plugins};
	for my $plugin (@plugins) {
	    unless($initialized{$plugin}) {
		if($plugin->can('start_tests')) {
		    $plugin->start_tests;
		}
		$initialized{$plugin} = 1;
		# we must do one more round to check for uninitialized
		# plugins
		$done = 0;
	    }
	}

	redo unless $done;
    }

    # run all tests: note that content and length of @{$self->tests}
    # may change inside the loop so idiomatic "for my $i (...)"
    # doesn't work here
    for(my $i = 0; $i < @{$self->tests}; $i ++) {
	my $test = $self->tests->[$i];
	$self->current_test_num($i);
	$self->run_test($test, $self->_global_test_params);
    }

    # end tests hook
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('end_tests')) {
	    $plugin->end_tests;
	}
    }
}

=head2 run_wtscript ($wtscript, $optional_params)

Reads wtscript and runs tests it defines.

=head3 Parameters

=over 4

=item * $wtscript

Either the name of wtscript file or wtscript passed as string. Very
simple heuristic is used distinguish first from second. If
C<$wtscript> contains either C<\n> or C<\r> it is treated as a
wtscript string. Otherwise, it is treated as a file name.

=item * $optional_params

=back

A reference to a hash that contains optional test parameters that can
override parameters defined in wtscript.

=cut

sub run_wtscript {
    my $self = shift;
    my $wtscript = shift;
    my $opts_override = shift || {};

    unless($wtscript =~ /[\r\n]/) {
	my $fh = new IO::File;
	my $file = $wtscript;
	$fh->open("< $file") or
	    die "HTTP::WebTest: Can't open file $file: $!";

	$wtscript = join '', <$fh>;
	$fh->close;
    }

    my ($tests, $opts) = $self->parse($wtscript);

    $self->run_tests($tests, { %$opts, %$opts_override });
}

=head2 num_fail ()

=head3 Returns

The number of failed tests.

=cut

sub num_fail {
    my $self = shift;

    my $fail = 0;

    for my $test (@{$self->tests}) {
	my $results = $test->results;

	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		$fail ++ unless $subresult;
	    }
	}
    }

    return $fail;
}

=head2 num_succeed ()

=head3 Returns

The number of passed tests.

=cut

sub num_succeed {
    my $self = shift;

    my $succeed = 0;

    for my $test (@{$self->tests}) {
	my $results = $test->results;

	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		$succeed ++ if $subresult;
	    }
	}
    }

    return $succeed;
}

=head2 have_succeed ()

=head3 Returns

True if all tests have passed, false otherwise.

=cut

sub have_succeed {
    my $self = shift;

    $self->num_fail > 0 ? 0 : 1;
}

=head2 parser_package($optional_parser_package)

If $optional_parser is defined sets a parser package to use when
parsing wtscript files. Otherwise just returns current parser package.

=head3 Returns

The parser package.

=cut

*parser_package = make_access_method('PARSER_PACKAGE',
                                     sub { 'HTTP::WebTest::Parser' });

=head2 parse ($data)

Parses test specification in wtscript format.

=head3 Parameters

=over 4

=item * $data

Scalar that contains test specification in wtscript format.

=back

=head3 Returns

A list of two elements.  First element is a reference to an array that
contains test objects.  Second element is a reference to a hash that
contains optional global test parameters.

It can be passed directly to C<run_tests>.

=head3 Example

    $webtest->run_tests($webtest->parse($data));

=cut

sub parse {
    my $self = shift;
    my $data = shift;

    load_package('HTTP::WebTest::Parser')
        unless(UNIVERSAL::can($self->parser_package, 'parse'));

    my ($tests, $opts) = $self->parser_package->parse($data);

    return ($tests, $opts);
}

=head1 LOW-LEVEL API METHODS

Most users don't need to use this part of C<HTTP::WebTest> API
directly.  It could be useful for users who want to:

=over 4

=item *

Write an C<HTTP::WebTest> plugin.

=item *

Get access to L<LWP::UserAgent|LWP::UserAgent>,
L<HTTP::WebTest::Request|HTTP::WebTest::Request>,
L<HTTP::Response|HTTP::Response> and
other objects used by C<HTTP::WebTest> during runing test sequence.

=back

=head2 tests ()

=head3 Returns

A reference to an array that contains test objects.

=cut

*tests = make_access_method('TESTS', sub { [] });

=head2 user_agent ($optional_user_agent)

If $optional_user_agent is a user agent object,
it is used by the C<HTTP::WebTest> object for all requests.
If $optional_user_agent is passed as undef, the HTTP::WebTest object is
reset to use the default user agent.

=head3 Returns

The user agent object used by the C<HTTP::WebTest> object.

=cut

*user_agent = make_access_method('USER_AGENT', 'create_user_agent');

=head2 plugins ($optional_plugins)

If C<$optional_plugins> is a reference to an array that contains plugin 
objects, the C<HTTP::WebTest> object uses these plugins while running tests.
If C<$optional_plugins> is passed as
undef, the C<HTTP::WebTest> object is reset to use the default set of plugins.

=head3 Returns

A reference to an array that contains plugin objects.  If you
add or remove plugin objects in this array, you will change the set of
plugins used by C<HTTP::WebTest> object during tests.

=cut

*plugins = make_access_method('PLUGINS', 'default_plugins');

=head2 create_user_agent ()

=head3 Returns

A new L<LWP::UserAgent|LWP::UserAgent> object, initialized with default
settings.

=cut

sub create_user_agent {
    my $self = shift;

    # create user agent
    my $user_agent = new LWP::UserAgent;

    # create cookie jar
    $user_agent->cookie_jar(new HTTP::WebTest::Cookies);

    return $user_agent;
}

=head2 reset_user_agent ()

Resets the user agent to the default.

=cut

sub reset_user_agent {
    my $self = shift;

    $self->user_agent(undef);
}

=head2 reset_plugins ()

Resets the set of plugin objects to the default set.

=cut

sub reset_plugins {
    my $self = shift;

    $self->plugins(undef);
}

=head2 default_plugins ()

=head3 Returns

A reference to the set of default plugin objects.

=cut

sub default_plugins {
    my $self = shift;

    my @plugins = ();

    for my $sn_package (qw(Loader SetRequest Cookies
                           StatusTest TextMatchTest
                           ContentSizeTest ResponseTimeTest
                           DefaultReport)) {
	my $package = "HTTP::WebTest::Plugin::$sn_package";

	load_package($package);

	push @plugins, $package->new($self);
    }

    return [@plugins];
}

# accessor method for global test parameters data
*_global_test_params = make_access_method('GLOBAL_TEST_PARAMS');

=head2 global_test_param ($param)

=head3 Returns

The value of the global test parameter C<$param>.

=cut

sub global_test_param {
    my $self = shift;
    my $param = shift;

    return $self->_global_test_params->{$param};
}

=head2 current_test_num ()

=head3 Returns

The number of the current test or, if no test is running, the current test run.

=cut

*current_test_num = make_access_method('CURRENT_TEST_NUM');

=head2 current_test ()

=head3 Returns

The L<HTTP::WebTest::Test|HTTP::WebTest::Test> object which corresponds
to the current test or, if no test is running, the current test run.

=cut

*current_test = make_access_method('CURRENT_TEST');

=head2 current_request ()

=head3 Returns

The L<HTTP::WebTest::Request|HTTP::WebTest::Request> object used in current test.

=cut

sub current_request { shift->current_test->request(@_) }

=head2 current_response ()

=head3 Returns

The L<HTTP::Response|HTTP::Response> object used in current test.

=cut

sub current_response { shift->current_test->response(@_) }

=head2 current_response_time ()

=head3 Returns

The response time for the HTTP request used in current test.

=cut

sub current_response_time { shift->current_test->response_time(@_) }

=head2 current_results ()

=head3 Returns

A reference to an array that contains the results of checks made by plugins
for the current test.

=cut

sub current_results { shift->current_test->results(@_) }

=head2 run_test ($test, $optional_params)

Runs a single test.

=head3 Parameters

=over 4

=item * $test

A test object.

=item * $optional_params

A reference to a hash that contains optional global test parameters.

=back

=cut

sub run_test {
    my $self = shift;
    my $test = shift;
    my $params = shift || {};

    # convert test to canonic representation
    $test = $self->convert_tests($test);
    $self->current_test($test);

    $self->_global_test_params($params);

    # create request (note that actual uri is more likely to be
    # set in plugins)
    my $request = HTTP::WebTest::Request->new('GET' =>
					      'http://MISSING_HOSTNAME/');
    $self->current_request($request);

    # set request object with plugins
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('prepare_request')) {
	    $plugin->prepare_request;
	}
    }

    # check if one of plugins did change request uri
    if($request->uri eq 'http://MISSING_HOSTNAME/') {
	die "HTTP::WebTest: request uri is not set";
    }

    # measure current time
    my $time1 = time;

    # get response
    my $response = $self->user_agent->request($request);
    $self->current_response($response);

    # measure current time
    my $time2 = time;

    # calculate response time
    $self->current_response_time($time2 - $time1);

    # init results
    my @results = ();

    # check response with plugins
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('check_response')) {
	    push @results, $plugin->check_response;
	}
    }
    $self->current_results(\@results);

    # report test results
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('report_test')) {
	    $plugin->report_test;
	}
    }
}

=head2 convert_tests (@tests)

Converts test objects C<@tests> of any supported type to internal
canonical representation (i.e. to
L<HTTP::WebTest::Test|HTTP::WebTest::Test> objects).

=head3 Returns

A list of L<HTTP::WebTest::Test|HTTP::WebTest::Test> objects (list
context) or the first value from a list of
L<HTTP::WebTest::Test|HTTP::WebTest::Test> objects (scalar context).

=cut

sub convert_tests {
    my $self = shift;
    my @tests = @_;

    my @conv = map HTTP::WebTest::Test->convert($_), @tests;

    return wantarray ? @conv : $conv[0];
}

=head1 BACKWARD COMPATIBILITY

C<HTTP::WebTest 2.xx> offers a richer API than its predecessor
C<HTTP::WebTest 1.xx>.  The old API is still supported, but may be 
deprecated in the future and is not recommended.

=cut

=head2 web_test ($file, $num_fail_ref, $num_succeed_ref, $optional_options)

Reads wtscript file and runs tests it defines.

In C<HTTP::WebTest 2.xx> you should use method C<run_wtscript>.

=head3 Parameters

=over 4

=item * $file

Name of a wtscript file.

=item * $num_fail_ref

A reference on scalar where a number of failed tests will be stored or
C<undef> if you don't need it.

=item * $num_succed_ref

A reference on scalar where a number of passed tests will be stored or
C<undef> if you don't need it.

=item * $optional_params

A reference to a hash that contains optional test parameters which can
override parameters defined in wtscript.

=back

=cut

sub web_test {
    my $self = shift;
    my $file = shift;
    my $num_fail_ref = shift;
    my $num_succeed_ref = shift;
    my $opts = shift || {};

    $self->run_wtscript($file, $opts);

    $$num_fail_ref = $self->num_fail if defined $num_fail_ref;
    $$num_succeed_ref = $self->num_succeed if defined $num_succeed_ref;

    return $self->have_succeed;
}

=head2 run_web_test ($tests, $num_fail_ref, $num_succeed_ref, $optional_options)

This is not a method.  It is subroutine which creates a
C<HTTP::WebTest> object and runs test sequence using it.

You need to either import C<run_web_test> into you namespace with

    use HTTP::WebTest qw(run_web_test);

or use the full name C<HTTP::WebTest::run_web_test>

In C<HTTP::WebTest 2.xx> you should use the method C<run_tests>.

=head3 Parameters

=over 4

=item * $tests

A reference to an array that contains a set of test objects.

=item * $num_fail_ref

A reference to a scalar where the number of failed tests will be stored or
C<undef> if you don't need it.

=item * $num_succed_ref

A reference to a scalar where the number of passed tests will be stored or
C<undef> if you don't need it.

=item * $optional_params

A reference to a hash that contains optional test parameters.

=back

=cut

sub run_web_test {
    my $tests = shift;
    my $num_fail_ref = shift;
    my $num_succeed_ref = shift;
    my $opts = shift || {};

    my $webtest = new HTTP::WebTest;

    $webtest->run_tests($tests, $opts);

    $$num_fail_ref = $webtest->num_fail if defined $num_fail_ref;
    $$num_succeed_ref = $webtest->num_succeed if defined $num_succeed_ref;

    return $webtest->have_succeed;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<HTTP::WebTest::Request|HTTP::WebTest::Request>

L<LWP::UserAgent|LWP::UserAgent>

L<HTTP::Response|HTTP::Response>

L<HTTP::WebTest::Cookies|HTTP::WebTest::Cookies>

L<HTTP::WebTest::Parser|HTTP::WebTest::Parser>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Test|HTTP::WebTest::Test>

=cut

1;
