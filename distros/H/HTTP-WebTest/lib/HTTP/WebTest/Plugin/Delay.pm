# $Id: Delay.pm,v 1.4 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::Delay;

=head1 NAME

HTTP::WebTest::Plugin::Delay - Pause before running test

=head1 SYNOPSIS

    plugins = ( ::Delay )

    test_name = Name
        delay = 10
        ....
    end_test

=head1 DESCRIPTION

This plugin module lets you specify pauses before running specific tests
in the test sequence.

=cut

use strict;
use base qw(HTTP::WebTest::Plugin);

use Time::HiRes qw(sleep);

=head1 TEST PARAMETERS

=for pod_merge copy opt_params

=head2 delay

Duration of pause (in seconds) before running test.

=head3 Allowed values

Any number greater that zero.

=cut

sub param_types {
    return q(delay scalar);
}

sub prepare_request {
    my $self = shift;

    if(my $delay = $self->test_param('delay')) {
	sleep($delay);
    }
}

=head1 COPYRIGHT

Copyright (c) 2002-2003 Duncan Cameron.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;

