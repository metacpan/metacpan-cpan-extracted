use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy ();

is File::Listing::Ftpcopy::_return42(), 42, 'return42 returns 42';

done_testing;
