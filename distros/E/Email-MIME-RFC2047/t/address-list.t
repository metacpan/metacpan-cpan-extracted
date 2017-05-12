use strict;
use utf8;

use Test::More tests => 1 + 4 + 2 + 3 * 2;

BEGIN {
    use_ok('Email::MIME::RFC2047::AddressList');
};

my @parse_tests = (
    '"Group 1 (Test)": =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>;, wellnhofer@aevum.de',
    [
        {
            name => 'Group 1 (Test)',
            mailbox_list => [
                { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
                { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
            ],
        },
        {
            address => 'wellnhofer@aevum.de',
        },
    ],
    'Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>',
    [
        { name => 'Mary Smith', address => 'mary@x.test' },
        { address => 'jdoe@example.org' },
        { name => 'Who?', address => 'one@y.test' },
    ],
    '<boss@nil.test>, "Giant; \"Big\" Box" <sysservices@example.net>',
    [
        { address => 'boss@nil.test' },
        { name => 'Giant; "Big" Box', address => 'sysservices@example.net' },
    ],
    "<o'reilly\@example.com>",
    [
        { address => "o'reilly\@example.com" },
    ],
);

for (my $i = 0; $i < @parse_tests; $i += 2) {
    my ($string, $expect) = ($parse_tests[$i], $parse_tests[$i+1]);

    my $mailbox = Email::MIME::RFC2047::AddressList->parse($string);
    is_deeply($mailbox, $expect, "parse $string");
}

my @error_tests = (
    'c@c.de, Name',
    qr/incomplete or missing address/,
    'c@c.de, <address>',
    qr/invalid address/,
);

for (my $i = 0; $i < @error_tests; $i += 2) {
    my ($string, $expect) = ($error_tests[$i], $error_tests[$i+1]);

    eval {
        Email::MIME::RFC2047::AddressList->parse($string)
    };
    like($@, $expect, 'parse error');
}

my @format_tests = (
    [
        {
            name => 'Group 1 (Test)',
            mailbox_list => [
                { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
                { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
            ],
        },
        {
            address => 'wellnhofer@aevum.de',
        },
    ],
    '"Group 1 (Test)": Keld =?ISO-8859-1?Q?J=f8rn?= Simonsen <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=e9?= Pirard <PIRARD@vm1.ulg.ac.be>;, wellnhofer@aevum.de',
    [
        { name => 'Mary Smith', address => 'mary@x.test' },
        { address => 'jdoe@example.org' },
        { name => 'Who?', address => 'one@y.test' },
    ],
    'Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>',
    [
        { address => 'boss@nil.test' },
        { name => 'Giant; "Big" Box', address => 'sysservices@example.net' },
    ],
    'boss@nil.test, "Giant; \"Big\" Box" <sysservices@example.net>',
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

    my $address_list = Email::MIME::RFC2047::AddressList->new();

    for my $address_spec (@$spec) {
        my $address;

        if ($address_spec->{mailbox_list}) {
            my $mailbox_list = Email::MIME::RFC2047::MailboxList->new;

            for my $mailbox_spec (@{ $address_spec->{mailbox_list} }) {
                my $mailbox = Email::MIME::RFC2047::Mailbox->new(
                    $mailbox_spec
                );
                $mailbox_list->push($mailbox);
            }

            $address = Email::MIME::RFC2047::Group->new(
                name         => $address_spec->{name},
                mailbox_list => $mailbox_list,
            );
        }
        else {
            $address = Email::MIME::RFC2047::Mailbox->new($address_spec);
        }
        $address_list->push($address);
    }

    my $string = $address_list->format($encoder);
    is($string, $expect, "format $expect");

    my $round_trip = Email::MIME::RFC2047::AddressList->parse($string);
    is_deeply([ $round_trip->items ], $spec, "round trip $expect");
}

