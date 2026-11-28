#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my $json = JSON->new->allow_nonref(1);
my @multiples =
(
    ['-4', '2', 1],
    ['-19.99', '0.01', 1],
    ['0', '0.0000000000001', 1],
    ['-0.0', '3', 1],
    ['0.3', '0.1', 1],
    ['0.31', '0.1', 0],
    ['1e-10', '1', 0],
    ['1.00000000001', '1', 0],
    ['-1.00000000001', '1', 0],
    ['1.5e-12', '1e-12', 0],
    ['2e-12', '1e-12', 1],
    ['1', '0.2', 1],
    ['1', '0.3', 0],
    ['1e100', '0.125', 1],
    ['1e100', '3', 0],
    ['1e-100', '1e-101', 1],
    ['1e-101', '1e-100', 0],
    ['1604938257', '123456789', 1],
    ['1604938258', '123456789', 0],
    ['246913578024690', '123456789012345', 1],
    ['246913578024691', '123456789012345', 0],
    ['-246913578024690', '123456789012345', 1],
    ['1e40', '1073741824', 1],
    ['1e20', '1073741824', 0],
    ['1e40', '12500000001', 0],
    ['1', '0', 0],
    ['1', '-1', 0],
    ['"0.31"', '0.1', 1],
);
my @equalities =
(
    ['1', '1.0', 1],
    ['-0.0', '0', 1],
    ['0.0001', '1e-4', 1],
    ['100000000000000', '1e14', 1],
    ['123456789012345', '123456789012346', 0],
    ['1.00000000001', '1', 0],
    ['-1', '1', 0],
    ['"1"', '1', 0],
    ['true', '1', 0],
    ['null', '0', 0],
);
for my $compile ( 0, 1 )
{
    for my $normalise ( 0, 1 )
    {
        subtest "compile=$compile, normalize_instance=$normalise" => sub
        {
            for my $case ( @multiples )
            {
                my( $value, $divisor, $expected ) = @$case;
                my $js = JSON::Schema::Validate->new( { multipleOf => $json->decode( $divisor ) }, compile => $compile, normalize_instance => $normalise );
                is( $js->validate( $json->decode( $value ) ) ? 1 : 0, $expected, "$value with multipleOf $divisor" );
            }
            for my $case ( @equalities )
            {
                my( $value, $constant, $expected ) = @$case;
                for my $schema ( { const => $json->decode( $constant ) }, { enum => [$json->decode( $constant )] } )
                {
                    my $js = JSON::Schema::Validate->new( $schema, compile => $compile, normalize_instance => $normalise );
                    my( $keyword ) = keys( %$schema );
                    is( $js->validate( $json->decode( $value ) ) ? 1 : 0, $expected, "$value with $keyword $constant" );
                }
            }
        };
    }
}

done_testing();

__END__
