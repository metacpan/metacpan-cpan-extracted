package Finance::CaVirtex::API::Request::Order;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL        => 'https://cavirtex.com/api2/user/order.json';
use constant ATTRIBUTES => qw(currencypair mode amount price);
use constant DATA_KEY   => 'order';


sub url               { URL        }
sub attributes        { ATTRIBUTES }
sub data_key          { DATA_KEY   }
sub currencypair      { my $self = shift; $self->get_set(@_) }
sub mode              { my $self = shift; $self->get_set(@_) }
sub amount            { my $self = shift; $self->get_set(@_) }
sub price             { my $self = shift; $self->get_set(@_) }
sub is_ready_to_send  {
    my $self = shift;
    return defined $self->currencypair and defined $self->mode and defined $self->amount and defined $self->price;
}

1;

__END__

