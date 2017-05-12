package Finance::LocalBitcoins::API::Request::OrderBook;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/bitcoincharts/%s/orderbook.json';
use constant ATTRIBUTES   => qw(currency);
use constant REQUEST_TYPE => 'GET';
use constant IS_PRIVATE   => 0;

sub url               { sprintf URL, shift->currency }
sub attributes        { ATTRIBUTES }
sub request_type      { REQUEST_TYPE }
sub is_private        { IS_PRIVATE }
sub currency          { my $self = shift; $self->get_set(@_) }
sub is_ready_to_send  { defined shift->currency }

1;

__END__

