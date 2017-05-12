package Finance::LocalBitcoins::API::Request::SendPin;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com/api/wallet-send-pin/';
use constant ATTRIBUTES => qw(address amount pincode);

sub address          { my $self = shift; $self->get_set(@_) }
sub amount           { my $self = shift; $self->get_set(@_) }
sub pincode          { my $self = shift; $self->get_set(@_) }
sub url              { URL        }
sub attributes       { ATTRIBUTES }
sub is_ready_to_send {
    my $self = shift;
    return defined $self->address and defined $self->amount and defined $self->pincode;
}

1;

__END__

