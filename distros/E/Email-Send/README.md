# NAME

Email::Send - Simply Sending Email

# WAIT!  ACHTUNG!

Email::Send is going away... well, not really going away, but it's being
officially marked "out of favor."  It has API design problems that make it hard
to usefully extend and rather than try to deprecate features and slowly ease in
a new interface, we've released Email::Send**er** which fixes these problems and
others.  As of today, 2008-12-19, Email::Sender is young, but it's fairly
well-tested.  Please consider using it instead for any new work.

# SYNOPSIS

    use Email::Send;

    my $message = <<'__MESSAGE__';
    To: recipient@example.com
    From: sender@example.com
    Subject: Hello there folks

    How are you? Enjoy!
    __MESSAGE__

    my $sender = Email::Send->new({mailer => 'SMTP'});
    $sender->mailer_args([Host => 'smtp.example.com']);
    $sender->send($message);

    # more complex
    my $bulk = Email::Send->new;
    for ( qw[SMTP Sendmail Qmail] ) {
        $bulk->mailer($_) and last if $bulk->mailer_available($_);
    }

    $bulk->message_modifier(sub {
        my ($sender, $message, $to) = @_;
        $message->header_set(To => qq[$to\@geeknest.com])
    });

    my @to = qw[casey chastity evelina casey_jr marshall];
    my $rv = $bulk->send($message, $_) for @to;

# DESCRIPTION

This module provides a very simple, very clean, very specific interface
to multiple Email mailers. The goal of this software is to be small
and simple, easy to use, and easy to extend.

## Constructors

- new

        my $sender = Email::Send->new({
            mailer      => 'NNTP',
            mailer_args => [ Host => 'nntp.example.com' ],
        });

    Create a new mailer object. This method can take parameters for any of the data
    properties of this module. Those data properties, which have their own accessors,
    are listed under ["Properties"](#properties).

## Properties

- mailer

    The mailing system you'd like to use for sending messages with this object.
    This is not defined by default. If you don't specify a mailer, all available
    plugins will be tried when the `send` method is called until one succeeds.

- mailer\_args

    Arguments passed into the mailing system you're using.

- message\_modifier

    If defined, this callback is invoked every time the `send` method is called
    on an object. The mailer object will be passed as the first argument. Second,
    the actual `Email::Simple` object for a message will be passed. Finally, any
    additional arguments passed to `send` will be passed to this method in the
    order they were received.

    This is useful if you are sending in bulk.

## METHODS

- send

        my $result = $sender->send($message, @modifier_args);

    Send a message using the predetermined mailer and mailer arguments. If you
    have defined a `message_modifier` it will be called prior to sending.

    The first argument you pass to send is an email message. It must be in some
    format that `Email::Abstract` can understand. If you don't have
    `Email::Abstract` installed then sending as plain text or an `Email::Simple`
    object will do.

    Any remaining arguments will be passed directly into your defined
    `message_modifier`.

- all\_mailers

        my @available = $sender->all_mailers;

    Returns a list of available mailers. These are mailers that are
    installed on your computer and register themselves as available.

- mailer\_available

        # is SMTP over SSL avaialble?
        $sender->mailer('SMTP')
          if $sender->mailer_available('SMTP', ssl => 1);

    Given the name of a mailer, such as `SMTP`, determine if it is
    available. Any additional arguments passed to this method are passed
    directly to the `is_available` method of the mailer being queried.

## Writing Mailers

    package Email::Send::Example;

    sub is_available {
        eval { use Net::Example }
    }

    sub send {
        my ($class, $message, @args) = @_;
        use Net::Example;
        Net::Example->do_it($message) or return;
    }

    1;

Writing new mailers is very simple. If you want to use a short name
when calling `send`, name your mailer under the `Email::Send` namespace.
If you don't, the full name will have to be used. A mailer only needs
to implement a single function, `send`. It will be called from
`Email::Send` exactly like this.

    Your::Sending::Package->send($message, @args);

`$message` is an Email::Simple object, `@args` are the extra
arguments passed into `Email::Send::send`.

Here's an example of a mailer that sends email to a URL.

    package Email::Send::HTTP::Post;
    use strict;

    use vars qw[$AGENT $URL $FIELD];
    use Return::Value;

    sub is_available {
        eval { use LWP::UserAgent }
    }

    sub send {
        my ($class, $message, @args);

        require LWP::UserAgent;

        if ( @args ) {
            my ($URL, $FIELD) = @args;
            $AGENT = LWP::UserAgent->new;
        }
        return failure "Can't send to URL if no URL and field are named"
            unless $URL && $FIELD;
        $AGENT->post($URL => { $FIELD => $message->as_string });
        return success;
    }

    1;

This example will keep a UserAgent singleton unless new arguments are
passed to `send`. It is used by calling `Email::Send::send`.

    my $sender = Email::Send->new({ mailer => 'HTTP::Post' });

    $sender->mailer_args([ 'http://example.com/incoming', 'message' ]);

    $sender->send($message);
    $sender->send($message2); # uses saved $URL and $FIELD

# SEE ALSO

[Email::Simple](https://metacpan.org/pod/Email%3A%3ASimple),
[Email::Abstract](https://metacpan.org/pod/Email%3A%3AAbstract),
[Email::Send::IO](https://metacpan.org/pod/Email%3A%3ASend%3A%3AIO),
[Email::Send::NNTP](https://metacpan.org/pod/Email%3A%3ASend%3A%3ANNTP),
[Email::Send::Qmail](https://metacpan.org/pod/Email%3A%3ASend%3A%3AQmail),
[Email::Send::SMTP](https://metacpan.org/pod/Email%3A%3ASend%3A%3ASMTP),
[Email::Send::Sendmail](https://metacpan.org/pod/Email%3A%3ASend%3A%3ASendmail),
[perl](https://metacpan.org/pod/perl).

# PERL EMAIL PROJECT

This module is maintained by the Perl Email Project.

[http://emailproject.perl.org/wiki/Email::Send](http://emailproject.perl.org/wiki/Email::Send)

# AUTHOR

Casey West, <`casey@geeknest.com`>.

# CONTRIBUTORS

- Chase Whitener, <`capoeirab@cpan.org`>.
- Ricardo SIGNES, <`rjbs@cpan.org`>.

# COPYRIGHT AND LICENSE

Copyright (c) 2004 Casey West.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
