package Finance::LocalBitcoins::API::Request::Contacts;
use base qw(Finance::LocalBitcoins::API::Request);
use strict;

use constant URL        => 'https://localbitcoins.com';
use constant READY      => 1;
use constant ATTRIBUTES => qw(contacts);

sub url              { URL          }
sub attributes       { ATTRIBUTES   }
sub is_ready_to_send { return defined shift->contacts }
# WARNING: THIS IS A WEIRD ROUTINE!
# it accepts an array and returns a comma separated list. ie:
# my $return = $api->currency('this','that','other');
# $return now is: "this,that,other"
sub contacts { 
    my $self = shift;
    my $contacts = $self->get_set([@_]); 
    return undef unless ref $contacts eq 'ARRAY';
    return join ',', @$contacts;
}

1;

__END__

