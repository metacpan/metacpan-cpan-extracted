use strict;
use utf8;

use Test::More tests => 1 + 1 + 3 + 1 * 2;

BEGIN {
    use_ok('Email::MIME::RFC2047::MailboxList');
};

my @parse_tests = (
    '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>',
    [
        { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
        { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
    ],
);

for (my $i=0; $i<@parse_tests; $i+=2) {
    my ($string, $expect) = ($parse_tests[$i], $parse_tests[$i+1]);

    my $mailbox = Email::MIME::RFC2047::MailboxList->parse($string);
    is_deeply([ $mailbox->items ], $expect, "parse $string");
}

my @error_tests = (
    'a@a.de, lkj, b@b.de',
    qr/invalid mailbox/,
    'name@example.com, name <xxx>',
    qr/invalid mailbox/,
    'name@example.com, group: a@a.de',
    qr/invalid mailbox/,
);

for (my $i = 0; $i < @error_tests; $i += 2) {
    my ($string, $expect) = ($error_tests[$i], $error_tests[$i+1]);

    eval {
        Email::MIME::RFC2047::MailboxList->parse($string)
    };
    like($@, $expect, 'parse error');
}

my @format_tests = (
    [
        { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
        { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
    ],
    'Keld =?ISO-8859-1?Q?J=f8rn?= Simonsen <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=e9?= Pirard <PIRARD@vm1.ulg.ac.be>',
);

for (my $i = 0; $i < @format_tests; $i += 2) {
    my ($spec, $expect) = ($format_tests[$i], $format_tests[$i+1]);

    my ($encoding, $method);
    if ($expect =~ /=?([\w-]+)\?([BQ])\?/) {
        ($encoding, $method) = ($1, $2);
    }
    my $encoder = Email::MIME::RFC2047::Encoder->new(
        encoding => $encoding,
        method   => $method,
    );

    my $mailbox_list = Email::MIME::RFC2047::MailboxList->new();

    for my $mailbox_spec (@$spec) {
        my $mailbox = Email::MIME::RFC2047::Mailbox->new(
            $mailbox_spec
        );
        $mailbox_list->push($mailbox);
    }

    my $string = $mailbox_list->format($encoder);
    is($string, $expect, "format $expect");

    my $round_trip = Email::MIME::RFC2047::MailboxList->parse($string);
    is_deeply([ $round_trip->items ], $spec, "round trip $expect");
}

