use lib qw(t);
use strict;
use Test::More;
use Test::Deep;
# make sure all the necesary modules exist
BEGIN {
  use_ok('Hash::AutoHash');
  use_ok('Hash::AutoHash::MultiValued');
}
diag( "Testing Hash::AutoHash::MultiValued $Hash::AutoHash::MultiValued::VERSION, Perl $], $^X" );
done_testing();
