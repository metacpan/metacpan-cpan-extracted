#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

my $index = 'http://www.example.com/download/';

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'DownloadSite', $index );
$no->add( 'IndexSite' );
is( $no->IndexSite, $index, 'no parameter' );

my $empty = Enbld::Target::AttributeCollector->new;
throws_ok {
    $empty->add( 'IndexSite', '' );
} qr/ABORT:Attribute 'IndexSite' isn't defined/, 'empty string';

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'IndexSite', $index );
is( $fixed->IndexSite, $index, 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'IndexSite', sub { return $index } );
is( $coderef->IndexSite, $index, 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'IndexSite', 'http://www.example.com  /download/' );
throws_ok {
    $space->IndexSite;
} qr/ABORT:Attribute 'IndexSite' includes space character/,
    'including space character';

my $invalid = Enbld::Target::AttributeCollector->new;
$invalid->add( 'IndexSite', 'ftp://www.example.com/download/' );
throws_ok {
    $invalid->IndexSite;
} qr/ABORT:Attribute 'IndexSite' isn't valid URL string/,
    'invalid URL string parameter';

my $noslash = Enbld::Target::AttributeCollector->new;
$noslash->add( 'IndexSite', 'http://www.example.com/download' );
is( $noslash->IndexSite, 'http://www.example.com/download',
        'end with no slash URL' );

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'IndexSite', sub { return } );
throws_ok {
    $undef->IndexSite;
} qr/ABORT:Attribute 'IndexSite' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'IndexSite', sub { return [ $index ] } );
throws_ok {
    $array->IndexSite;
} qr/ABORT:Attribute 'IndexSite' isn't scalar value/,
    'return array reference';

done_testing();
