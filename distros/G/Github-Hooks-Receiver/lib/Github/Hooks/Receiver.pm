package Github::Hooks::Receiver;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Github::Hooks::Receiver::Event;

use JSON;
use Plack::Request;
use Class::Accessor::Lite (
    new => 1,
    ro => [qw/secret/],
);

sub events { shift->{events} ||= {} }

sub to_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        if ($req->method ne 'POST') {
            return [400, [], ['BAD REQUEST']];
        }

        # Parse JSON payload
        my $payload_json;
        if (lc $req->header('content-type') eq 'application/json') {
            $payload_json = $req->content;
        } elsif (lc $req->header('content-type') eq 'application/x-www-form-urlencoded') {
            $payload_json = $req->param('payload');
        }
        my $payload = eval { decode_json $payload_json }
            or return [400, [], ['BAD REQUEST']];

        my $event_name = $req->header('X-GitHub-Event');
        my $event = Github::Hooks::Receiver::Event->new(
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

    if ($self->secret) {
        require Plack::Middleware::HubSignature;
        $app = Plack::Middleware::HubSignature->wrap($app,
            secret => $self->secret,
        );
    }
    $app;
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

Github::Hooks::Receiver - Github hooks receiving server

=head1 SYNOPSIS

    use Github::Hooks::Receiver;
    my $receiver = Github::Hooks::Receiver->new(secret => 'secret1234');
    # my $receiver = Github::Hooks::Receiver->new;
    # secret is optional, but strongly RECOMMENDED!
    $receiver->on(push => sub {
        my ($event, $req) = @_;
        warn $event->event;
        my $payload = $event->payload;
    });
    my $psgi = $receiver->to_app;
    $receiver->run;

=head1 DESCRIPTION

Github::Hooks::Receiver is utility for creating a server receiving
github hooks and processing something jobs.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

