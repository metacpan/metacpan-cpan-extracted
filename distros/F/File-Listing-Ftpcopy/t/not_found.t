use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy qw( ftpparse );

is ftpparse(''), undef, 'not found';

done_testing;
