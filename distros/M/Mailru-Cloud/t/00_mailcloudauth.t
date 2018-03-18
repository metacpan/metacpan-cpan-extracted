#
#===============================================================================
#
#         FILE: 00_mailcloudauth.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 05.11.2017 19:11:34
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin '$Bin';
use File::Basename;
use lib "$Bin/../lib";

use Test::More 'no_plan';

BEGIN {
    use_ok("Mailru::Cloud::Auth");
    use_ok("Mailru::Cloud");
}

my $login                   = 'petr.davydov.80@bk.ru';
my $password                = '@F3bHlkIS7Ou';
my $uploadFile              = "$Bin/test_upload.f";
my $download_file           = "$Bin/test_download";
my $create_folder           = "/Test/temp" . int(rand(10000));
unlink($download_file);

can_ok("Mailru::Cloud", 'new');

my $cloud = Mailru::Cloud->new;
isa_ok($cloud, "Mailru::Cloud");

ok ($cloud->login(-login => $login, -password => $password), "Test login");
ok ($cloud->__isLogin(), "Test login method '__isLogin'");



test_info();
test_createFolder();
my @uploaded = test_uploadFile();
test_listFiles();
test_shareResource();
test_downloadFile();

test_deleteResource($_) for @uploaded;
test_deleteResource($create_folder);
test_deleteResource('/dfhdffereerer');

test_emptyTrash();

sub test_info {
    my $info = $cloud->info;

    like($info->{file_size_limit}, qr /./, "Test info file_size_limit");
    like($info->{used_space}, qr /^\d+$/, "Test info used_space");
    like($info->{total_space}, qr /^\d+$/, "Test info total_space");

    print "File size limit: $info->{file_size_limit}\n";
    print "Used space: $info->{used_space}. Total space: $info->{total_space}\n";

}

sub test_uploadFile {
    my $basename = basename($uploadFile);
    my $new_fname = $cloud->uploadFile(-file  => $uploadFile, -path => '/');
    is($new_fname, '/' . $basename, "Test upload file to mail cloud");


    my $new_fname2 = $cloud->uploadFile(-file  => $uploadFile, -path => '/', -rename => 1);
    my ($part_fname) = $basename =~ /^(.+)\./;
    like($new_fname2, qr/$part_fname \(\d+\)/, "Test upload file with rename");

    is ($cloud->get_last_uploaded_file_hash(), '8F6984310039D967127C01C8E80BDA36A31B9E19', "Test compare file hash");
    return ($new_fname, $new_fname2);
}

sub test_downloadFile {
    ok ($cloud->downloadFile(-file => $download_file, -cloud_file => basename($uploadFile)), "Test download file");
    #Проверим ошибку при скачивании
    eval {
        $cloud->downloadFile(-file => $download_file, -cloud_file => 'notakoifile');
    };
    like ($@, qr/^Cant download file/, "Test error download file");

    ok(unlink($download_file), "Test delete downloaded file");

}

sub test_createFolder {
    ok($cloud->createFolder(-path => $create_folder), "Test createFolder (create folder $create_folder)");
}

sub test_deleteResource {
    my $resource = shift;
    ok ($cloud->deleteResource(-path => $resource), "Test deleteResource $resource");
}

sub test_emptyTrash {
    ok ($cloud->emptyTrash(), "Test empty trash");
}

sub test_listFiles {
    my $list = $cloud->listFiles();
    my $found = grep {$_->{name} eq basename($uploadFile)} @$list;
    ok ($found, 'Test list files folder /');
    
    #Test not exists folder
    eval {$cloud->listFiles(-path => 'not real path')};
    like ($@, qr/Folder.+not exists/, "Test on listFiles fake folder");

    $list = $cloud->listFiles(-path => '/Test');
    $found = grep {$_->{name} eq basename($create_folder)} @$list;
    ok ($found, 'Test list files folder /Test');

}

sub test_shareResource {
    my $link = $cloud->shareResource(-path => '/Test');
    like ($link, qr/.+/, "Test shareResource");
}
