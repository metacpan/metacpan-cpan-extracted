#!perl
use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $bdir = 't/base';
my $unix = "$bdir/unix.txt";
my $win = "$bdir/win.txt";

my $rw = File::Edit::Portable->new;

{
    my $x = $rw->recsep($win, 'hex');
    my $y = $rw->recsep($win, 'type');
    is ($x, '\0d\0a', "hex recsep is correct for win");
    is ($y, 'win', "type recsep is correct for win");
}
{
    my $x = $rw->recsep($unix, 'hex');
    my $y = $rw->recsep($unix, 'type');
    is ($x, '\0a', "hex recsep is correct for unix");
    is ($y, 'nix', "type recsep is correct for unix");
}
{
    my $x = $rw->recsep( 'xxx', 'hex' );
    my $p = $rw->platform_recsep('hex');
    is ( $x, $p, "hex recsep is set to platform for bad file" );
}
{
    my $x = $rw->recsep( 'xxx', 'type' );
    my $p = $rw->platform_recsep('type');
    is ( $x, $p, "type recsep is set to platform for bad file" );
}
{
    my $x = $rw->recsep('xxx');
    my $p = $rw->platform_recsep;
    is ( $x, $p, "string recsep is set to platform for bad file" );
}
{
    my @os = qw(win mac nix unknown unknown);

    for ("\r\n", "\r", "\n"){
        my $fname = $rw->_temp_filename;

        $rw->write(file => $fname, contents => [qw(abc)], recsep => $_);

        my $os = $rw->recsep($fname, 'type');
        my $hex = $rw->recsep($fname, 'hex');

        my @m = grep /^$os$/, @os;
        my $os_name = shift @os;

        is ($m[0], $os_name, "$m[0] recsep matches type");

        is unlink($fname), 1, "temp file unlinked ok";
    }
}

done_testing();
