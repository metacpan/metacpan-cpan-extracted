use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING} or plan skip_all => 'Kwalitee test only for developers';
}

use English qw( -no_match_vars );

eval { require Test::Kwalitee; };

$EVAL_ERROR and plan skip_all => 'Test::Kwalitee not installed';

# Since we now use a custom Moose exporter this metric is no longer valid
Test::Kwalitee->import( tests => [ qw(-use_strict) ] );

unlink q(Debian_CPANTS.txt);

# Local Variables:
# mode: perl
# tab-width: 3
# End:
