use strict;
use warnings;

use Test::Needs qw( Sub::Name Sub::Identify );
use Test::More;

BEGIN {
    if ( $INC{'Sub/Util.pm'} ) {
        plan skip_all => "Sub::Util needes not to be preloaded for this test";
        exit 0;
    }
}

require Log::Contextual::WarnLogger::Fancy;
ok( Sub::Identify::sub_name( \&Log::Contextual::WarnLogger::Fancy::is_info ),
    'is_info' );

done_testing;

