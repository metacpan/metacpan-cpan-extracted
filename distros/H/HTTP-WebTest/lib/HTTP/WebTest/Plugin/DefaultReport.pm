# $Id: DefaultReport.pm,v 1.10 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::DefaultReport;

=head1 NAME

HTTP::WebTest::Plugin::DefaultReport - Default test report plugin.

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin is the default test report plugin.  It builds a simple text
report.

=cut

use strict;

use base qw(HTTP::WebTest::ReportPlugin);
use HTTP::WebTest::Utils qw(make_access_method);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 default_report

I<GLOBAL PARAMETER>

This parameter controls whether the default report plugin is used for
test report creation.  Value C<yes> means that default report plugin
will be used, value C<no> means that it will not.
It can also be used to disable all output 
(i.e. if this parameter has value C<no> and no other report plugins
are loaded).

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 test_name

Name associated with this URL in the test report and error messages.

=head2 show_headers

Include request and response headers in the test report.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 show_html

Include content of HTTP response in the test report.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 show_cookies

Option to display any cookies sent or received.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 terse

Option to display shorter test report.

=over 4

=item * summary

Only a one-line summary for each URL

=item * failed_only

Only tests that failed and the summary

=item * no

Show all tests and the summary

=head3 Default value

C<no>

=back

=cut

sub param_types {
    return shift->SUPER::param_types . "\n" .
	   q(default_report yesno
             test_name      scalar
             show_html      yesno
             show_cookies   yesno
             show_headers   yesno
             terse          scalar('^(?:no|summary|failed_only)$') );
}

# accessor for temporary buffer
*tempout_ref = make_access_method('TEMPOUT_REF', sub { my $s = ''; \$s } );

sub start_tests {
    my $self = shift;

    $self->global_validate_params(qw(default_report));

    return unless $self->global_yesno_test_param('default_report', 1);

    $self->SUPER::start_tests;

    # reset temporary output storage
    $self->tempout_ref(undef);
}

sub report_test {
    my $self = shift;

    $self->global_validate_params(qw(default_report));

    return unless $self->global_yesno_test_param('default_report', 1);

    $self->validate_params(qw(test_name show_html show_headers
                              show_cookies terse));

    # get test params we handle
    my $test_name    = $self->test_param('test_name', 'N/A');
    my $show_html    = $self->yesno_test_param('show_html');
    my $show_cookies = $self->yesno_test_param('show_cookies');
    my $show_headers = $self->yesno_test_param('show_headers');
    my $terse        = lc $self->test_param('terse', 'no');

    my $url = 'N/A';
    if($self->webtest->current_request) {
	$url = $self->webtest->current_request->uri;
    }

    return if $terse eq 'summary';

    # output buffer
    my $out = '';

    # test header
    $out .= "Test Name: $test_name\n";
    $out .= "URL: $url\n\n";

    my $not_ok_num = 0;

    for my $result (@{$self->webtest->current_results}) {
	# test results
	my $group_comment = $$result[0];

	my @results = @$result[1 .. @$result - 1];
	my @not_ok_results = grep +(not $_->ok), @results;
	$not_ok_num += @not_ok_results;

	if($terse eq 'failed_only') {
	    # skip all positive results in output
	    @results = @not_ok_results;
	}

	next unless @results;

	$out .= $self->sformat(<<FORMAT, uc($group_comment));
  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
FORMAT

	for my $subresult (@$result[1 .. @$result - 1]) {
	    my $comment = $subresult->comment;
	    my $ok      = $subresult->ok ? 'SUCCEED' : 'FAIL';

	    $out .= $self->sformat(<<FORMAT, $comment, $ok);
    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<
FORMAT
	}
    }

    # true if show_*** parameters should take effect
    my $show_xxx = $terse eq 'failed_only' ? $not_ok_num > 0 : 1;

    my $response = $self->webtest->current_response;
    my $request = $self->webtest->current_request;

    if($show_headers and $show_xxx) {
	# show all headers

	$out .= "\n";

	$out .= "  REQUEST HEADERS:\n";
	$out .= $request->method . ' ' . $request->uri . "\n";
	$out .= $request->headers_as_string . "\n";
	$out .= "  RESPONSE HEADERS:\n";
	$out .= $response->protocol . " " . $response->status_line . "\n";
	$out .= $response->headers_as_string . "\n";
    }

    if($show_cookies and $show_xxx) {
	# show sent and recieved cookies

	my @sent = $request->header('Cookie');
	my @recv = $response->header('Set-Cookie');

	$out .= "\n";

	$out .= "  SENT COOKIE(S)\n";
	for my $cookie (@sent) {
	    $out .= "    $cookie\n";
	}
	unless(@sent) {
	    $out .= "    *** none ***\n";
	}

	$out .= "  RECEIVED COOKIE(S)\n";
	for my $cookie (@recv) {
	    $out .= "    $cookie\n";
	}
	unless(@recv) {
	    $out .= "    *** none ***\n";
	}
    }

    if($show_html and $show_xxx) {
	# content in response

	$out .= "\n";

	$out .= "  PAGE CONTENT:\n";
	$out .= $response->content . "\n";
    }

    $out .= "\n\n";

    ${$self->tempout_ref} .= $out;
}

sub end_tests {
    my $self = shift;

    $self->global_validate_params(qw(default_report));

    return unless $self->global_yesno_test_param('default_report', 1);

    $self->print("Failed  Succeeded  Test Name\n");

    my $total_fail_num = 0;
    my $total_suc_num = 0;

    for my $test (@{$self->webtest->tests}) {
	my $results = $test->results;

	my $fail_num = 0;
	my $suc_num = 0;
	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		if($subresult) {
		    $suc_num ++;
		} else {
		    $fail_num ++;
		}
	    }
	}

	$total_fail_num += $fail_num;
	$total_suc_num += $suc_num;

	my $name = $test->param('test_name') || '*** no name ***';
	$self->fprint(<<FORMAT, $fail_num, $suc_num, $name);
 @|||||     @||||| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
FORMAT
    }

    $self->print("\n\n");

    $self->print(${$self->tempout_ref});

    $self->print("Total web tests failed: $total_fail_num ",
		 " succeeded: $total_suc_num\n");

    $self->SUPER::end_tests;
}

# formated output
sub sformat {
    my $self = shift;
    my $format = shift;
    local $^A = '';
    formline($format, @_);
    return $^A;
}

# print line using format specification
sub fprint {
    my $self = shift;
    my $format = shift;
    $self->print($self->sformat($format, @_));
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
