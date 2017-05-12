package SlotWorker;

use strict;
use warnings;

use base 'Gearman::Spawner::Worker';

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->register_method('slot');
    return $self;
}

sub slot {
    my SlotWorker $self = shift;
    # wait to make sure this worker doesn't return to handle another job
    sleep 1;
    return $self->{slot};
}

1;
