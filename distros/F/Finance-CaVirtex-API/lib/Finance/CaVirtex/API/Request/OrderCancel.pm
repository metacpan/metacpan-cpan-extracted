package Finance::CaVirtex::API::Request::OrderCancel;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL        => 'https://cavirtex.com/api2/user/order_cancel.json';
use constant ATTRIBUTES => qw(id);
use constant DATA_KEY   => undef;

sub url               { URL        }
sub attributes        { ATTRIBUTES }
sub data_key          { DATA_KEY   }
sub id                { my $self = shift; $self->get_set(@_) }
sub is_ready_to_send  { defined shift->id }

1;

__END__

