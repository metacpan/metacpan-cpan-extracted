use lib qw(t);
use strict;
use Test::More tests => 3;
# make sure all the necesary modules exist
BEGIN {
  use_ok('Hash::AutoHash');
  use_ok('Hash::AutoHash::Args');
  use_ok('Hash::AutoHash::Args::V0');
}
diag( "Testing Hash::AutoHash::Args $Hash::AutoHash::Args::VERSION, Perl $], $^X" );
done_testing();
