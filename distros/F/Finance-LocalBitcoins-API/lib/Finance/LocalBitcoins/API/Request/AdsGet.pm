package Finance::LocalBitcoins::API::Request::AdsGet;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/ad-get';
use constant READY        => 1;
use constant ATTRIBUTES   => qw(ads);

sub url              { URL          }
sub is_ready_to_send { defined shift->ads       }
sub attributes       { ATTRIBUTES   }
sub ads {
    my $self = shift;
    my $ads = $self->get_set([@_]);
    return undef unless ref $ads eq 'ARRAY';
    return join ',', @$ads;
}

1;

__END__

