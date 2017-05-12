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

ok chmod("+r", $fn ), "chmod +r $fn";
is sprintf( '%o', getmod( $fn ) ), 444, "$fn is 444";

ok chmod("-r", $fn ), "chmod -r $fn";
is sprintf( '%o', getmod( $fn ) ), 000, "$fn is 000";

ok chmod("u+r", $fn ), "chmod u+r $fn";
is sprintf( '%o', getmod( $fn ) ), 400, "$fn is 400";

ok chmod("u-r", $fn ), "chmod u-r $fn";
is sprintf( '%o', getmod( $fn ) ), 000, "$fn is 000";

ok chmod("ug+r", $fn ), "chmod ug+r $fn";
is sprintf( '%o', getmod( $fn ) ), 440, "$fn is 440";

ok chmod("ug-r", $fn ), "chmod ug+r $fn";
is sprintf( '%o', getmod( $fn ) ), 000, "$fn is 000";

ok chmod("ugo+r", $fn ), "chmod ugo+r $fn";
is sprintf( '%o', getmod( $fn ) ), 444, "$fn is 444";

ok chmod("ugo-r", $fn ), "chmod ugo+r $fn";
is sprintf( '%o', getmod( $fn ) ), 000, "$fn is 000";

done_testing;
