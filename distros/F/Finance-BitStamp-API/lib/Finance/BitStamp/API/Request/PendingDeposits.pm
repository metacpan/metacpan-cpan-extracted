package Finance::BitStamp::API::Request::PendingDeposits;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL   => 'https://www.bitstamp.net/api/unconfirmed_btc/';
use constant READY => 1;

sub url      { URL   }
sub is_ready { READY }

1;

__END__

