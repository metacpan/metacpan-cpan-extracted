package CountWorker;

use strict;
use warnings;

use base 'Gearman::Spawner::Worker';

use fields 'processed';

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);
    $self->{processed} = 0;

    $self->register_method('inc');
    $self->register_method('die');
    $self->register_method('exit');
    $self->register_method('pid');

    return $self;
}

sub inc {
    my CountWorker $self = shift;
    return ++$self->{processed};
}

sub pid {
    return $$;
}

sub die {
    close STDERR;
    die "deadly";
}

sub exit {
    exit;
}

1;
