# $Id: ContentSizeTest.pm,v 1.9 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::ContentSizeTest;

=head1 NAME

HTTP::WebTest::Plugin::ContentSizeTest - Response body size checks

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin tests the size the HTTP response content.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 min_bytes

Minimum number of bytes expected in returned page.

=head3 Allowed values

Any integer less than C<max_bytes> (if C<max_bytes> is specified).

=head2 max_bytes

Maximum number of bytes expected in returned page.

=head3 Allowed values

Any integer greater that zero and greater than C<min_bytes> (if
C<min_bytes> is specified).

=cut

sub param_types {
    return q(min_bytes scalar
             max_bytes scalar);
}

sub check_response {
    my $self = shift;

    # response content length
    my $nbytes = length $self->webtest->current_response->content;

    $self->validate_params(qw(min_bytes max_bytes));

    # size limits
    my $min_bytes = $self->test_param('min_bytes');
    my $max_bytes = $self->test_param('max_bytes');

    # test results
    my @results = ();
    my @ret = ();

    # check minimal size
    if(defined $min_bytes) {
	my $ok = $nbytes >= $min_bytes;
	my $comment = 'Number of returned bytes (';
	$comment .=  sprintf '%6d', $nbytes;
	$comment .= ' ) is > or =';
	$comment .= sprintf '%6d', $min_bytes;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    # check maximal size
    if(defined $max_bytes) {
	my $ok = $nbytes <= $max_bytes;
	my $comment = 'Number of returned bytes (';
	$comment .=  sprintf '%6d', $nbytes;
	$comment .= ' ) is < or =';
	$comment .= sprintf '%6d', $max_bytes;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    push @ret, [ 'Content size check', @results ] if @results;

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
