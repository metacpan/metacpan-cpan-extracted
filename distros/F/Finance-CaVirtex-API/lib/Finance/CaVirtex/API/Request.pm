package Finance::CaVirtex::API::Request;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Finance::CaVirtex::API::DefaultPackage);

use constant URL               => 'https://cavirtex.com/api2/';
use constant REQUEST_TYPE      => 'POST';
use constant CONTENT_TYPE      => 'application/x-www-form-urlencoded';
use constant ATTRIBUTES        => qw();
use constant READY_TO_SEND     => 0;
use constant IS_PRIVATE        => 1;
use constant DATA_KEY          => undef;

sub url               { URL           }
sub request_type      { REQUEST_TYPE  }
sub content_type      { CONTENT_TYPE  }
sub attributes        { ATTRIBUTES    }
sub is_ready_to_send  { READY_TO_SEND }
sub is_private        { IS_PRIVATE    }
sub data_key          { DATA_KEY      }

## dump all the fields as a hash...
#sub request_content {
    #my $self = shift;
    #my %content;
    #foreach my $field ($self->attributes) {
        #$content{$field} = $self->$field if defined $self->$field;
    #}
    #return %content;
#}

# dump all the fields as a hashref...
sub request_content {
    my $self = shift;
    my $content = {};
    foreach my $field ($self->attributes) {
        $content->{$field} = $self->$field if defined $self->$field;
    }
    return $content;
}

1;

__END__

