package t::Secrets;

use strict;
use Test::More;

sub replace {
    my ( $class, $conf, $key ) = @_;
    return "secret-$key";
}
1;
