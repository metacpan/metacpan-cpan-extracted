package Finance::CaVirtex::API::Request::TradeBook;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL          => 'https://cavirtex.com/api2/trades.json';
use constant ATTRIBUTES   => qw(currencypair days startdate enddate);
use constant DATA_KEY     => [qw(orders trades)];
use constant REQUEST_TYPE => 'GET';
use constant IS_PRIVATE   => 0;

sub url               { URL }
sub attributes        { ATTRIBUTES }
sub request_type      { REQUEST_TYPE }
sub data_key          { DATA_KEY }
sub is_private        { IS_PRIVATE }
sub currencypair      { my $self = shift; $self->get_set(@_) }
sub days              { my $self = shift; $self->get_set(@_) }
sub startdate         { my $self = shift; $self->get_set(@_) }
sub enddate           { my $self = shift; $self->get_set(@_) }
# Valid currencypair: BTCCAD, LTCCAD, BTCLTC
sub is_ready_to_send  { defined shift->currencypair }

1;

__END__

