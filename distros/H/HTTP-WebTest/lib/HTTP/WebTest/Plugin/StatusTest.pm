# $Id: StatusTest.pm,v 1.9 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::StatusTest;

=head1 NAME

HTTP::WebTest::Plugin::StatusTest - Checks the HTTP response status

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin checks the HTTP response status.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::Status;

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 status_code

Given numeric HTTP Status Code, tests response returned that value.

=head3 Default value

C<200> (OK).

=cut

sub param_types {
  return q(status_code scalar);
}

sub check_response {
    my $self = shift;

    $self->validate_params(qw(status_code));

    my $code = $self->webtest->current_response->code;
    my $status_line = $self->webtest->current_response->status_line;

    my $expected_code = $self->test_param('status_code', RC_OK);
    my $ok = $code eq $expected_code;

    my $comment = "Expected '$expected_code' and got: " . $status_line;

    return ['Status code check', $self->test_result($ok, $comment)];
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
