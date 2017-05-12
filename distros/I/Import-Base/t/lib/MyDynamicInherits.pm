package
    MyDynamicInherits;

use strict;
use warnings;
use base 'MyDynamic';

sub modules {
    my ( $class, $bundles, $args ) = @_;
    my @modules = (
        '-strict' => [qw( vars )],
    );
    my %bundles = (
        'Spec' => [
            'File::Spec::Functions' => [qw( catfile )],
        ],
        Lax => [
            '-strict',
            '-warnings',
        ],
    );
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

1;
