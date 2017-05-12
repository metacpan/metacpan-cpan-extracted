#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::configs::myConfigRoot;
use Jedi::App;

sub jedi_app {
    my ($app) = @_;
    $app->get(
        '/',
        sub {
            my ( $self, $request, $response ) = @_;
            $response->status(200);
            $response->body( $self->jedi_config->{ ref $self }{text} );
        }
    );
}

1;
