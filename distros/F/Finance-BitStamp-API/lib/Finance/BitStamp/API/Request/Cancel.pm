package Finance::BitStamp::API::Request::Cancel;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL        => 'https://www.bitstamp.net/api/cancel_order/';
use constant ATTRIBUTES => qw(id);

sub id       { my $self = shift; $self->get_set(@_) }
sub url      { URL }
sub is_ready { defined shift->id }

1;

__END__

