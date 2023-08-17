#perl
use strict;
use 5.010;
use Test::More;
use File::Temp 'tempdir';

BEGIN {
    if( $^O !~ /cygwin/ ) {
        plan skip_all => "This test only works on Cygwin";
        exit;
    };
};
use Win32::API;
use Win32API::File 'CreateFile', 'CloseHandle', ':FILE_FLAG_', 'FILE_LIST_DIRECTORY', 'OPEN_EXISTING', 'FILE_SHARE_WRITE', 'FILE_SHARE_READ', 'GENERIC_READ';
plan tests => 1;
my $is_cygwin = 1;

use Filesys::Notify::Win32::ReadDirectoryChanges;
my $orgpath = tempdir();

# cd /cygdrive/c/Users/Corion/Projekte/Filesys-Notify-Win32-ReadDirectoryChanges/ ; perl -Ilib t/02-readdirectorychanges-cygwin-crash.t

if( fork()) {
    # main
    
    my $winpath = $is_cygwin ? Cygwin::posix_to_win_path($orgpath) : $orgpath;
    my $subtree = 1;
    $winpath .= "\\" if $winpath !~ /\\\z/;
    my $hPath = CreateFile( $winpath, FILE_LIST_DIRECTORY()|GENERIC_READ(), FILE_SHARE_READ() | FILE_SHARE_WRITE(), [], OPEN_EXISTING(), FILE_FLAG_BACKUP_SEMANTICS(), [] )
        or die $^E;
    my $res = Filesys::Notify::Win32::ReadDirectoryChanges::_ReadDirectoryChangesW($hPath, $subtree, 0x1b);
    for my $i (Filesys::Notify::Win32::ReadDirectoryChanges::_unpack_file_notify_information($res)) {
        $i->{path} = $winpath . $i->{path};
        if( $is_cygwin ) {
            my $p = $i->{path};
            note "win32 : $p";
            $i->{path} = Cygwin::win_to_posix_path( $p );
            like $i->{path}, qr!^[\w/]+$!;
        };
    };

} else {
    sleep 1;
    open my $fh, '>',  "$orgpath/foo";
    open my $fh2, '>', "$orgpath/bar";
    diag "Child quit";
}
