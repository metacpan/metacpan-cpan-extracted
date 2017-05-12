#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'DarwinArgument' );
$no->add( 'DefaultArgument' );
$no->add( 'AdditionalArgument' );
is( $no->AdditionalArgument, '', 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
$empty->add( 'AdditionalArgument', '' );
is( $empty->AdditionalArgument, '', 'null parameter' );

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'AdditionalArgument', 'argument' );
is( $fixed->AdditionalArgument, 'argument', 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'AdditionalArgument', sub { return 'argument' } );
is( $coderef->AdditionalArgument, 'argument', 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'AdditionalArgument', 'a r g s' );
is( $space->AdditionalArgument, 'a r g s', 'including space' );

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'AdditionalArgument', sub { return } );
is( $undef->AdditionalArgument, '', 'return undef' );

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'AdditionalArgument', sub { return [ 'argument' ] } );
throws_ok {
    $array->AdditionalArgument;
} qr/ABORT:Attribute 'AdditionalArgument' isn't scalar value/,
    'return array reference';

done_testing();
