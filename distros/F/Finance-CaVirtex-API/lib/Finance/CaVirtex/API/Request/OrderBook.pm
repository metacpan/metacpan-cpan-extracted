package Finance::CaVirtex::API::Request::OrderBook;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL               => 'https://cavirtex.com/api2/orderbook.json';
use constant ATTRIBUTES        => qw(currencypair);
use constant DATA_KEY          => 'orderbook';
use constant REQUEST_TYPE      => 'GET';
use constant IS_PRIVATE        => 0;

sub request_type      { REQUEST_TYPE }
sub url               { URL          }
sub attributes        { ATTRIBUTES   }
sub data_key          { DATA_KEY     }
sub is_private        { IS_PRIVATE   }

sub currencypair      { my $self = shift; $self->get_set(@_) }
sub is_ready_to_send  { defined shift->currencypair }

1;

__END__

