#!perl

use strict;
use warnings;

use File::Spec;
use File::Copy;
use File::Temp;
use FindBin;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $empty = Enbld::Target::AttributeCollector->new;
$empty->add( 'SortedVersionList' );
throws_ok {
    $empty->add( 'Version', '' );
} qr/ABORT:Attribute 'Version' isn't defined/, 'empty parameter';

my $fixed = Enbld::Target::AttributeCollector->new;
$fixed->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$fixed->add( 'Version', '1.13.1' );
is( $fixed->Version, '1.13.1', 'fixed parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$coderef->add( 'Version', sub { return '1.13.1' } );
is( $coderef->Version, '1.13.1', 'coderef parameter' );

my $invalid = Enbld::Target::AttributeCollector->new;
$invalid->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$invalid->add( 'VersionCondition', undef );
$invalid->add( 'Version', '1.13.100' );
throws_ok {
    $invalid->Version;
} qr/NOT valid version string/, 'invalid parameter';

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$space->add( 'Version', '1. 3.1' );
throws_ok {
    $space->Version;
} qr/ABORT:Attribute 'Version' includes space character/, 'including space';

my $undef = Enbld::Target::AttributeCollector->new;
$undef->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$undef->add( 'Version', sub { return } );
throws_ok {
    $undef->Version;
} qr/ABORT:Attribute 'Version' is empty string/, 'return undef';

my $array = Enbld::Target::AttributeCollector->new;
$array->add( 'VersionForm', '\d{1,2}\.\d{1,2}(\.\d{1,2})?' );
$array->add( 'Version', sub { return [ '1.13.1' ] } );
throws_ok {
    $array->Version;
} qr/ABORT:Attribute 'Version' isn't scalar value/, 'return array reference';

subtest 'invalid Version Condition' => sub {
    set_http_hook();

    my $invalid_condition = Enbld::Target::AttributeCollector->new;
    $invalid_condition->add( 'IndexSite', 'http://www.example.com' );
    $invalid_condition->add( 'VersionForm', '\d\.\d' );
    $invalid_condition->add( 'AllowedCondition' );
    $invalid_condition->add( 'ArchiveName', 'TestApp' );
    $invalid_condition->add( 'Extension', 'tar.gz' );
    $invalid_condition->add( 'IndexParserForm' );
    $invalid_condition->add( 'VersionCondition', '1.2' );
    $invalid_condition->add( 'VersionList' );
    $invalid_condition->add( 'SortedVersionList' );
    $invalid_condition->add( 'Version' );

    throws_ok {
        $invalid_condition->Version;
    } qr/ERROR:Invalid Version Condition:1/, 'invalid condition';

    done_testing();
};

done_testing();

sub set_http_hook {

    my $html = do { local $/; <DATA> };

    require Enbld::HTTP;
    Enbld::HTTP->register_get_hook( sub { return $html } );
}

__DATA__
<html>
<body>
<a href="TestApp-1.0.tar.gz">TestApp-1.0.tar.gz</a>
<a href="TestApp-1.1.tar.gz">TestApp-1.1.tar.gz</a>
</body>
</html>


