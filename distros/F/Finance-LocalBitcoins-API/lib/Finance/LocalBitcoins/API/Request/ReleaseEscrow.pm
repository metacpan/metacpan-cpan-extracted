package Finance::LocalBitcoins::API::Request::ReleaseEscrow;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com/api/escrow_release/%s/';
use constant ATTRIBUTES => qw(escrow_id);

sub escrow_id        { my $self = shift; $self->get_set(@_) }
sub url              { sprintf URL, shift->escrow_id        }
sub is_ready_to_send { defined shift->escrow_id             }
sub attributes       { ATTRIBUTES                           }

1;

__END__

