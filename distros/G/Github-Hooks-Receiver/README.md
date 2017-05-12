# NAME

Github::Hooks::Receiver - Github hooks receiving server

# SYNOPSIS

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

# DESCRIPTION

Github::Hooks::Receiver is utility for creating a server receiving
github hooks and processing something jobs.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
