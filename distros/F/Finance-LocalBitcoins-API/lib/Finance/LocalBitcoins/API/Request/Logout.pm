package Finance::LocalBitcoins::API::Request::Logout;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/logout/';
use constant READY        => 1;

sub url              { URL          }
sub is_ready_to_send { READY        }

1;

__END__

