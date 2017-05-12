use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;

note "Testing main class";
test_class_methods('Hash::AutoHash::Args','autoargs_set');
note "Testing V0 class";
test_class_methods('Hash::AutoHash::Args::V0','autoargs_set');

done_testing();
