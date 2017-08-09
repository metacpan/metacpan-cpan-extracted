package Email::MIME::RFC2047;
$Email::MIME::RFC2047::VERSION = '0.97';
use strict;
use warnings;

# ABSTRACT: Correct handling of non-ASCII MIME headers

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::RFC2047 - Correct handling of non-ASCII MIME headers

=head1 VERSION

version 0.97

=head1 SYNOPSIS

    use Email::MIME;

    # create headers with non-ASCII chars

    use Email::MIME::RFC2047::Encoder;
    use Email::MIME::RFC2047::Mailbox;

    my $email = Email::MIME->create();
    my $encoder = Email::MIME::RFC2047::Encoder->new(
        encoding => 'utf-8',
        method   => 'Q',
    );

    $email->header_set(
        Subject => $encoder->encode_text($non_ascii_subject)
    );

    my $to_address = Email::MIME::RFC2047::Mailbox->new(
        name    => $non_ascii_name,
        address => $email_address,
    );
    $email->header_set(To => $to_address->format($encoder));

    # parse headers with non-ASCII chars

    use Email::MIME::RFC2047::Decoder;

    my $email = Email::MIME->new($message);
    my $decoder = Email::MIME::RFC2047::Decoder->new();

    my $subject = $decoder->decode_text($email->header('Subject'));

    my $to_address = Email::MIME::RFC2047::AddressList->parse(
        $email->header('To')
    );

=head1 DESCRIPTION

This distribution tries to provide a correct and usable implementation of
RFC 2047 "MIME Part Three: Message Header Extensions for Non-ASCII Text".
The L<Encode::MIME::Header> module also provides RFC 2047 encoding and
decoding but a useful API should handle the different situations where
RFC 2047 encoded headers are used. Section 5 of the RFC defines three use
cases for 'encoded-words':

(1) As a replacement of 'text' tokens, for example in a Subject header

(2) In comments

(3) As a replacement for a 'word' entity within a 'phrase', for example,
one that precedes an address in a From, To, or Cc header

Especially, case (3) requires the handling of quoted strings as defined by
RFC 2822. So the encoding and decoding modules provide separate methods for
the handling of text and phrases.

Since parsing and encoding of phrases makes up the bulk of handling address
headers like From, To or Cc, additional modules to handle these headers are
also provided.

See L<Email::MIME::RFC2047::Encoder> for encoding.

See L<Email::MIME::RFC2047::Decoder> for decoding.

See L<Email::MIME::RFC2047::Mailbox> for handling of Sender headers.

See L<Email::MIME::RFC2047::MailboxList> for handling of From headers.

See L<Email::MIME::RFC2047::AddressList> for handling of Reply-To, To, Cc
and Bcc headers.

See L<Email::MIME::RFC2047::Group> for handling groups of mailboxes.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
