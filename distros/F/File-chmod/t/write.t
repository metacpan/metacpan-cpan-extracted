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

chmod( 0000, $fn );
note sprintf "state of %s: %o\n", $fn, getmod( $fn );

ok chmod("+w", $fn ), "chmod +w $fn";
is sprintf( '%o', getmod( $fn ) ), 222, "$fn is 222";

ok chmod("-w", $fn ), "chmod -w $fn";
is sprintf( '%o', getmod( $fn ) ), 000, "$fn is 000";

done_testing;
