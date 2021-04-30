use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $config = $alpaca->configuration();
isa_ok( $config, 'Finance::Alpaca::Struct::Configuration' );
isa_ok(
    $alpaca->modify_configuration( trade_confirm_emails => 'all' ),
    'Finance::Alpaca::Struct::Configuration'
);
done_testing;
1;
