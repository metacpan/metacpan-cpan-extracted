package Event_RPC_Test2;

use strict;
use utf8;

sub get_data			{ shift->{data}				}
sub set_data			{ shift->{data}			= $_[1]	}

sub new {
    my $class = shift;
    my ($data) = @_;
    
    return bless {
        data    => $data,
    }, $class;
}

sub get_object_copy {
    my $self = shift;
    return $self;
}

1;

