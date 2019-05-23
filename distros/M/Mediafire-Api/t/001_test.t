#
#===============================================================================
#
#         FILE: 001_test.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 20.04.2019 21:40:06
#     REVISION: ---
#===============================================================================

use utf8;
use strict;
use warnings;
use File::Spec;
use File::Basename;

my $CURR_DIR;
BEGIN {
    $CURR_DIR = File::Spec->curdir;
}

use lib File::Spec->catdir($CURR_DIR, './lib');

use Test::More 'no_plan';                      # last test to print

use_ok('Mediafire::Api');

my $LOGIN               = $ENV{MEDIAFIRE_LOGIN};
my $PASSWORD            = $ENV{MEDIAFIRE_PASSWORD};
my $UPLOAD_FILE         = File::Spec->catfile($CURR_DIR, 't', 'test_upload3.f');
my $DEST_DOWNLOAD_FILE  = File::Spec->catfile($CURR_DIR, 't', 'downloaded_test_upload3.f');


SKIP: {
    if (not $LOGIN) {
        skip "Variable ENV{MEDIAFIRE_LOGIN} not set. Skip test";
    }
    if (not $PASSWORD) {
        skip "Variable ENV{MEDIAFIRE_PASSWORD} not set. Skip test";
    }

    # Login to mediafire
    my $mediafire = eval {
        testLogin($LOGIN, $PASSWORD);
    };
    if ($@) {
        skip $@;
    }

    my $mediafire_file = testUploadFile($mediafire, $UPLOAD_FILE);
    testFindFileByName($mediafire, basename($UPLOAD_FILE));
    testDownloadFile($mediafire, $mediafire_file, $DEST_DOWNLOAD_FILE);

};


sub testLogin {
    my ($login, $password) = @_;
    my $mediafire = Mediafire::Api->new();
    my $login_res = $mediafire->login(
        -login          => $login,
        -password       => $password,
    );
    ok($login_res, 'Test login success');

    return $mediafire;
}

sub testUploadFile {
    my ($mediafire, $file) = @_;
    my $upload_file = $mediafire->uploadFile(
        -file           => $file,
        -path           => 'myfiles',
    );

    my $doupload_key = $upload_file->key;
    ok($doupload_key, "Test upload file. DouploadKey: $doupload_key");
    return $upload_file;
}

sub testFindFileByName {
    my ($mediafire, $filename) = @_;
    my $res = $mediafire->findFileByName(
        -filename       => $filename,
    );

    ok (@$res, "Test findFileByName ok");
    my $doupload_key = $res->[0]->key;
    ok($doupload_key, "Find file doupload_key: $doupload_key");

}

sub testDownloadFile {
    my ($mediafire, $mediafire_file, $dest_file) = @_;

    unlink($dest_file);
    $mediafire->downloadFile(
        -mediafire_file     => $mediafire_file,
        -dest_file          => $dest_file,
    );

    ok (-f $dest_file, 'Test downloadFile()');
}


