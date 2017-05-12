#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'AllowedCondition' );
is( $no->AllowedCondition, '', 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
$empty->add( 'AllowedCondition', '' );
is( $empty->AllowedCondition, '', 'empty parameter' );

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'AllowedCondition', 'development' );
is( $fixed->AllowedCondition, "development", 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'AllowedCondition', sub { return 'development' } );
is( $coderef->AllowedCondition, "development", 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'AllowedCondition', 'd e v e l o p m e n t' );
throws_ok {
    $space->AllowedCondition;
} qr/ABORT:Attribute 'AllowedCondition' includes space character/,
    'including space';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'AllowedCondition', sub { return } );
is( $undef->AllowedCondition, '', 'return undef' );

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'AllowedCondition', sub { return [ 'development' ] } );
throws_ok {
    $array->AllowedCondition;
} qr/ABORT:Attribute 'AllowedCondition' isn't scalar value/,
    'return array reference';

done_testing();
