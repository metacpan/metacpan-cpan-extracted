[![Build Status](https://travis-ci.org/sdt/Email-Sender-Transport-Mailgun.svg?branch=master)](https://travis-ci.org/sdt/Email-Sender-Transport-Mailgun)
# NAME

Email::Sender::Transport::Mailgun - Mailgun transport for Email::Sender

# SYNOPSIS

    use Email::Sender::Simple qw( sendmail );
    use Email::Sender::Transport::Mailgun qw( );

    my $transport = Email::Sender::Transport::Mailgun->new(
        api_key => '...',
        domain  => '...',
    );

    my $message = ...;

    sendmail($message, { transport => $transport });

# DESCRIPTION

This transport delivers mail via Mailgun's messages.mime API.

## Why use this module?

The SMTP transport can also be used to send messages through Mailgun. In this
case, Mailgun options must be specified with Mailgun-specific MIME headers.

This module exposes those options as attributes, which can be set in code, or
via `EMAIL_SENDER_TRANSPORT_` environment variables.

## Why not use this module?

This module uses Mailgun's messages.mime API, not the full-blown messages API.

If you want to use advanced Mailgun features such as templated batch mailouts
or mailing lists, you're better off using something like [WebService::Mailgun](https://metacpan.org/pod/WebService%3A%3AMailgun)
or [WWW::Mailgun](https://metacpan.org/pod/WWW%3A%3AMailgun).

# REQUIRED ATTRIBUTES

The attributes all correspond directly to Mailgun parameters.

## api\_key

Mailgun API key. See [https://documentation.mailgun.com/api-intro.html#authentication](https://documentation.mailgun.com/api-intro.html#authentication)

## domain

Mailgun domain. See [https://documentation.mailgun.com/api-intro.html#base-url](https://documentation.mailgun.com/api-intro.html#base-url)

# OPTIONAL ATTRIBUTES

These (except region) correspond to the `o:` options in the `messages.mime`
section of [https://documentation.mailgun.com/api-sending.html#sending](https://documentation.mailgun.com/api-sending.html#sending)

## campaign

Id of the campaign. Comma-separated string list or arrayref of strings.

## deliverytime

Desired time of delivery. String or DateTime object.

## dkim

Enables/disables DKIM signatures. `'yes'` or `'no'`.

## region

Defines used Mailgun region. `'us'` (default) or `'eu'`.

See [https://documentation.mailgun.com/en/latest/api-intro.html#mailgun-regions](https://documentation.mailgun.com/en/latest/api-intro.html#mailgun-regions).

## tag

Tag string. Comma-separated string list or arrayref of strings.

## testmode

Enables sending in test mode. `'yes'` or `'no'`.

## tracking

Toggles tracking. `'yes'` or `'no'`.

## tracking\_clicks

Toggles clicks tracking. `'yes'`, `'no'` or `'html_only'`.

## tracking\_opens

Toggles open tracking. `'yes'` or `'no'`.

# MIME HEADERS

The `o:` options above can also be specified using the `X-Mailgun-` headers
listed here [https://documentation.mailgun.com/user\_manual.html#sending-via-smtp](https://documentation.mailgun.com/user_manual.html#sending-via-smtp)

If a single-valued option is specified in both the options and the headers,
experimentation shows the header takes precedence. This doesn't seem to be
documented, so don't rely on this behaviour.

Multi-valued options use both the options and the headers.

# ENVIRONMENT

The great strength of Email::Sender is that you don't need to hardcode your
transport, nor any of the options relating to that transport. They can all be
specified via environment variables.

To select the Mailgun transport, use `EMAIL_SENDER_TRANSPORT=Mailgun`.

To specify any of the attributes above, prepend the attribute name with
`EMAIL_SENDER_TRANSPORT_`.

- EMAIL\_SENDER\_TRANSPORT\_api\_key
- EMAIL\_SENDER\_TRANSPORT\_domain
- EMAIL\_SENDER\_TRANSPORT\_campaign
- EMAIL\_SENDER\_TRANSPORT\_deliverytime
- EMAIL\_SENDER\_TRANSPORT\_dkim
- EMAIL\_SENDER\_TRANSPORT\_region
- EMAIL\_SENDER\_TRANSPORT\_tag
- EMAIL\_SENDER\_TRANSPORT\_testmode
- EMAIL\_SENDER\_TRANSPORT\_tracking
- EMAIL\_SENDER\_TRANSPORT\_tracking\_clicks
- EMAIL\_SENDER\_TRANSPORT\_tracking\_opens

# LICENSE

Copyright (C) Stephen Thirlwall.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Stephen Thirlwall <sdt@cpan.org>
