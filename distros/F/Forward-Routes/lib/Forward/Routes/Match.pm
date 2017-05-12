package Forward::Routes::Match;
use strict;
use warnings;


sub new {
    return bless {}, shift;
}


sub action {
    return shift->{params}->{action};
}


sub app_namespace {
    my $self = shift;
    return $self->{app_namespace};
}


sub captures {
    my $self = shift;
    my ($key) = @_;
    $self->{captures} ||= {};
    return $self->{captures} unless defined $key && length $key;
    return $self->{captures}->{$key};
}


sub class {
    my $self = shift;

    return undef unless $self->{params}->{controller};

    my @class;

    push @class, $self->{app_namespace} if $self->{app_namespace};

    push @class, $self->{namespace} if $self->{namespace};

    push @class, $self->{params}->{controller};

    return join('::', @class);
}


sub controller {
    my $self = shift;
    return $self->{params}->{controller};
}


sub is_bridge {
    my $self = shift;
    my (@is_bridge) = @_;
    return $self->{is_bridge} unless @is_bridge;
    $self->{is_bridge} = $is_bridge[0];
    return $self;
}


sub name {
    my $self = shift;
    return $self->{name};
}


sub namespace {
    my $self = shift;
    return $self->{namespace};
}


sub params {
    my $self = shift;
    my ($key) = @_;
    $self->{params} ||= {};
    return $self->{params} unless defined $key && length $key;
    return $self->{params}->{$key};
}



sub _add_captures {
    my $self = shift;
    my ($params) = @_;
    %{$self->captures} = (%$params, %{$self->captures});
    return $self;
}


sub _add_params {
    my $self = shift;
    my ($params) = @_;
    %{$self->params} = (%$params, %{$self->params});
    return $self;
}


sub _set_app_namespace {
    my $self = shift;
    my ($value) = @_;
    $self->{app_namespace} = $value;
    return $self;
}


sub _set_captures {
    my $self = shift;
    my ($captures) = @_;
    $self->{captures} = $captures;
    return $self;
}


sub _set_name {
    my $self = shift;
    my ($value) = @_;
    $self->{name} = $value;
    return $self;
}


sub _set_namespace {
    my $self = shift;
    my ($value) = @_;
    $self->{namespace} = $value;
    return $self;
}


sub _set_params {
    my $self = shift;
    my ($params) = @_;
    $self->{params} = $params;
    return $self;
}

1;
