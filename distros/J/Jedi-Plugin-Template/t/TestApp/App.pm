#
# This file is part of Jedi-Plugin-Template
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::TestApp::App;
use Jedi::App;
use Jedi::Plugin::Template;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/',    $jedi->can('handle_index') );
    $jedi->get( qr{.*}, $jedi->can('handle_allothers') );

    return;
}

sub handle_index {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('index');
    return;
}

sub handle_allothers {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body('allothers');
    return;
}

1;
