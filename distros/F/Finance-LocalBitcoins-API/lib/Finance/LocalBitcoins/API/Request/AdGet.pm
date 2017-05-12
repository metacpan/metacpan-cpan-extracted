package Finance::LocalBitcoins::API::Request::AdGet;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com/api/ad-get/%s/';
use constant READY      => 1;
use constant ATTRIBUTES => qw(ad_id);

sub ad_id            { my $self = shift; $self->get_set(@_) }
sub url              { sprintf URL, shift->ad_id            }
sub is_ready_to_send { defined shift->ad_id                 }
sub attributes       { ATTRIBUTES                           }

1;

__END__

