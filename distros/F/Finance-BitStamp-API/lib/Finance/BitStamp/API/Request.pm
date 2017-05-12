package Finance::BitStamp::API::Request;
use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Finance::BitStamp::API::DefaultPackage);

use Time::HiRes qw(gettimeofday);

use constant URL          => 'https://www.bitstamp.net/api/';
use constant REQUEST_TYPE => 'POST';
use constant CONTENT_TYPE => 'application/x-www-form-urlencoded';
use constant ATTRIBUTES   => qw();
use constant READY        => 0;
use constant PRIVATE      => 1;

sub url          { URL          }
sub request_type { REQUEST_TYPE }
sub content_type { CONTENT_TYPE }
sub attributes   { ATTRIBUTES   }
sub is_ready     { READY        }
sub is_private   { PRIVATE      }

# this is set once for each object call.
sub nonce { shift->{nonce} ||= sprintf '%d%06d' => gettimeofday }

# dump all the fields as a hash...
sub request_content {
    my $self = shift;
    my %content;
    foreach my $field ($self->attributes) {
        if (defined $self->$field) {
            my $value = $self->$field;
            if (ref $value and ref $value eq 'HASH') {
                foreach my $sub_field (keys %$value) {
                    $content{sprintf('%s[%s]', $field, $sub_field)} = $value->{$sub_field}
                }
            }
            else {
                $content{$field} = $self->$field;
            }
        }
    }
    return %content;
}

1;

__END__

