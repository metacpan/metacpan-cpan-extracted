#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::advanced;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/',      $jedi->can('hello_world') );
    $jedi->get( qr{aaa},  $jedi->can('regexp') );
    $jedi->get( qr{aaaa}, $jedi->can('regexp2') );

    return;
}

sub hello_world {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('Hello World !');

    return 1;
}

sub regexp {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('aaa');
    return 1;
}

sub regexp2 {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body( $response->body . ',aaaa' );
}

1;
