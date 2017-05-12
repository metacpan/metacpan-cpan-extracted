package Finance::LocalBitcoins::API::Request::NewContact;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/contact_create/%s/';
use constant ATTRIBUTES   => qw(ad_id);

sub contact_id       { my $self = shift; $self->get_set(@_) }
sub url              { sprintf URL, shift->contact_id       }
sub is_ready_to_send { defined shift->contact_id            }
sub attributes       { ATTRIBUTES                           }

1;

__END__

