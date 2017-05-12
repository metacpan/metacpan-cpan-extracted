package FormValidator::Nested::FilterInvalid;
use strict;
use warnings;

sub new {
    my $self = shift;
    my $key = caller;

    bless {key => $key}, $self;
}
sub key {
    my $self = shift;
    return $self->{key};
}


1;

