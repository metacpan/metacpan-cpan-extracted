#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::BadRoute::BadMethod;
use Jedi::App;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->_jedi_routes_push( 'PLOP', '/', sub { } );

    return;
}

1;
