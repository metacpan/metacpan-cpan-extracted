package Finance::LocalBitcoins::API::Request::Dash;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/dashboard/';
#use constant ATTRIBUTES  => qw(currencypair);
use constant REQUEST_TYPE => 'POST';
#use constant DATA_KEY    => undef;
use constant IS_PRIVATE   => 1;
use constant READY        => 1;

sub url              { URL          }
#sub attributes      { ATTRIBUTES   }
sub request_type     { REQUEST_TYPE }
#sub data_key        { DATA_KEY     }
sub is_private       { IS_PRIVATE   }
sub is_ready_to_send { READY        }
#sub currencypair    { my $self = shift; $self->get_set(@_) }

1;

__END__

