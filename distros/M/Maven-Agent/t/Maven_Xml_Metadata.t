use strict;
use warnings;

use Test::More tests => 18;

BEGIN { use_ok('Maven::Xml::Metadata') }

use Data::Dumper;
use File::Basename;
use File::Spec;
use Maven::Maven;

my $test_dir = dirname( File::Spec->rel2abs($0) );
my $maven    = Maven::Maven->new(
    M2_HOME     => File::Spec->catdir( $test_dir, 'M2_HOME' ),
    'user.home' => File::Spec->catdir( $test_dir, 'HOME' )
);
my $metadata;

$metadata =
    Maven::Xml::Metadata->new(
    file => $maven->dot_m2( 'repository', 'com', 'pastdev', 'foo', 'maven-metadata-local.xml' ) );
is( $metadata->get_groupId(),    'com.pastdev', 'groupId' );
is( $metadata->get_artifactId(), 'foo',         'artifactId' );
is_deeply(
    $metadata->get_versioning()->get_versions(),
    [ '1.0.0', '1.0.1-SNAPSHOT', '1.0.1' ],
    'versioning.versions'
);
is( $metadata->get_versioning()->get_lastUpdated(), '20140222160453', 'versioning.lastUpdated' );
is( $metadata->get_versioning()->get_latest(),      '1.0.1',          'versioning.latest' );
is( $metadata->get_versioning()->get_release(),     '1.0.1',          'versioning.release' );

$metadata = Maven::Xml::Metadata->new(
    file => $maven->dot_m2(
        'repository', 'com', 'pastdev', 'foo', '1.0.1-SNAPSHOT', 'maven-metadata-local.xml'
    )
);
is( $metadata->get_groupId(),    'com.pastdev',    'snapshot groupId' );
is( $metadata->get_artifactId(), 'foo',            'snapshot artifactId' );
is( $metadata->get_version(),    '1.0.1-SNAPSHOT', 'snapshot version' );
is( $metadata->get_versioning()->get_lastUpdated(),
    '20140220201509', 'snapshot versioning.lastUpdated' );
is( $metadata->get_versioning()->get_snapshot()->get_localCopy(),
    'true', 'snapshot versioning.snapshot.localCopy' );
is( $metadata->get_versioning()->get_snapshotVersions()->[0]->get_extension(),
    'jar', 'snapshot versioning.snapshotVersions[0].extension' );
is( $metadata->get_versioning()->get_snapshotVersions()->[0]->get_value(),
    '1.0.1-SNAPSHOT', 'snapshot versioning.snapshotVersions[0].value' );
is( $metadata->get_versioning()->get_snapshotVersions()->[0]->get_updated(),
    '20140220201509', 'snapshot versioning.snapshotVersions[0].updated' );
is( $metadata->get_versioning()->get_snapshotVersions()->[1]->get_extension(),
    'pom', 'snapshot versioning.snapshotVersions[1].extension' );
is( $metadata->get_versioning()->get_snapshotVersions()->[1]->get_value(),
    '1.0.1-SNAPSHOT', 'snapshot versioning.snapshotVersions[1].value' );
is( $metadata->get_versioning()->get_snapshotVersions()->[1]->get_updated(),
    '20140220201509', 'snapshot versioning.snapshotVersions[1].updated' );
