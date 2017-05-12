package Finance::CaVirtex::API::Request::Withdraw;
use base qw(Finance::CaVirtex::API::Request);
use strict;

use constant URL        => 'https://cavirtex.com/api2/user/withdraw.json';
use constant ATTRIBUTES => qw(amount currency address);

sub amount   { my $self = shift; $self->get_set(@_) }
sub currency { my $self = shift; $self->get_set(@_) }
sub address  { my $self = shift; $self->get_set(@_) }

sub url              { URL }
sub attributes       { ATTRIBUTES }
sub is_ready_to_send { 
    my $self = shift;
    return defined $self->amount and defined $self->currency and defined $self->address;
}

1;

__END__

