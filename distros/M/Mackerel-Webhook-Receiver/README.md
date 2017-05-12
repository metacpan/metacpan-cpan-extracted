# NAME

Mackerel::Webhook::Receiver - Mackerel Webhook receiving server

# SYNOPSIS

    use Mackerel::Webhook::Receiver;
    my $receiver = Mackerel::Webhook::Receiver->new;
    $receiver->on(alert => sub {
        my ($event, $req) = @_;
        warn $event->event;
        my $payload = $event->payload;
    });
    my $psgi = $receiver->to_app;
    $receiver->run;

# DESCRIPTION

Mackerel::Webhook::Receiver is utility for creating a server receiving
Mackerel Webhooks and processing something jobs.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
