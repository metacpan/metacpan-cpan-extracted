# NAME

Mail::MBX - Read MBX mailbox files

# SYNOPSIS

    use Mail::MBX ();

    my $mbx = Mail::MBX->open('mailbox.mbx');

    while (my $message = $mbx->message) {
        while ($message->read(my $buf, 4096)) {
            # Do something with the message body
        }
    }

    $mbx->close;

# DESCRIPTION

`Mail::MBX` provides a reasonable way to read mailboxes in the MBX format, as
used by the University of Washington's UW-IMAP reference implementation.  At
present, only sequential reading is supported, though this is ideal for mailbox
format conversion tasks.

# OPENING MAILBOXES

- `Mail::MBX->open(_$file_)`

    Open an MBX mailbox file, returning a new `Mail::MBX` object.

- `$mbx->close()`

    Close the current mailbox object.

- `$mbx->message()`

    Return the current MBX message, in the form of a `[Mail::MBX::Message](https://metacpan.org/pod/Mail::MBX::Message)`
    object, and move the internal file handle to the next message.

    See `[Mail::MBX::Message](https://metacpan.org/pod/Mail::MBX::Message)` for further details on accessing message contents.

# AUTHOR

Written by Xan Tronix <xan@cpan.org>

# COPYRIGHT

Copyright (c) 2014 cPanel, Inc.  Distributed under the terms of the MIT license.
