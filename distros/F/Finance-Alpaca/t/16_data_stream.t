use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $clock = $alpaca->clock;
SKIP: {
    skip 'Market is closed' if !$clock->is_open;
    my $stream = $alpaca->data_stream(
        sub {
            my ($packet) = @_;
            if ( $packet->isa('Finance::Alpaca::Struct::Quote') && $packet->symbol eq 'MSFT' ) {
                pass sprintf '[%s] Bid: %i @ $%f | Ask %i @ $%f', $packet->symbol,
                    $packet->bid_size, $packet->bid_price, $packet->ask_size, $packet->ask_price;
                done_testing;
                exit;
            }
        }
    );
    $stream->subscribe( quotes => ['MSFT'], trades => ['MSFT'], bars => ['*'] );
    Mojo::IOLoop->timer(
        30 => sub {
            fail('Timeout after 30s');
            done_testing;
            exit;
        }
    );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
done_testing;
1;
