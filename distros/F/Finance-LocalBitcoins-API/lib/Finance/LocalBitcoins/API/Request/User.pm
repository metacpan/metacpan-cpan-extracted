package Finance::LocalBitcoins::API::Request::User;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL          => 'https://localbitcoins.com/api/account_info/%s/';
#use constant ATTRIBUTES   => qw(username);
#use constant ATTRIBUTES   => qw();
#use constant REQUEST_TYPE => 'POST';
#use constant DATA_KEY    => undef;
use constant IS_PRIVATE   => 1;
use constant READY        => 1;

sub init {
    my $self = shift;
    my %args = @_;
    $self->username($args{username}) if exists $args{username};
    return $self->SUPER::init(@_);
}

sub url              { sprintf URL, shift->username }
#sub attributes       { ATTRIBUTES   }
#sub request_type     { REQUEST_TYPE }
#sub data_key        { DATA_KEY     }
sub is_private       { IS_PRIVATE   }
sub is_ready_to_send { READY        }
sub username         { my $self = shift; $self->get_set(@_) }

1;

__END__

