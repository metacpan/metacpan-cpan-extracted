package JLogger;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '1.003';
$VERSION = eval $VERSION;

require Carp;
use Class::Load 'load_class';
use Scalar::Util 'weaken';

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if (my $transport_data = delete $args{transport}) {
        $self->transport($transport_data);
    }

    $self->handlers(delete $args{handlers}
          || {message => ['JLogger::Handler::Message']});


    $self->filters(delete $args{filters} || []);

    $self->storages(delete $args{storages} || []);

    $self->{on_disconnect} =
      exists $args{on_disconnect} ? $args{on_disconnect} : sub { };

    $self;
}

sub transport {
    my ($self, $transport_data) = @_;

    return $self->{transport} unless defined $transport_data;

    weaken $self;
    $self->{transport} = $self->build_element(
        $transport_data,
        on_message    => sub { $self->_on_message($_[1]) },
        on_disconnect => sub { $self->on_disconnect->($self) },
    );
}

sub handlers {
    my ($self, $handlers) = @_;

    return $self->{handlers} unless defined $handlers;

    $self->{handlers} = {};
    while (my ($handler_name, $handler_data) = each %$handlers) {
        $self->{handlers}->{$handler_name} =
          $self->build_element($handler_data);
    }
}

sub filters {
    my ($self, $filters) = @_;

    return $self->{filters} unless defined $filters;

    $self->{filters} = [];
    foreach my $filter (@$filters) {
        push @{$self->{filters}}, $self->build_element($filter);
    }
}

sub storages {
    my ($self, $storages) = @_;

    return $self->{storages} unless defined $storages;

    $self->{storages} = [];
    foreach my $store (@$storages) {
        push @{$self->{storages}}, $self->build_element($store);
    }
}

sub on_disconnect {
    @_ > 1 ? $_[0]->{on_disconnect} = $_[1] : $_[0]->{on_disconnect};
}

sub connect {
    $_[0]->transport->connect;
}

sub disconnect {
    $_[0]->transport->disconnect;
}

sub build_element {
    my ($self, $element, %extra_args) = @_;

    my ($element_class, $args) = @$element;

    $args ||= {};

    load_class $element_class;
    $element_class->new(%$args, %extra_args);
}

sub _on_message {
    my ($self, $node) = @_;

    foreach my $node ($node->nodes) {
        if (my $handler = $self->{handlers}->{$node->name}) {
            if (my $data = $handler->handle($node)) {
                unless ($self->_check_filters($data)) {
                    $self->_store_result($data);
                }
            }
        }
    }
}

sub _check_filters {
    my ($self, $data) = @_;

    foreach my $filter (@{$self->filters}) {
        return 1 if $filter->filter($data);
    }

    0;
}

sub _store_result {
    my ($self, $data) = @_;

    foreach my $store (@{$self->storages}) {
        $store->store($data);
    }
}

1;
__END__

=head1 NAME

JLogger - jabber messages logger

=head1 DESCRIPTION

JLogger is a highly customizable jabber transport for logging messages passed
over jabber server. It has different kind of filters and possibilities to save
captured messages.

=head1 SERVER CONFIGURATION

=head2 ejabberd

Edit ejabberd.cfg and add this line to the C<modules> section:

    mod_service_log:
        loggers: ["jlogger.example.com"]

Add this to the C<listen> section to make ejabberd listen for JLogger connections:

    -
        port: 5526
        module: ejabberd_service
        ip: "127.0.0.1"
        access: all
        hosts:
            "jlogger.example.com":
                password: "secret"

You may find simple configuration in F<config.yaml.example>.
To log messages on old ejabberd < 17.04 server please use transport
C<JLogger::Transport::AnyEvent> instead of
C<JLogger::Transport::AnyEvent::XEP0297>

=head1 AUTHOR

Sergey Zasenko

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2017, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
