package Finance::BitPay::API::Request::InvoiceGet;
use base qw(Finance::BitPay::API::Request);
use strict;

use constant URL          => 'https://bitpay.com/api/invoice/%s';
use constant REQUEST_TYPE => 'GET';

sub init {
    my $self = shift;
    my %args = @_;
    $self->id($args{id}) if exists $args{id};
    return $self->SUPER::init(@_);
}

sub id           { my $self = shift; $self->get_set(@_) }
sub url          { sprintf URL, shift->id }
sub is_ready     { defined shift->id      }
sub request_type { REQUEST_TYPE           }

1;

__END__

