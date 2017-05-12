package Finance::BitStamp::API::Request::RippleAddress;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL   => 'https://www.bitstamp.net/api/ripple_address/';
use constant READY => 1;

sub url      { URL   }
sub is_ready { READY }

1;

__END__

