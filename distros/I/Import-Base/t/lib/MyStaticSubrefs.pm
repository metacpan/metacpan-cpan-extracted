package
    MyStaticSubrefs;

use strict;
use warnings;
use Test::More;
use base 'MyStatic';

our @IMPORT_MODULES = (
    '-strict' => [ 'vars' ],
    sub { return -warnings => [qw( uninitialized )] },
);

our %IMPORT_BUNDLES = (
    'Spec' => [
        'File::Spec::Functions' => [qw( catfile )],
    ],
    Lax => [
        '-strict',
        sub {
            my ( $bundles, $args ) = @_;
            like $args->{package}, qr{^static::subref};
            return '-warnings';
        },
    ],
    Inherit => [
        sub {
            my ( $bundles, $args ) = @_;
            like $args->{package}, qr{^static::subref};
            no strict 'refs';
            my $class = $args->{package};
            push @{ "${class}::ISA" }, 'inherited';
            return;
        },
    ],
);

package
    inherited; # dummy package to inherit from

1;
