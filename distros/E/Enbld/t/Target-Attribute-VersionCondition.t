#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'VersionCondition' );
is( $no->VersionCondition, 'latest', 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
throws_ok {
    $empty->add( 'VersionCondition', '' );
} qr/ABORT:Attribute 'VersionCondition' isn't defined/, 'empty parameter';

my $specified = Enbld::Target::AttributeCollector->new;
$specified->add( 'VersionForm', '\d' );
$specified->add( 'AllowedCondition', undef );
$specified->add( 'VersionCondition', '1' );
is( $specified->VersionCondition, '1', 'specified parameter' );

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'VersionForm',  '\d' );
$fixed->add( 'AllowedCondition', 'development' );
$fixed->add( 'VersionCondition', 'development' );
is( $fixed->VersionCondition, 'development', 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'VersionCondition', sub { return 'latest' } );
is( $coderef->VersionCondition, 'latest', 'coderef parameter' );

my $invalid = Enbld::Target::AttributeCollector->new;
$invalid->add( 'VersionForm','\d' );
$invalid->add( 'AllowedCondition', undef );
$invalid->add( 'VersionCondition', 'invalid' );
throws_ok {
    $invalid->VersionCondition;
} qr/ERROR:Invalid Version Condition:invalid/, 'invalid parameter';

my $notmatch = Enbld::Target::AttributeCollector->new;
$notmatch->add( 'VersionForm', '\d' );
$notmatch->add( 'AllowedCondition', 'development' );
$notmatch->add( 'VersionCondition', 'future' );
throws_ok {
    $notmatch->VersionCondition;
} qr/ERROR:Invalid Version Condition:future/, 'no match parameter';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'VersionCondition', sub { return } );
throws_ok {
    $undef->VersionCondition;
} qr/ABORT:Attribute 'VersionCondition' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'VersionCondition', sub { return [ 'latest' ] } );
throws_ok {
    $array->VersionCondition;
} qr/ABORT:Attribute 'VersionCondition' isn't scalar value/,
    'return array reference';

my $duplicate = Enbld::Target::AttributeCollector->new;
$duplicate->add( 'VersionCondition' );
throws_ok {
    $duplicate->add( 'VersionCondition' );
} qr/ABORT:VersionCondition is already added/, 'duplicate';

done_testing();
