package
    MyDynamic;

use strict;
use warnings;
use base 'Import::Base';

sub modules {
    my ( $class, $bundles, $args ) = @_;
    my @modules = (
        "strict",
        "warnings",
    );
    my %bundles = (
        'Spec' => [
            'File::Spec::Functions' => [qw( catdir )],
        ],
        'lax' => [
            '-warnings' => [qw( uninitialized )],
        ],
    );
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

1;
