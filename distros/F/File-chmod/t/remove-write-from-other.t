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

chmod( 0777, $fn );
note sprintf "state of %s: %o\n", $fn, getmod( $fn );

ok chmod("o-w", $fn ), "chmod -w $fn";
is sprintf( '%o', getmod( $fn ) ), 775, "$fn is 775";

done_testing;
