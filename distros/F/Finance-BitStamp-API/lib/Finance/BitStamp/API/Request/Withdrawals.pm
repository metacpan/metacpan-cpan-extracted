package Finance::BitStamp::API::Request::Withdrawals;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL   => 'https://www.bitstamp.net/api/withdrawal_requests/';
use constant READY => 1;

sub url      { URL   }
sub is_ready { READY }

1;

__END__

