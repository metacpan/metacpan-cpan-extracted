package Apache::Session::Timeout;

use strict;
use Apache::Session::File;

our @ISA = ('Apache::Session::File');

sub populate {
    my $self = shift;
    sleep 6;
    return $self->SUPER::populate(@_);
}

1;
