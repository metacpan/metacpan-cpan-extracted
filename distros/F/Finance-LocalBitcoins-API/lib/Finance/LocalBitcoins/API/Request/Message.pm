package Finance::LocalBitcoins::API::Request::Message;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com/api/contact_message_post/%s/';
use constant ATTRIBUTES => qw(contact_id msg);

sub contact_id       { my $self = shift; $self->get_set(@_) }
sub msg              { my $self = shift; $self->get_set(@_) }
sub url              { sprintf URL, shift->contact_id       }
sub attributes       { ATTRIBUTES                           }
sub is_ready_to_send {
    my $self = shift;
    return defined $self->contact_id and defined $self->msg;
}

1;

__END__

