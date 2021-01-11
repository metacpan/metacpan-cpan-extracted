use Test2::V0;
use Finance::Google::Portfolio;

my $obj;
ok( $obj = Finance::Google::Portfolio->new(), 'new' );
is( ref $obj, 'Finance::Google::Portfolio', 'ref $object' );

done_testing;
