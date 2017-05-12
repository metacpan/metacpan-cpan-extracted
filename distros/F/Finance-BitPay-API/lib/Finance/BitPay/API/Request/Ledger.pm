package Finance::BitPay::API::Request::Ledger;
use base qw(Finance::BitPay::API::Request);
use strict;

use constant URL          => 'https://bitpay.com/api/ledger';
use constant ATTRIBUTES   => qw(c startDate endDate);

sub c          { my $self = shift; $self->get_set(@_) }
sub startDate  { my $self = shift; $self->get_set(@_) }
sub endDate    { my $self = shift; $self->get_set(@_) }
sub attributes { ATTRIBUTES }
sub url        { URL        }
sub is_ready   {
    my $self = shift;
    return defined $self->c
       and defined $self->startDate
       and defined $self->endDate;
}

1;

__END__

