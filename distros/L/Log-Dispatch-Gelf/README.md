[![Build Status](https://travis-ci.org/avast/log-dispatch-gelf.svg?branch=master)](https://travis-ci.org/avast/log-dispatch-gelf)
# NAME

Log::Dispatch::Gelf - Log::Dispatch plugin for Graylog's GELF format.

# SYNOPSIS

    use Log::Dispatch;

    my $sender = ... # e.g. RabbitMQ queue.
    my $log = Log::Dispatch->new(
        outputs => [ 
            #some custom sender
            [
                'Gelf',
                min_level         => 'debug',
                additional_fields => { facility => __FILE__ },
                send_sub          => sub { $sender->send($_[0]) },
            ],
            #or send to graylog via TCP/UDP socket
            [
                'Gelf',
                min_level         => 'debug',
                additional_fields => { facility => __FILE__ },
                socket            => {
                    host     => 'graylog.server',
                    port     => 21234,
                    protocol => 'tcp',
                }
            ]
        ],
    );
    $log->info('It works');

    $log->log(
        level             => 'info',
        message           => "It works\nMore details.",
        additional_fields => { test => 1 }
    );

# DESCRIPTION

Log::Dispatch::Gelf is a Log::Dispatch plugin which formats the log message
according to Graylog's GELF Format version 1.1. It supports sending via a
socket (TCP or UDP) or a user provided sender.

# CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in [Log::Dispatch::Output](https://metacpan.org/pod/Log::Dispatch::Output):

- additional\_fields

    optional hashref of additional fields of the gelf message (no need to prefix
    them with \_, the prefixing is done automatically).

- chunked

    optional scalar. An integer specifying the chunk size or the special
    string values 'lan' or 'wan' corresponding to 8154 or 1420 respectively.
    A zero chunk size means no chunking will be applied.

    Chunking is only applicable to UDP connections.

- compress

    optional scalar. If a true value the message will be gzipped with
    IO::Compress::Gzip.

- send\_sub

    mandatory sub for sending the message to graylog. It is triggered after the
    gelf message is generated.

- socket

    optional hashref create tcp or udp (default behavior) socket and set
    `send_sub` to sending via socket

# METHODS

## $log->log( level => $, message => $, additional\_fields => \\% )

In addition to the corresponding method in [Log::Dispatch::Output](https://metacpan.org/pod/Log::Dispatch::Output) this
subclassed method takes an optional hashref of additional\_fields for the
gelf message. As in the corresponding parameter on the constructor there is
no need to prefix them with an \_. If the same key appears in both the
constructor's and method's additional\_fields then the method's value will
take precedence overriding the constructor's value for the current call.

The subclassed log method is still called with all parameters passed on.

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Miroslav Tynovsky <tynovsky@avast.com>
