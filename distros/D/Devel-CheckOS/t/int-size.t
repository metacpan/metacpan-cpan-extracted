use strict;
use warnings;

use Test::More;

use Devel::CheckOS qw(os_is);

if(~0 == 4294967295) {
    use_ok('Devel::AssertOS', 'HWCapabilities::Int32');
} else {
    use_ok('Devel::AssertOS', 'HWCapabilities::Int64');
}

done_testing;
