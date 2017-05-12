#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::hostip;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/', $jedi->can('get_hostip') );

    return;
}

sub get_hostip {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body( $jedi->jedi_host_ip );

    return 1;
}

1;
