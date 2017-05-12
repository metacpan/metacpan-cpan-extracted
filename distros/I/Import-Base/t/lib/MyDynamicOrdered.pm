package
    MyDynamicOrdered;

use strict;
use warnings;
use Test::More;
use base 'Import::Base';

sub modules {
    my ( $class, $bundles, $args ) = @_;
    like $args->{package}, qr{^dynamic::order};
    my @modules = (
        # If we put '<strict', this will still apply
        '-strict' => [qw( vars )],
        # Make sure things added with < are still added
        '<File::Spec::Functions' => [qw( catdir )],
        # Make sure things added with > are still added
        '>File::Spec::Functions' => [qw( splitdir )],
    );
    my %bundles = (
        Early => [
            '<strict',
            '<warnings',
        ],
        Strict => [
            'strict', 'warnings',
        ],
        # Lax will always be lax, no matter what
        Lax => [
            '>-strict',
            '>-warnings',
        ],
    );
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

1;
