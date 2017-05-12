#!perl
use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $rw = File::Edit::Portable->new;
{
    my $string = $rw->platform_recsep;
    my $converted = unpack "H*", $string;
    $converted =~ s/0/\\0/g;
    my $hex = $rw->platform_recsep('hex');
    is ($converted, $hex, "recsep with hex matches hexed string version");

    my @sys = qw(win nix mac unknown);

    my $type = $rw->platform_recsep('type');
    is ((grep {/^$type$/} @sys), 1, "platform recsep type is ok" );
}

done_testing();
