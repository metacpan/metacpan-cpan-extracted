use warnings;
use strict;
use Test::More;

my $module = 'Linux::Info::Compilation';
require_ok($module);
can_ok( $module, qw(new search psfind pstop _compare) );
done_testing;
