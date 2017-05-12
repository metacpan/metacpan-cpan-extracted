package Flower::Chronos::X11;

use strict;
use warnings;

use Encode;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub get_active_window {
    my $self = shift;

    my $id   = $self->_get_active_window_id;
    my $info = $self->_get_window_info($id);

    return $info;
}

sub idle_time { int(`xprintidle` / 1000) }

sub _get_window_info {
    my $self = shift;
    my ($id) = @_;

    my $dump = $self->_run_xprop('-id', $id);

    my $info = {};
    $info->{id} = $id;

    ($info->{class})   = $dump =~ m/WM_CLASS\(STRING\) = (.*)/m;
    ($info->{name})    = $dump =~ m/WM_NAME\(.*?\) = (.*)/m;
    ($info->{role})    = $dump =~ m/WM_WINDOW_ROLE\(STRING\) = (.*)/m;
    ($info->{command}) = $dump =~ m/WM_COMMAND\(.*?\) = (.*)/m;

    $info->{name} = decode('UTF-8', $info->{name});

    $info->{$_} //= '' for keys %$info;

    return $info;
}

sub _get_active_window_id {
    my $self = shift;

    my $active_window = $self->_run_xprop('-root', '_NET_ACTIVE_WINDOW');

    my ($id) = $active_window =~ m/\# ([^\s]+)/;
    $id =~ s{,$}{};

    return $id;
}

sub _run_xprop {
    my $self = shift;
    my (@args) = @_;

    return `xprop @args`;
}

1;
