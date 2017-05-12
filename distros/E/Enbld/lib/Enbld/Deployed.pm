package Enbld::Deployed;

use strict;
use warnings;

our %deployed;

sub add {
    my ( $pkg, $config ) = @_;

    $deployed{$config->name} = $config;

    return $config->name;
}

sub is_deployed {
    my ( $pkg, $name ) = @_;

    return $deployed{$name} if ( $deployed{$name} );

    return;
}

1;
