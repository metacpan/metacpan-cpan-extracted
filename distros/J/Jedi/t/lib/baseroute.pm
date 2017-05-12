#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::baseroute;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;
    $jedi->get(
        '/',
        sub {
            my ( $app, $req, $resp ) = @_;
            $resp->status(200);
            $resp->body( $app->jedi_base_route );
        }
    );
}
1;
