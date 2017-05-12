#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::base;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/', $jedi->can('hello_world') );
    $jedi->post( '/', $jedi->can('hello_world_post') );
}

sub hello_world {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('Hello World !');

    return 1;
}

sub hello_world_post {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('Hello World POST !');

    return 1;
}
1;
