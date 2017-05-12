#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;

# check module
use_ok( 'Getopt::Valid' );

my $check = 0;
my $input_ref = _get_input( undef, 'some-value', \$check );
ok(
    $check,
    'Inflate without validation'
);

$check = 0;
$input_ref = _get_input( qr/^valid/, 'invalid-value', \$check );
ok(
    ! defined $input_ref->{ inflated_arg } && ! $check,
    'Invalid input does not inflate'
);

$check = 0;
$input_ref = _get_input( qr/^valid/, 'valid-value', \$check );
ok(
    defined $input_ref->{ inflated_arg }
    && $check
    && $input_ref->{ inflated_arg } eq 'VALID-VALUE',
    'Valid input does inflate'
);





sub _get_input {
    my ( $constraint, $value, $ref ) = @_;
    my %validator = (
        name       => 'Test',
        version    => '0.1.0',
        underscore => 1,
        struct     => [
            'inflated-arg=s' => {
                ( $constraint ? ( constraint => $constraint ) : () ),
                postfilter => sub {
                    my ( $v ) = @_;
                    $$ref ++;
                    return uc( $v );
                }
            }
        ]
    );
    my $v = Getopt::Valid->new( \%validator );
    @ARGV = ( qw/ --inflated-arg /, $value );;
    $v->collect_argv;
    $v->validate;
    return $v->valid_args();
}