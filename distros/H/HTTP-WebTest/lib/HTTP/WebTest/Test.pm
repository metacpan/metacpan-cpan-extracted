# $Id: Test.pm,v 1.7 2003/03/02 11:52:10 m_ilya Exp $

package HTTP::WebTest::Test;

=head1 NAME

HTTP::WebTest::Test - Test object class

=head1 SYNOPSIS

    use HTTP::WebTest::Test;

    my $test = HTTP::WebTest::Test->new(%params);
    my $test = HTTP::WebTest::Test->convert($raw_test);

    my $value = $test->param($param);
    my $value = $test->params->{$param};

    my $results = $test->results;
    my $result = $test->result->[0];
    $test->result->[0] = $result;
    $test->results([ @results ]);

    my $request = $test->request;
    $test->request($request);
    my $response = $test->response;
    $test->response($response);
    my $response_time = $test->response_time;
    $test->response_time($response_time);

=head1 DESCRIPTION

Objects of this class represent tests.  They store both test parameters and
test results.

=head1 CLASS METHODS

=cut

use strict;

use HTTP::WebTest::Utils qw(make_access_method);

=head2 new (%params)

Constructor.

=head3 Parameters

=over 4

=item * %params

A hash with test parameters.

=back

=head3 Returns

A new C<HTTP::WebTest::Test> object.

=cut

sub new {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;
    $self->params({ %params });

    return $self;
}

=head2 params

=head3 Returns

A reference to a hash with all test parameters.

=cut

*params = make_access_method('PARAMS', sub { {} });

=head2 param ($param)

=head3 Returns

A value of test parameter named C<$param>.

=cut

sub param {
    my $self = shift;
    my $param = shift;

    return $self->params->{$param};
}

=head2 results ($optional_results)

Can set L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> objects
for this C<HTTP::WebTest::Test> object if an array reference
C<$optional_results> is passed.

=head3 Returns

A reference to an array that contains
L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> objects.

=cut

*results = make_access_method('RESULTS', sub { [] });

=head2 request ($optional_request)

If parameter C<$optional_request> is passed,
set L<HTTP::Request|HTTP::Request> object for this
C<HTTP::WebTest::Test> object.

=head3 Returns

A L<HTTP::Request|HTTP::Request> object.

=cut

*request = make_access_method('REQUEST');

=head2 response ($optional_response)

If parameter C<$optional_response> is passed,
set L<HTTP::Response|HTTP::Response> object for this
C<HTTP::WebTest::Test> object.

=head3 Returns

A L<HTTP::Response|HTTP::Response> object.

=cut

*response = make_access_method('RESPONSE');

=head2 response_time ($optional_response_time)

If parameter C<$optional_response_time> is passed,
set response time for this C<HTTP::WebTest::Test> object.

=head3 Returns

A response time.

=cut

*response_time = make_access_method('RESPONSE_TIME');

=head2 convert ($test)

Tries to convert test definition in some form into
C<HTTP::WebTest::Test> object.  Currenlty supports test defintion in
form of C<HTTP::WebTest::Test> object (it is just passed through) or in
the form of hash reference:

    { test_param1 => test_value1, test_param2 => test_value2 }

=head3 Returns

A new C<HTTP::WebTest::Test> object.

=cut

sub convert {
    my $class = shift;
    my $test = shift;

    return $test if UNIVERSAL::isa($test, 'HTTP::WebTest::Test');

    my $conv_test = $class->new(%$test);

    return $conv_test;
}

=head2 reset ()

Resets test object

=cut

sub reset {
    my $self = shift;

    $self->request(undef);
    $self->response(undef);
    $self->response_time(undef);
    $self->results(undef);
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult>

L<HTTP::Request|HTTP::Request>

L<HTTP::Response|HTTP::Response>

=cut

1;
