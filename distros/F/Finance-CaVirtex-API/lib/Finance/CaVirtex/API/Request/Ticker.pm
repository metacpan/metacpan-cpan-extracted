package Finance::CaVirtex::API::Request::Ticker;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL          => 'https://cavirtex.com/api2/ticker.json';
use constant ATTRIBUTES   => qw(currencypair);
use constant REQUEST_TYPE => 'GET';
use constant DATA_KEY     => 'ticker';
use constant IS_PRIVATE   => 0;
use constant READY        => 1;

sub url              { URL }
sub attributes       { ATTRIBUTES }
sub request_type     { REQUEST_TYPE }
sub data_key         { DATA_KEY }
sub is_private       { IS_PRIVATE }
sub is_ready_to_send { READY }
sub currencypair     { my $self = shift; $self->get_set(@_) }

1;

__END__

