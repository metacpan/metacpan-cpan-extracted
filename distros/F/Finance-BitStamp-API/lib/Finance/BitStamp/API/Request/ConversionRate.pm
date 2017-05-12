package Finance::BitStamp::API::Request::ConversionRate;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL          => 'https://www.bitstamp.net/api/eur_usd/';
use constant REQUEST_TYPE => 'GET';
use constant PRIVATE      => 0;
use constant READY        => 1;

sub url          { URL          }
sub request_type { REQUEST_TYPE }
sub is_private   { PRIVATE      }
sub is_ready     { READY        }

1;

__END__

