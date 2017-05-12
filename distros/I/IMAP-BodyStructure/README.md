# NAME

IMAP::BodyStructure - IMAP4-compatible BODYSTRUCTURE and ENVELOPE parser

# SYNOPSIS

    use IMAP::BodyStructure;

    # $imap is a low-level IMAP-client with an ability to fetch items
    # by message uids

    my $bs = new IMAP::BodyStructure
        $imap->imap_fetch($msg_uid,
                'BODYSTRUCTURE', 1)->[0]->{BODYSTRUCTURE};

    print "[UID:$msg_uid] message is in Russian. Sure.\n"
        if $bs->charset =~ /(?:koi8-r|windows-1251)/i;

    my $part = $bs->part_at('1.3');
    $part->type =~ m#^image/#
        and print "The 3rd part is an image named \""
            . $part->filename . "\"\n";

# DESCRIPTION

An IMAP4-compatible IMAP server MUST include a full MIME-parser which
parses the messages inside IMAP mailboxes and is accessible via
BODYSTRUCTURE fetch item. This module provides a Perl interface to
parse the output of IMAP4 MIME-parser. Hope no one will have problems
with parsing this doc.

It is a rather straightforward `m/\G.../gc`-style parser and is
therefore much, much faster then the venerable [Mail::IMAPClient::BodyStructure](https://metacpan.org/pod/Mail::IMAPClient::BodyStructure)
which is based on a [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent) grammar. I believe it is also
more correct when parsing nested multipart `message/rfc822` parts. See
testsuite if interested.

I'd also like to emphasize that _this module does not contain IMAP4
client!_ You will need to employ one from CPAN, there are many. A
section with examples of getting to a BODYSTRUCTURE fetch item with
various Perl IMAP clients available on CPAN would greatly
enhance this document.

# INTERFACE

## METHODS

- new($)

    The constructor does most of the work here. It initializes the
    hierarchial data structure representing all the message parts and their
    properties. It takes one argument which should be a string returned
    by IMAP server in reply to a FETCH command with BODYSTRUCTURE item.

    All the parts on all the levels are represented by IMAP::BodyStructure
    objects and that enables the uniform access to them. It is a direct
    implementation of the Composite Design Pattern.

- type()

    Returns the MIME type of the part. Expect something like `text/plain`
    or `application/octet-stream`.

- encoding()

    Returns the MIME encoding of the part. This is usually one of '7bit',
    '8bit', 'base64' or 'quoted-printable'.

- size()

    Returns the size of the part in octets. It is _NOT_ the size of the
    data in the part, which may be encoded as quoted-printable leaving us
    without an obvious method of calculating the exact size of original
    data.

- disp()

    Returns the content-disposition of the part. One of 'inline' or
    'attachment', usually. Defaults to inline, but you should remember
    that if there IS a disposition but you cannot recognize it than act as
    if it's 'attachment'. And use case-insensitive comparisons.

- charset()

    Returns the charset of the part OR the charset of the first nested
    part. This looks like a good heuristic really. Charset is something
    resembling 'UTF-8', 'US-ASCII', 'ISO-8859-13' or 'KOI8-R'. The standard
    does not say it should be uppercase, by the way.

    Can be undefined.

- filename()

    Returns the filename specified as a part of Content-Disposition
    header.

    Can be undefined.

- description()

    Returns the description of the part.

- parts(;$)

    This sub acts differently depending on whether you pass it an
    argument or not.

    Without any arguments it returns a list of parts in list context and
    the number in scalar context.

    Specifying a scalar argument allows you to get an individual part with
    that index.

    _Remember, all the parts I talk here about are not actual message data, files
    etc. but IMAP::BodyStructure objects containing information about the
    message parts which was extracted from parsing BODYSTRUCTURE IMAP
    response!_

- part\_at($)

    This method returns a message part by its path. A path to a part in
    the hierarchy is a dot-separated string of part indices. See ["SYNOPSIS"](#synopsis) for
    an example. A nested `message/rfc822` does not add a hierarchy level
    UNLESS it is a single part of another `message/rfc822` part (with no
    `multipart/*` levels in between).  Instead, it has an additional
    `.TEXT` part which refers to the internal IMAP::BodyStructure object.
    Look, here is an outline of an example message structure with part
    paths alongside each part.

        multipart/mixed                   1
            text/plain                    1.1
            application/msword            1.2
            message/rfc822                1.3
                multipart/alternative     1.3.TEXT
                    text/plain            1.3.1
                    multipart/related     1.3.2
                        text/html         1.3.2.1
                        image/png         1.3.2.2
                        image/png         1.3.2.3

    This is a text email with two attachments, one being an MS Word document,
    and the other is itself a message (probably a forward) which is composed in a
    graphical MUA and contains two alternative representations, one
    plain text fallback and one HTML with images (bundled as a
    `multipart/related`).

    Another one with several levels of `message/rfc822`. This one is hard
    to compose in a modern MUA, however.

        multipart/mixed                   1
            text/plain                    1.1
            message/rfc822                1.2
                message/rfc822            1.2.TEXT
                    text/plain            1.2.1

- part\_path()

    Returns the part path to the current part.

## DATA MEMBERS

These are additional pieces of information returned by IMAP server and
parsed. They are rarely used, though (and rarely defined too, btw), so
I chose not to provide access methods for them.

- params

    This is a hashref of MIME parameters. The only interesting param is
    charset and there's a shortcut method for it.

- lang

    Content language.

- loc

    Content location.

- cid

    Content ID.

- md5

    Content MD5. No one seems to bother with calculating and it is usually
    undefined.

**cid** and **md5** members exist only in singlepart parts.

- get\_enveleope($)

    Parses a string into IMAP::BodyStructure::Envelope object. See below.

## IMAP::BodyStructure::Envelope CLASS

Every message on an IMAP server has an envelope. You can get it
using ENVELOPE fetch item or, and this is relevant, from BODYSTRUCTURE
response in case there are some nested messages (parts with type of
`message/rfc822`). So, if we have a part with such a type then the
corresponding IMAP::BodyStructure object always has
**envelope** data member which is, in turn, an object of
IMAP::BodyStructure::Envelope.

You can of course use this satellite class on its own, this is very
useful when generating meaningful message lists in IMAP folders.

## METHODS

- new($)

    The constructor create Envelope object from string which should be an
    IMAP server respone to a fetch with ENVELOPE item or a substring of
    BODYSTRUCTURE response for a message with message/rfc822 parts inside.

## DATA MEMBERS

- date

    Date of the message as specified in the envelope. Not the IMAP
    INTERNALDATE, be careful!

- subject

    Subject of the message, may be RFC2047 encoded, of course.

- message\_id
- in\_reply\_to

    Message-IDs of the current message and the message in reply to which
    this one was composed.

- to, from, cc, bcc, sender, reply\_to

    These are the so called address-lists or just arrays of addresses.
    Remember, a message may be addressed to lots of people.

    Each address is a hash of four elements:

    - name

        The informal part, "A.U.Thor" from "A.U.Thor, &lt;a.u.thor@somewhere.com>"

    - sroute

        Source-routing information, not used. (By the way, IMAP4r1 spec was
        born after the last email address with sroute passed away.)

    - account

        The part before @.

    - host

        The part after @.

    - full

        The full address for display purposes.

# EXAMPLES

The usual way to determine if an email has some files attached (in
order to display a cute little scrap in the message list, e.g.) is to
check whether the message is multipart or not. This method tends to
give many false positives on multipart/alternative messages with a
HTML and plaintext parts and no files. The following sub tries to be a
little smarter.

    sub _has_files {
        my $bs = shift;

        return 1 if $bs->{type} !~ m#^(?:text|multipart)/#;

        if ($bs->{type} =~ m#^multipart/#) {
            foreach my $part (@{$bs->{parts}}) {
                return 1 if _has_files($part);
            }
        }

        return 0;
    }

This snippet selects a rendering routine for a message part.

    foreach (
        [ qr{text/plain}            => \&_render_textplain  ],
        [ qr{text/html}             => \&_render_texthtml   ],
        [ qr{multipart/alternative} => \&_render_alt        ],
        [ qr{multipart/mixed}       => \&_render_mixed      ],
        [ qr{multipart/related}     => \&_render_related    ],
        [ qr{image/}                => \&_render_image      ],
        [ qr{message/rfc822}        => \&_render_rfc822     ],
        [ qr{multipart/parallel}    => \&_render_mixed      ],
        [ qr{multipart/report}      => \&_render_mixed      ],
        [ qr{multipart/}            => \&_render_mixed      ],
        [ qr{text/}                 => \&_render_textplain  ],
        [ qr{message/delivery-status}=> \&_render_textplain ],
    ) {
        $bs->type =~ $_->[0]
            and $renderer = $_->[1]
            and last;
    }

# BUGS

Shouldn't be any, as this is a simple parser of a standard structure.

# AUTHOR

Alex Kapranoff &lt;alex@kapranoff.ru>

# ACKNOWLEDGMENTS

Jonas Liljegren contributed support for multivalued "lang" items.

# COPYRIGHT AND LICENSE

This software is copyright (C) 2015 by Alex Kapranoff &lt;alex@kapranoff.ru>.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

# SEE ALSO

[Mail::IMAPClient](https://metacpan.org/pod/Mail::IMAPClient), [Net::IMAP::Simple](https://metacpan.org/pod/Net::IMAP::Simple), RFC3501, RFC2045, RFC2046.
