package
    UseCase::Moo::ApplyRole;

use strict;
use warnings;
use Test::More;
use base 'Import::Base';

our %IMPORT_BUNDLES = (
    'Class' => [ 'Moo' ],
    'Plugin' => [
        sub {
            my ( $bundles, $args ) = @_;
            $args->{package}->can( 'with' )->( 'UseCase::Moo::ApplyRole::Role' );
            ();
        },
    ],
    'WithRequires' => [
        sub {
            my ( $bundles, $args ) = @_;
            $args->{package}->can( 'with' )->( 'UseCase::Moo::ApplyRole::WithRequires' );
            ();
        },
    ],
    'Role' => [ 'Moo::Role' ],
);

1;
