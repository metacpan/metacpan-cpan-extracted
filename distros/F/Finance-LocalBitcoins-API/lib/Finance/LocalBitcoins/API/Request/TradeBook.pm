package Finance::LocalBitcoins::API::Request::TradeBook;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/bitcoincharts/%s/trades.json';
use constant ATTRIBUTES   => qw(since);
use constant REQUEST_TYPE => 'GET';
use constant IS_PRIVATE   => 0;

sub init {
    my $self = shift;
    my %args = @_;
    $self->currency($args{currency}) if exists $args{currency};
    return $self->SUPER::init(@_);
}

sub currency         { my $self = shift; $self->get_set(@_) }
sub since            { my $self = shift; $self->get_set(@_) }
sub url              { sprintf URL, shift->currency }
sub is_ready_to_send { defined shift->currency }
sub attributes       { ATTRIBUTES   }
sub request_type     { REQUEST_TYPE }
sub is_private       { IS_PRIVATE   }

1;

__END__

