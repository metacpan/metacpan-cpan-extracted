package Finance::BitStamp::API::Request::Sell;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL        => 'https://www.bitstamp.net/api/sell/';
use constant ATTRIBUTES => qw(amount price);

sub amount   { my $self = shift; $self->get_set(@_) }
sub price    { my $self = shift; $self->get_set(@_) }
sub url      { URL   }
sub is_ready {
    my $self = shift;
    return defined $self->amount and defined $self->price;
}

1;

__END__

