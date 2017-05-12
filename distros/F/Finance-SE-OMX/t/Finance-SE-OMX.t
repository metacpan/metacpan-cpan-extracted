use Test::More tests => 2;

BEGIN { use_ok('Finance::SE::OMX') };

$stock = Finance::SE::OMX->new;
isnt($stock->get_stocklist(0), undef, "Getting the A-list");
