package Finance::LocalBitcoins::API::Request::Send;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/wallet-send/';
use constant ATTRIBUTES   => qw(address amount);

sub address          { my $self = shift; $self->get_set(@_) }
sub amount           { my $self = shift; $self->get_set(@_) }
sub url              { URL          }
sub attributes       { ATTRIBUTES   }
sub is_ready_to_send {
    my $self = shift;
    return defined $self->address and defined $self->amount
}

1;

__END__

