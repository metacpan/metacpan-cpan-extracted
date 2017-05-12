package
    MyDynamicSubrefs;

use strict;
use warnings;
use Test::More;
use base 'MyDynamic';

sub modules {
    my ( $class, $bundles, $args ) = @_;
    like $args->{package}, qr{^dynamic::subref};
    my @modules = (
        '-strict' => [ 'vars' ],
        sub { return -warnings => [qw( uninitialized )] },
    );
    my %bundles = (
        'Spec' => [
            'File::Spec::Functions' => [qw( catfile )],
        ],
        Lax => [
            '-strict',
            sub {
                my ( $bundles, $args ) = @_;
                like $args->{package}, qr{^dynamic::subref};
                return '-warnings';
            },
        ],
        Inherit => [
            sub {
                my ( $bundles, $args ) = @_;
                like $args->{package}, qr{^dynamic::subref};
                no strict 'refs';
                my $class = $args->{package};
                push @{ "${class}::ISA" }, 'inherited';
                return;
            },
        ],
    );
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

package
    inherited; # dummy package to inherit from

1;
