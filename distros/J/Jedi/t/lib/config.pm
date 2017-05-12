#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::config;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/', $jedi->can('get_config') );

    return;
}

sub get_config {
    my ( $jedi, $request, $response ) = @_;
    $response->status(200);
    $response->body( $jedi->jedi_config->{myconf} // 'noconf' );

    return 1;
}

1;
