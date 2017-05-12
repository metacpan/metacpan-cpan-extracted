use strict;
use warnings;
use Test::More;
use English '-no_match_vars';
use File::Temp ();
use File::chmod qw( chmod getmod );
$File::chmod::UMASK = 0;

plan skip_all => "Windows perms work differently" if $OSNAME eq 'MSWin32';

my $tmp = File::Temp->new;
my $fn  = $tmp->filename;

note sprintf "original state of %s: %o\n", $fn, getmod( $fn );

ok chmod("+x", $fn ), "chmod +x $fn";
ok -x $fn, "$fn executable";

ok chmod("-x", $fn ), "chmod -x $fn";
ok ! -x $fn, "$fn not executable";

done_testing;
