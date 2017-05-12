package Finance::BitStamp::API::Request::Transactions;
use base qw(Finance::BitStamp::API::Request);
use strict;

use constant URL        => 'https://www.bitstamp.net/api/user_transactions/';
use constant ATTRIBUTES => qw(offset limit sort);
use constant READY      => 1;

sub offset     { my $self = shift; $self->get_set(@_) }
sub limit      { my $self = shift; $self->get_set(@_) }
sub sort       { my $self = shift; $self->get_set(@_) }
sub url        { URL        }
sub is_ready   { READY      }
sub attributes { ATTRIBUTES }

1;

__END__

