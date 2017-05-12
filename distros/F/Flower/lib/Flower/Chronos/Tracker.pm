package Flower::Chronos::Tracker;

use strict;
use warnings;

use Flower::Chronos::X11;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{idle_timeout}  = $params{idle_timeout}  || 300;
    $self->{flush_timeout} = $params{flush_timeout} || 300;
    $self->{applications}  = $params{applications};
    $self->{on_end}        = $params{on_end};

    return $self;
}

sub track {
    my $self = shift;

    if ($self->_is_time_to_flush) {
        if (%{$self->{prev} || {}}) {
            $self->{prev}->{_end} =
              $self->{prev}->{_start} + $self->{flush_timeout};

            $self->{on_end}->($self->{prev});
            $self->{prev} = {};
        }
    }

    my $x11 = $self->{x11} ||= $self->_build_x11;

    my $info;
    if ($x11->idle_time > $self->{idle_timeout}) {
        $info = {idle => 1, category => ''};
    }
    else {
        $info = $x11->get_active_window;
    }

    my $prev = $self->{prev} ||= {};
    my $time = $self->_time;

    $self->_run_applications($info) unless $info->{idle};

    $info->{$_} //= '' for (qw/id name role class/);
    $info->{application} //= 'other';
    $info->{category}    //= 'other';

    if (  !$prev->{id}
        || $info->{id} ne $prev->{id}
        || $info->{name} ne $prev->{name}
        || $info->{role} ne $prev->{role}
        || $info->{class} ne $prev->{class})
    {
        if (%$prev) {
            $prev->{_end} = $time;
            $self->{on_end}->($prev);
        }

        $info->{_start} ||= $time;
    }

    $self->{prev} = $info;
    $self->{prev}->{_start} ||= $time;

    return $self;
}

sub _run_applications {
    my $self = shift;
    my ($info) = @_;

    foreach my $application (@{$self->{applications}}) {
        local $@;
        my $rv = eval { $application->run($info) };
        next if $@;

        last if $rv;
    }
}

sub _is_time_to_flush {
    my $self = shift;

    $self->{flush_time} //= $self->_time;

    if ($self->_time - $self->{flush_time} > $self->{flush_timeout}) {
        $self->{flush_time} = $self->_time;
        return 1;
    }

    return 0;
}

sub _build_x11 {
    return Flower::Chronos::X11->new;
}

sub _time { time }

1;
