package Finance::LocalBitcoins::API::Request::Ticker;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/';
use constant REQUEST_TYPE => 'GET';
use constant IS_PRIVATE   => 0;
use constant READY        => 1;

sub url              { URL          }
sub request_type     { REQUEST_TYPE }
sub is_private       { IS_PRIVATE   }
sub is_ready_to_send { READY        }

1;

__END__

