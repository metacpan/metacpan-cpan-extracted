package Finance::LocalBitcoins::API::Request;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use constant URL               => 'https://localbitcoins.com/api/';
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

sub new { (bless {} => shift)->init(@_) }
sub init {
    my $self = shift;
    my %args = @_;
    foreach my $attribute ($self->attributes) {
        $self->$attribute($args{$attribute}) if exists $args{$attribute};
    }
    return $self;
}

# this method simply makes all the get/setter attribute methods below very tidy...
sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

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

