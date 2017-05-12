use strict;
use warnings;

use Test::Needs qw( Sub::Util );
use Test::More;

require Log::Contextual::WarnLogger::Fancy;
ok( Sub::Util::subname( \&Log::Contextual::WarnLogger::Fancy::is_info ),
    'is_info' );

done_testing;

