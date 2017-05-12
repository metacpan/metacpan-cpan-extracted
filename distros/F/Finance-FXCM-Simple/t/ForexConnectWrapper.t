use strict;
use warnings;

use Test::More tests => 10;
use Scalar::Util qw(looks_like_number);
use Data::Dumper;

BEGIN { use_ok('Finance::FXCM::Simple') };

SKIP: {
    skip 'No login information to fxcm demo account defined', 9 unless (defined($ENV{FXCM_USER}) && defined($ENV{FXCM_PASSWORD}));
    eval {
        my $ff = Finance::FXCM::Simple->new($ENV{FXCM_USER}, $ENV{FXCM_PASSWORD}, "Demo", "http://www.fxcorporate.com/Hosts.jsp");
        $ff->setSubscriptionStatus('EUR/CAD', 'D');
        my $offers_hash = $ff->getOffersHash();
        is($offers_hash->{'EUR/CAD'}, 'D', 'EUR/CAD updates unsubscribed');
        $ff->setSubscriptionStatus('EUR/CAD', 'T');
        $offers_hash = $ff->getOffersHash();
        is($offers_hash->{'EUR/CAD'}, 'T', 'EUR/CAD updates subscribed');
        ok(looks_like_number($ff->getAsk("EUR/USD")), "getAsk returns a number");
        ok(looks_like_number($ff->getBid("EUR/USD")), "getBid returns a number");
        ok(looks_like_number($ff->getBalance()), "getBalance returns a number");
        ok(looks_like_number($ff->getBaseUnitSize("XAU/USD")), "getBaseUnitSize returns a number");
        ok(looks_like_number($ff->getBaseUnitSize("EUR/CAD")), "getBaseUnitSize works for EUR/CAD pair");


        #Close any existing trades to get the account into a well defined state
        my $trades = $ff->getTrades();
        foreach my $trade(@$trades) {
            $ff->closeMarket($trade->{id}, $trade->{size});
        }

        $trades = $ff->getTrades();
        is(@$trades, 0, "getTrades returns empty array ref (instead of undef) when no trades opened");

        $ff->openMarket("AUD/USD", "B", 1000);

        $trades = $ff->getTradesForSymbol("AUD/USD");
        is(@$trades, 1, "1 trade opened");
        is($trades->[0]->{symbol}, "AUD/USD", "AUD/USD trade");
        is($trades->[0]->{direction}, "long", "AUD/USD trade long");
        is($trades->[0]->{size}, "1000", "AUD/USD trade long 1000");

        $ff->openMarket("EUR/USD", "B", 5000);
        $trades = $ff->getTrades();
        is(@$trades, 2, "2 trades opened");
        foreach my $trade(@$trades) {
            $ff->closeMarket($trade->{id}, $trade->{size});
        }
        $trades = $ff->getTrades();
        is(@$trades, 0, "All trades closed");
        1;
    } or do {
        print "Error: " . $@;
    };
};
