#!perl
use 5.006;
use strict;
use warnings;

use File::Tempdir;
use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $tempdir = File::Tempdir->new;
my $tdir = $tempdir->name;
my $bdir = 't/base';

my $unix = "$bdir/unix.txt";
my $win = "$bdir/win.txt";

my $win_cp = "$tdir/win.bak";
my $unix_cp = "$tdir/unix.bak";

{
    my $rw = File::Edit::Portable->new;

    my $win_fh = $rw->read($win);
    my $temp_wfh = $rw->tempfile;

    while (<$win_fh>){
        s/asd/xxx/g;
        print $temp_wfh $_;
    }

    $rw->write(copy => $win_cp, contents => $temp_wfh);
    
    my $recsep = $rw->recsep($win_cp, 'hex');
    is ($recsep, '\0d\0a', "write() a tempfile() has proper line endings for win32");

    my $fh = $rw->read($win_cp);

    {
        local $/;
        my $matches = () = <$fh> =~ /xxx/g;
        is ($matches, 4, "write() with tempfile() handle does the right thing for win32");
    }
}
{
    my $rw = File::Edit::Portable->new;

    my $unix_fh = $rw->read($unix);
    my $temp_wfh = $rw->tempfile;

    while (<$unix_fh>){
        s/asd/xxx/g;
        print $temp_wfh $_;
    }

    $rw->write(copy => $unix_cp, contents => $temp_wfh);
    
    my $recsep = $rw->recsep($unix_cp, 'hex');
    is ($recsep, '\0a', "write() a tempfile() has proper line endings with nix");

    my $fh = $rw->read($unix_cp);

    {
        local $/;
        my $matches = () = <$fh> =~ /xxx/g;
        is ($matches, 7, "write() with tempfile() handle does the right thing with nix");
    }
}

done_testing();
