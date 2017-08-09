use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy ();

ok 1;

diag '';
diag '';
diag '';
diag("_size_of_UV = " . File::Listing::Ftpcopy::_size_of_UV());
diag '';
diag '';

done_testing;
