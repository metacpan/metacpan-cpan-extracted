use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $history = $alpaca->portfolio_history();
is( ref $history, 'HASH', 'Portfoio history is returned as a hash of arrays' );
done_testing;
1;
