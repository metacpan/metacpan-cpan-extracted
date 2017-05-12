#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'ArchiveName', 'archive' );
$no->add( 'DistName' );
is( $no->DistName, 'archive', 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
throws_ok {
    $empty->add( 'DistName', '' );
} qr/ABORT:Attribute 'DistName' isn't defined/, 'empty parameter';

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'DistName', 'archive' );
is( $fixed->DistName, 'archive', 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'DistName', sub { return 'archive' } );
is( $coderef->DistName, 'archive', 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'DistName', 'a r c h i v e' );
throws_ok {
    $space->DistName;
} qr/ABORT:Attribute 'DistName' includes space character/,
    'including space character';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'DistName', sub { return } );
throws_ok {
    $undef->DistName;
} qr/ABORT:Attribute 'DistName' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'DistName', sub { return [ 'archive' ] } );
throws_ok {
    $array->DistName;
} qr/ABORT:Attribute 'DistName' isn't scalar value/, 'return array reference';

done_testing();
