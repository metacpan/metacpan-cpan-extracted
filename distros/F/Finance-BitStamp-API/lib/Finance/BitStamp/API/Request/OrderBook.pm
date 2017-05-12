package Finance::BitStamp::API::Request::OrderBook;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL          => 'https://www.bitstamp.net/api/order_book/';
use constant REQUEST_TYPE => 'GET';
use constant ATTRIBUTES   => qw(group);
use constant PRIVATE      => 0;
use constant READY        => 1;

sub group        { my $self = shift; $self->get_set(@_) }
sub url          { URL          }
sub request_type { REQUEST_TYPE }
sub attributes   { ATTRIBUTES   }
sub is_private   { PRIVATE      }
sub is_ready     { READY        }

1;

__END__

