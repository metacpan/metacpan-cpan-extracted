package t::Secrets;

use strict;
use Test::More;

sub replace {
    my ( $class, $conf, $key ) = @_;
    is( $conf->{secretPlaceholderConfig},
        1, "Found secrets module configuration" );
    return "secret-$key";
}
1;
