#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::multipleheaders;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/', $jedi->can('multiple_headers') );

    return;
}

sub multiple_headers {
    my ( $jedi, $request, $response ) = @_;

    $response->status(200);
    $response->body('OK');
    $response->push_header( 'test', 1 );
    $response->push_header( 'test', 2 );

    return 1;
}

1;
