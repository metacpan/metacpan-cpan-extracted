#
#===============================================================================
#
#         FILE: 001_test_mega_cli.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 20.10.2018 20:47:03
#     REVISION: ---
#===============================================================================

use utf8;
use strict;
use warnings;
use lib 'lib';
use File::Spec;
use File::Basename;
use Data::Printer;

use Test::More 'no_plan';


my $MEGA_LOGIN          = $ENV{MEGA_LOGIN};
my $MEGA_PASSWORD       = $ENV{MEGA_PASSWORD};
my $UPLOAD_FILE         = 't/test_upload';

# Find mega in different path
use_ok('Mega::Cli');
my $mega = createMegaObj() or BAIL_OUT("Can't create Mega::Cli object");
isa_ok ($mega, 'Mega::Cli');

testCreateSeveralObject();

if (not defined $MEGA_LOGIN) {
    diag ("Not defined env: 'MEGA_LOGIN'");
    exit 0;
}
if (not defined $MEGA_PASSWORD) {
    diag ("Not defined env: 'MEGA_PASSWORD'");
    exit 0;
}

testMegaLogin();
testCreateDir($mega);

my $remote_file = testUploadFile($mega, $UPLOAD_FILE);
testDownloadFile($mega, $remote_file);

testShareFile($mega, $remote_file);


sub testCreateSeveralObject {
    
    eval {
        my $mega = createMegaObj();
    };
    like ($@, qr/Can't lock port/, 'Test create several mega objects');
}


sub createMegaObj {
    my $mega; 
    my @paths = split(/:/, $ENV{PATH});
    for my $path (@paths) {
        eval {
            $mega = Mega::Cli->new(
                -path           => $path,
            );
        };
        if ($@) {
            if ($@ =~ /^Command:/) {
                print $@;
            }
            else {
                die $@;
            }
        }
        else {
            print "Found mega in path: $path\n";
            last;
        }
    }
    
    return $mega;
}

sub testMegaLogin {
    eval {
        $mega->login(
                        -login      => $MEGA_LOGIN,
                        -password   => '',
                    );
    };
    ok ($@, "Fail Login to mega: $@");
    my $login_res = $mega->login(
                    -login      => $MEGA_LOGIN,
                    -password   => $MEGA_PASSWORD,
                );
    ok ($login_res, 'Login to mega');
}

sub testCreateDir {
    my $mega = shift;
    #Good dir
    my $dir = './testdir/';
    ok($mega->createDir(-dir   => $dir), "Create good dir test");

    #Bad dir
    $dir = './testdir';
    eval {
        $mega->createDir(-dir   => $dir);
    };
    like($@, qr/^Can't create folder/, "Create bad dir test");
}

sub testUploadFile {
    my ($mega, $source_file) = @_;
    my $dest_file = File::Spec->catfile('t', basename($source_file));

    my $res = $mega->uploadFile(
                        -local_file     => $source_file,
                        -remote_file    => $dest_file,
                        -create_dir     => 1,
                    );
    ok($res, "Upload file");
    return $dest_file;
}

sub testDownloadFile {
    my ($mega, $source_file) = @_;
    my $dest_file = File::Spec->catfile('t', 'test_download_file');
    unlink($dest_file);

    my $res = $mega->downloadFile(
                        -local_file     => $dest_file,
                        -remote_file    => $source_file,
                        -create_dir     => 1,
                    );
    ok($res, "Download file");
    ok(-e $dest_file, "Download file exists")
}

sub testShareFile {
    my ($mega, $remote_file) = @_;

    my $res;
    $res = $mega->shareResource(
                    -remote_resource    => $remote_file,
                );
    like($res, qr/^https.+/, "Test share resource: $remote_file ok. Share link: $res");

    #Test share not exists file
    eval {
        $mega->shareResource(
            -remote_resource        => 'not_exists_file',
        );
    };
    like($@, qr/Node not found/, "Test share not exists resource");

    #Unshare
    $res = $mega->unshareResource(
                    -remote_resource    => $remote_file,
    );
    ok ($res, "Test unshare resource");
}


