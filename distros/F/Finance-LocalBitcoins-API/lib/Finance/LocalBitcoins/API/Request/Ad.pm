package Finance::LocalBitcoins::API::Request::Ad;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com/api/ad-create/';
use constant ATTRIBUTES => qw(min_amount max_amount price_equation lat lon city location_string countrycode account_info bank_name sms_verification_required track_max_amount require_trusted_by_advertiser trade_type online_provider);
use constant READY      => 1;

sub min_amount                    { my $self = shift; $self->get_set(@_) }
sub max_amount                    { my $self = shift; $self->get_set(@_) }
sub price_equation                { my $self = shift; $self->get_set(@_) }
sub lat                           { my $self = shift; $self->get_set(@_) }
sub lon                           { my $self = shift; $self->get_set(@_) }
sub city                          { my $self = shift; $self->get_set(@_) }
sub location_string               { my $self = shift; $self->get_set(@_) }
sub countrycode                   { my $self = shift; $self->get_set(@_) }
sub account_info                  { my $self = shift; $self->get_set(@_) }
sub bank_name                     { my $self = shift; $self->get_set(@_) }
sub sms_verification_required     { my $self = shift; $self->get_set(@_) }
sub track_max_amount              { my $self = shift; $self->get_set(@_) }
sub require_trusted_by_advertiser { my $self = shift; $self->get_set(@_) } 
sub trade_type                    { my $self = shift; $self->get_set(@_) }
sub online_provider               { my $self = shift; $self->get_set(@_) }

sub url              { URL          }
sub is_ready_to_send { READY        }
sub attributes       { ATTRIBUTES   }

1;

__END__

