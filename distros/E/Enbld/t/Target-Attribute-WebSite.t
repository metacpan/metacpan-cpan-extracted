#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;
my $testsite = 'http://www.example.com/';

my $no = Enbld::Target::AttributeCollector->new;
throws_ok {
    $no->add( 'WebSite' );
} qr/ABORT:Attribute 'WebSite' isn't defined/, 'no parameter';

my $empty = Enbld::Target::AttributeCollector->new;
throws_ok {
    $empty->add( 'WebSite', '' );
} qr/ABORT:Attribute 'WebSite' isn't defined/, 'empty string parameter';

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'WebSite', $testsite );
is( $fixed->WebSite, $testsite, 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'WebSite', sub { return $testsite } );
is( $coderef->WebSite, $testsite, 'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'WebSite', 'http://www. example. com/' );
throws_ok {
    $space->WebSite;
} qr/ABORT:Attribute 'WebSite' includes space character/,
    'including space character';

my $invalid = Enbld::Target::AttributeCollector->new;
$invalid->add( 'WebSite', 'ftp://www.example.com/' );
throws_ok {
    $invalid->WebSite;
} qr/ABORT:Attribute 'WebSite' isn't valid URL string/,
    'invalid URL string parameter';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'WebSite', sub { return } );
throws_ok {
    $undef->WebSite;
} qr/ABORT:Attribute 'WebSite' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'WebSite', sub { return [ $testsite ] } );
throws_ok {
    $array->WebSite;
} qr/ABORT:Attribute 'WebSite' isn't scalar value/, 'return array reference';

done_testing();
