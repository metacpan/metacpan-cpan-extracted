#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;

# check module
use_ok( 'Getopt::Valid' );

#
# ANY
#

my $check = 0;
_get_input( 'invalid', 0, {
    anytrigger => sub { $check++ }
} );
ok(
    $check,
    'any-trigger called on invalid'
);

$check = 0;
_get_input( 'valid', 0, {
    anytrigger => sub { $check++ }
} );
ok(
    $check,
    'any-trigger called on valid'
);

#
# SET
#

$check = 0;
_get_input( 'valid', 0, undef, {
    settrigger => sub { $check++ }
} );
ok(
    ! $check,
    'set-trigger not called on unset'
);

$check = 0;
_get_input( 'valid', 1, undef, {
    settrigger => sub { $check++ }
} );
ok(
    $check,
    'set-trigger called on set'
);

#
# OK
#

$check = 0;
_get_input( 'invalid', 0, {
    oktrigger => sub { $check++ }
} );
ok(
    ! $check,
    'ok-trigger not called on invalid'
);

$check = 0;
_get_input( 'valid', 0, {
    oktrigger => sub { $check++ }
} );
ok(
    $check,
    'ok-trigger called on valid'
);

#
# FAIL
#

$check = 0;
_get_input( 'invalid', 0, {
    failtrigger => sub { $check++ }
} );
ok(
    $check,
    'fail-trigger called on invalid'
);

$check = 0;
_get_input( 'valid', 0, {
    failtrigger => sub { $check++ }
} );
ok(
    ! $check,
    'fail-trigger not called on valid'
);






sub _get_input {
    my ( $str, $bool, $str_args_ref, $bool_args_ref ) = @_;
    my %validator = (
        name       => 'Test',
        version    => '0.1.0',
        underscore => 1,
        struct     => [
            'str-arg=s' => {
                constraint => qr/^valid/,
                ( $str_args_ref ? %$str_args_ref : () )
            },
            'bool-arg' => {
                ( $bool_args_ref ? %$bool_args_ref : () )
            }
        ]
    );
    my $v = Getopt::Valid->new( \%validator );
    @ARGV = ( qw/ --str-arg /, $str );
    push @ARGV, '--bool-arg' if $bool;
    $v->collect_argv;
    $v->validate;
    return $v->valid_args();
}