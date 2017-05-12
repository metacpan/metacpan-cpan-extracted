# $Id: StartTests.pm,v 1.1 2002/05/26 20:03:16 m_ilya Exp $

package StartTests;

use strict;

use base qw(HTTP::WebTest::Plugin);

sub start_tests {
    my $self = shift;

    $StartTests::counter ++;
}

1;
