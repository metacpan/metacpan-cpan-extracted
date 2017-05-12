use Test::More;

use Safe;

BEGIN { Safe->new }

use JSONY;

my $data = JSONY->new->load( "[ 1 2 3 4 ]" );

pass 'GitHub issue #2 fixed';

done_testing;
