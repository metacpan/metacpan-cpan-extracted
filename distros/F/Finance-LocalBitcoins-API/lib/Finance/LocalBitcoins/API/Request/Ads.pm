package Finance::LocalBitcoins::API::Request::Ads;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/ads/';
use constant READY        => 1;
use constant ATTRIBUTES   => qw(visible trade_type currency countrycode);

sub visible          { my $self = shift; $self->get_set(@_) }
sub trade_type       { my $self = shift; $self->get_set(@_) }
sub currency         { my $self = shift; $self->get_set(@_) }
sub countrycode      { my $self = shift; $self->get_set(@_) }
sub url              { URL          }
sub is_ready_to_send { READY        }
sub attributes       { ATTRIBUTES   }

1;

__END__

