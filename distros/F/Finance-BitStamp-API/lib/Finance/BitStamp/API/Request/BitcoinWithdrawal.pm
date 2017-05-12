package Finance::BitStamp::API::Request::BitcoinWithdrawal;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL        => 'https://www.bitstamp.net/api/bitcoin_withdrawal/';
use constant ATTRIBUTES => qw(amount address);

sub amount   { my $self = shift; $self->get_set(@_) }
sub address  { my $self = shift; $self->get_set(@_) }
sub url      { URL }
sub is_ready {
    my $self = shift;
    return defined $self->amount and defined $self->address;
}

1;

__END__

