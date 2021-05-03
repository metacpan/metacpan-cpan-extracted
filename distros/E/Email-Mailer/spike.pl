#!/usr/bin/env perl
use exact -lib;
use Email::Mailer;
use Email::Sender::Transport::Print;

Email::Mailer->new(
    transport => Email::Sender::Transport::Print->new,
    subject   => "Bob",
    from      => "bob\@example.org",
    to        => "bob\@example.org",
    text      => "Béton",
)->send;

say '-' x 110;

Email::Mailer->new(
    transport => Email::Sender::Transport::Print->new,
    subject   => "Bob",
    from      => "bob\@example.org",
    to        => "bob\@example.org",
    text      => "Béton",
    html      => "<p>Béton</p>",
)->send;

say '-' x 110;

Email::Mailer->new(
    transport   => Email::Sender::Transport::Print->new,
    subject     => "Bob",
    from        => "bob\@example.org",
    to          => "bob\@example.org",
    text        => "Béton",
    attachments => [{
        source => __FILE__,
    }],
)->send;
