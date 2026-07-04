#!/usr/bin/perl -w

# Offline test: header values must not be able to inject extra SMTP
# headers via embedded CR/LF (header injection).  FakeSMTP runs a local
# throwaway SMTP server, captures the DATA section, and we inspect the
# headers that were actually put on the wire.

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use FakeSMTP qw(capture_sent);

subtest 'newline in a header value cannot inject a new header' => sub {
    my $data = capture_sent(
        From    => 'me@example.com',
        To      => 'you@example.com',
        Subject => "Hello\nBcc: attacker\@example.net",
        Message => "body\n",
    );

    my ($headers) = split /\r?\n\r?\n/, $data, 2;
    unlike $headers, qr/^Bcc:/im,
        'injected Bcc does not appear as a header line';
};

subtest 'legitimate multi-line message bodies are preserved' => sub {
    my $data = capture_sent(
        From    => 'me@example.com',
        To      => 'you@example.com',
        Subject => 'Plain subject',
        Message => "Line one\nLine two\n",
    );

    # Assert the separator between the lines survived (as SMTP CRLF), not
    # just that both lines appear somewhere: "Line oneLine two" must fail.
    my (undef, $body) = split /\r\n\r\n/, $data, 2;
    like $body, qr/\ALine one\r\nLine two\r\n/,
        'body lines preserved with their line breaks intact';
};

done_testing;
