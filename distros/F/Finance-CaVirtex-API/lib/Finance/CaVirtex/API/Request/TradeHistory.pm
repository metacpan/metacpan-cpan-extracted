package Finance::CaVirtex::API::Request::TradeHistory;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL        => 'https://cavirtex.com/api2/user/trades.json';
use constant ATTRIBUTES => qw(currencypair days startdate enddate);
use constant DATA_KEY   => 'trades';

sub url              { URL        }
sub attributes       { ATTRIBUTES }
sub data_key         { DATA_KEY   }
sub currencypair     { my $self = shift; $self->get_set(@_) }
sub days             { my $self = shift; $self->get_set(@_) }
sub startdate        { my $self = shift; $self->get_set(@_) }
sub enddate          { my $self = shift; $self->get_set(@_) }
sub is_ready_to_send { defined shift->currencypair }

1;

__END__

