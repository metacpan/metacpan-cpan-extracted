use strict;
use warnings;

use Test::More;

use Capture::Tiny qw( capture );
use FindBin qw( $Bin );

chdir "$Bin/../.."
    or die "Cannot chdir to $Bin/../..: $!";

my ( $out, $err ) = capture { system(qw( precious lint -a )) };
is( $? >> 8, 0,   'precious lint -a exited with 0' );
is( $err,    q{}, 'no output to stderr' );

done_testing();
