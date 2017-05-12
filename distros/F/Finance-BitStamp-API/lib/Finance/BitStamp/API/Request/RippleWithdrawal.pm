package Finance::BitStamp::API::Request::RippleWithdrawal;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL        => 'https://www.bitstamp.net/api/ripple_withdrawal/';
use constant ATTRIBUTES => qw(amount address currency);

sub amount     { my $self = shift; $self->get_set(@_) }
sub address    { my $self = shift; $self->get_set(@_) }
sub currency   { my $self = shift; $self->get_set(@_) }
sub url        { URL        }
sub attributes { ATTRIBUTES }
sub is_ready   {
    my $self = shift;
    return defined $self->amount and defined $self->address and defined $self->currency;
}

1;

__END__

