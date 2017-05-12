# $Id: ResponseTimeTest.pm,v 1.7 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::ResponseTimeTest;

=head1 NAME

HTTP::WebTest::Plugin::ResponseTimeTest - Tests for response time

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin supports web server response time tests.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 min_rtime

Minimum web server response time (seconds) expected.

=head3 Allowed values

Any number less than C<max_rtime> (if C<max_rtime> is specified).

=head2 max_rtime

Maximum web server response time (seconds) expected.

=head3 Allowed values

Any number greater that zero and greater than C<min_rtime> (if
C<min_rtime> is specified).

=cut

sub param_types {
    return q(min_rtime scalar
             max_rtime scalar);
}

sub check_response {
    my $self = shift;

    # response time
    my $rtime = $self->webtest->current_response_time;

    $self->validate_params(qw(min_rtime max_rtime));

    # response time limits
    my $min_rtime = $self->test_param('min_rtime');
    my $max_rtime = $self->test_param('max_rtime');

    # test results
    my @results = ();
    my @ret = ();

    # check minimal size
    if(defined $min_rtime) {
	my $ok = $rtime >= $min_rtime;
	my $comment = 'Response time (';
	$comment .=  sprintf '%6.2f', $rtime;
	$comment .= ' ) is > or =';
	$comment .= sprintf '%6.2f', $min_rtime;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    # check maximal size
    if(defined $max_rtime) {
	my $ok = $rtime <= $max_rtime;
	my $comment = 'Response time (';
	$comment .=  sprintf '%6.2f', $rtime;
	$comment .= ' ) is < or =';
	$comment .= sprintf '%6.2f', $max_rtime;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    push @ret, [ 'Response time check', @results ] if @results;

    return @ret;
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
