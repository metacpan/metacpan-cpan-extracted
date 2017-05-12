package Mackerel::Webhook::Receiver;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use JSON;
use Plack::Request;

use Mackerel::Webhook::Receiver::Event;

use Class::Accessor::Lite (
    new => 1,
);
sub events { shift->{events} ||= {} }

sub to_app {
    my $self = shift;
    sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        if ($req->method ne 'POST') {
            return [400, [], ['BAD REQUEST']];
        }

        my $payload = eval { decode_json $req->content }
            or return [400, [], ['BAD REQUEST']];

        my $event_name = $payload->{event};
        my $event = Mackerel::Webhook::Receiver::Event->new(
            payload => $payload,
            event   => $event_name,
        );

        if (my $code = $self->events->{''}) {
            $code->($event, $req);
        }
        if (my $code = $self->events->{$event_name}) {
            $code->($event, $req);
        }

        [200, [], ['OK']];
    };
}

sub on {
    my $self = shift;
    my ($event, $code) = @_;
    if (ref $event eq 'CODE') {
        $code  = $event;
        $event = '';
    }
    $self->events->{$event} = $code;
}

sub run {
    my $self = shift;
    my %opts = @_ == 1 ? %{$_[0]} : @_;

    my %server;
    my $server = delete $opts{server};
    $server{server} = $server if $server;

    my @options = %opts;
    require Plack::Runner;

    my $runner = Plack::Runner->new(
        %server,
        options => \@options,
    );
    $runner->run($self->to_app);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mackerel::Webhook::Receiver - Mackerel Webhook receiving server

=head1 SYNOPSIS

    use Mackerel::Webhook::Receiver;
    my $receiver = Mackerel::Webhook::Receiver->new;
    $receiver->on(alert => sub {
        my ($event, $req) = @_;
        warn $event->event;
        my $payload = $event->payload;
    });
    my $psgi = $receiver->to_app;
    $receiver->run;

=head1 DESCRIPTION

Mackerel::Webhook::Receiver is utility for creating a server receiving
Mackerel Webhooks and processing something jobs.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

