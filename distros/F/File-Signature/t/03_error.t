# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use File::Signature;

#########################

my $err = File::Signature->new('./nonexistent');

ok( $err->error, "returns true");
like( $err->error, qr/ERROR: stat failure on \S+/, "scalar context");
my @list = $err->error; 
is( scalar @list, 3, "list context" );

