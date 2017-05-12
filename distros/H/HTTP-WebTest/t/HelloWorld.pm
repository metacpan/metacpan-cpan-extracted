# $Id: HelloWorld.pm,v 1.2 2002/12/12 23:22:07 m_ilya Exp $

package HelloWorld;

use strict;

use base qw(HTTP::WebTest::Plugin);

sub check_response {
    my $self = shift;

    my $path = $self->webtest->current_request->uri->path;

    my $ok = $path eq '/hello';

    return ['Are we welcome?', $self->test_result($ok, 'Hello, World!')];
}

1;
