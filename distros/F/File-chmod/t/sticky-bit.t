use strict;
use warnings;
use Test::More;
use English '-no_match_vars';
use File::Temp ();
use File::chmod qw( chmod getmod );
$File::chmod::UMASK = 0;

plan skip_all => "Windows perms work differently" if $OSNAME eq 'MSWin32';
plan skip_all => "old File::Temp without newdir" if !File::Temp->can('newdir');

my $tmp = File::Temp->newdir;
my $fn  = $tmp->dirname;
note sprintf "original state of %s: %o\n", $fn, getmod( $fn );


ok chmod("+t", $fn ), "chmod +t $fn";
ok -k $fn, "$fn sticky"
	or diag sprintf "state of %s: %o\n", $fn, getmod( $fn );

ok chmod("-t", $fn ), "chmod -t $fn";
ok ! -k $fn, "$fn not sticky"
	or diag sprintf "state of %s: %o\n", $fn, getmod( $fn );


ok chmod("o+t", $fn ), "chmod o+t $fn";
ok -k $fn, "$fn sticky"
	or diag sprintf "state of %s: %o\n", $fn, getmod( $fn );

ok chmod("o-t", $fn ), "chmod o-t $fn";
ok ! -k $fn, "$fn not sticky"
	or diag sprintf "state of %s: %o\n", $fn, getmod( $fn );


ok chmod("u+t", $fn ), "chmod u+t $fn";
ok ! -k $fn, "$fn sticky"
	or diag sprintf "state of %s: %o\n", $fn, getmod( $fn );

done_testing;
