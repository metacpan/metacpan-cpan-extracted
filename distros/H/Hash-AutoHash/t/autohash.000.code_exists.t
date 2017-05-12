use lib qw(t);
use strict;
use Test::More tests => 3;
# use Test::More;
# make sure all the necesary modules exist
BEGIN {
  use_ok('Tie::Hash::MultiValue');
  use_ok('Hash::AutoHash');
  use_ok('autohashUtil');
}
diag( "Testing Hash::AutoHash $Hash::AutoHash::VERSION, Perl $], $^X" );
done_testing();
