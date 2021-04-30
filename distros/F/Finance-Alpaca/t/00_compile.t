use strict;
use Test2::V0;
use Test2::Tools::Class;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new( keys => [ 'does not', 'really matter' ] );
isa_ok $alpaca, 'Finance::Alpaca';
done_testing;
1;
