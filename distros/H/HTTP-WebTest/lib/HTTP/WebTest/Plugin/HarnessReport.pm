# $Id: HarnessReport.pm,v 1.12 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::HarnessReport;

=head1 NAME

HTTP::WebTest::Plugin::HarnessReport - Test::Harness compatible reports

=head1 SYNOPSIS

N/A

=head1 DESCRIPTION

This plugin creates reports that are compatible with
L<Test::Harness|Test::Harness>.  By default, this plugin is not loaded
by L<HTTP::WebTest|HTTP::WebTest>.  To load it, use the global test
parameter C<plugins>.  Internally this plugin uses
L<Test::Builder|Test::Builder> module so it should be compatible with
other testing libraries (like L<Test::More|Test::More> or
L<Test::Differences|Test::Differences>).  You should be able to
intermix them freely in one test script.

Unless you want to get mix of outputs from the default report and this
report (normally you don't want it), the default report plugin should
be disabled.  See parameter C<default_report> (value C<no>).

Test parameters C<plugins> and C<default_report> are documented in
L<HTTP::WebTest|HTTP::WebTest>.

=head1 EXAMPLE

See L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook> for example.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);
use HTTP::WebTest::Utils qw(make_access_method);

use Test::Builder;

=head1 TEST PARAMETERS

None.

=cut

my $TEST = Test::Builder->new;

# declare supported test params
sub param_types {
    return q(test_name      scalar);
}

sub report_test {
    my $self = shift;

    my @results = @{$self->webtest->current_test->results};

    $self->validate_params(qw(test_name));

    my $test_name = $self->test_param('test_name');
    my $url = 'N/A';
    if($self->webtest->current_request) {
	$url = $self->webtest->current_request->uri;
    }

    # fool Test::Builder to generate diag output on STDOUT
    my $failure_output = $TEST->failure_output;
    $TEST->failure_output($TEST->output);

    $TEST->diag('-' x 60);
    $TEST->diag("URL: $url");
    $TEST->diag("Test Name: $test_name") if defined $test_name;

    my $all_ok = 1;

    for my $result (@{$self->webtest->current_results}) {
	# test results
	my $group_comment = $$result[0];

	my @results = @$result[1 .. @$result - 1];

	$TEST->diag(uc($group_comment));

	for my $subresult (@$result[1 .. @$result - 1]) {
	    my $comment = $subresult->comment;
	    my $ok      = $subresult->ok ? 'SUCCEED' : 'FAIL';
	    $all_ok   &&= $subresult->ok;

	    $TEST->diag("  $comment: $ok\n");
	}
    }

    # restore failure_output
    $TEST->failure_output($failure_output);

    local $Test::Builder::Level = 3;
    $TEST->ok($all_ok);
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<Test::Builder|Test::Builder>

=cut

1;
