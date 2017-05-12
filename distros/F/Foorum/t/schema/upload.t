#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 12;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache base_path/;
use Foorum::TestUtils qw/rollback_db/;
use File::Path;
use File::Copy ();
use File::Remove qw/remove/;

my $schema    = schema();
my $cache     = cache();
my $base_path = base_path();

my $upload_res = $schema->resultset('Upload');
my $upload_file
    = File::Spec->catfile( $base_path, 't', 'schema', 'upload', 'test.txt' );
my $upload_id   = 1;
my $directory_1 = int( $upload_id / 3200 / 3200 );
my $directory_2 = int( $upload_id / 3200 );
my $upload_dir
    = File::Spec->catdir( $base_path, 'root', 'upload', $directory_1,
    $directory_2 );
my @created;

unless ( -e $upload_dir ) {
    @created = mkpath( [$upload_dir], 0, 0777 );    ## no critic
    ## no critic (ProhibitLeadingZeros)
}
my $dest_file = File::Spec->catfile( $upload_dir, 'test.txt' );

# create data, TODO. add_file need use $upload based on Catalyst::Request::Upload
sub create_data {
    my ( $upload_res, $upload_id, $upload_file, $dest_file ) = @_;

    $upload_res->search( { upload_id => $upload_id } )->delete;
    my $upload_rs = $upload_res->create(
        {   upload_id => $upload_id,
            user_id   => 1,
            forum_id  => 2,
            filename  => 'test.txt',
            filesize  => 2,
            filetype  => 'txt',
        }
    );

    File::Copy::copy( $upload_file, $dest_file );

    return $upload_id;
}

create_data( $upload_res, $upload_id, $upload_file, $dest_file );

# test ->get
my $upload = $upload_res->get($upload_id);
isnt( $upload, undef, '->get OK' );
is( $upload->{upload_id}, $upload_id, 'get upload_id OK' );
is( $upload->{user_id},   1,          'get user_id OK' );
is( $upload->{forum_id},  2,          'get forum_id OK' );
is( $upload->{filename},  'test.txt', 'get filename OK' );
is( $upload->{filetype},  'txt',      'get filetype OK' );
is( $upload->{filesize},  2,          'get filesize OK' );
ok( -e $dest_file, 'file exist' );

# test remove_file_by_upload_id
$upload_res->remove_file_by_upload_id( $upload->{upload_id} );
$upload = $upload_res->get( $upload->{upload_id} );
is( $upload, undef, 'after remove_file_by_upload_id get undef' );
ok( not( -e $dest_file ), 'after remove_file_by_upload_id file deleted' );

# test remove_by_upload
create_data( $upload_res, $upload_id, $upload_file, $dest_file );
$upload = $upload_res->get($upload_id);
$upload_res->remove_by_upload($upload);
$upload = $upload_res->get($upload_id);
is( $upload, undef, 'after remove_by_upload get undef' );
ok( not( -e $dest_file ), 'after remove_by_upload file deleted' );

END {

    # Keep Database the same from original
    rollback_db();

    if ( scalar @created ) {
        remove \1, @created;
    }
}

1;
