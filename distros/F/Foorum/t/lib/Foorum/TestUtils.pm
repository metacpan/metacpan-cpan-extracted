package Foorum::TestUtils;

use strict;
use warnings;
use YAML::XS qw/LoadFile/;    # config
use Foorum::Schema;           # schema
use Cache::FileCache;         # cache
use File::Copy ();
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/
    rollback_db
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);

sub rollback_db {

    # Keep Database the same from original
    File::Copy::copy(
        File::Spec->catfile( $path, 'foorum.backup.db' ),
        File::Spec->catfile( $path, 'foorum.db' )
    );
    File::Copy::copy(
        File::Spec->catfile( $path, 'theschwartz.backup.db' ),
        File::Spec->catfile( $path, 'theschwartz.db' )
    );
}

1;
