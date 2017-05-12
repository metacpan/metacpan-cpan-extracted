#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'Prefix' );
is( $no->Prefix, '--prefix=', 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
throws_ok {
    $empty->add( 'Prefix', '' );
} qr/ABORT:Attribute 'Prefix' isn't defined/, 'null parameter';

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'Prefix', '--PREFIX=' );
is( $fixed->Prefix, '--PREFIX=', 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'Prefix', sub { return '--PREFIX=' } );
is( $coderef->Prefix, '--PREFIX=', 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'Prefix', '--PREFIX =' );
throws_ok {
    $space->Prefix;
} qr/ABORT:Attribute 'Prefix' includes space character/, 'including space';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'Prefix', sub { return } );
throws_ok {
    $undef->Prefix;
} qr/ABORT:Attribute 'Prefix' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'Prefix', sub { return [ '--PREFIX=' ] } );
throws_ok {
    $array->Prefix;
} qr/ABORT:Attribute 'Prefix' isn't scalar value/, 'return array reference';

done_testing();
