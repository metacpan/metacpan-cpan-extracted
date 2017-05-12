package Finance::BitPay::API::Request::Rates;
use base qw(Finance::BitPay::API::Request);
use strict;

use constant URL          => 'https://bitpay.com/api/rates';
use constant REQUEST_TYPE => 'GET';
use constant READY        => 1;

sub request_type { REQUEST_TYPE }
sub url          { URL          }
sub is_ready     { READY        }

1;

__END__

