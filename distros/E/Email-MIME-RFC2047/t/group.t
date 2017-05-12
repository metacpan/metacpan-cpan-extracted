use strict;
use utf8;

use Test::More tests => 1 + 2 + 2 + 2 * 3;

BEGIN {
    use_ok('Email::MIME::RFC2047::Address');
};

my @parse_tests = (
    '"Group 1 (Test)": =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>;',
    {
        name => 'Group 1 (Test)',
        mailbox_list => [
            { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
            { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
        ],
    },
    'undisclosed-recipients:;',
    {
        name => 'undisclosed-recipients',
        mailbox_list => [],
    },
);

for (my $i=0; $i<@parse_tests; $i+=2) {
    my ($string, $expect) = ($parse_tests[$i], $parse_tests[$i+1]);

    my $address = Email::MIME::RFC2047::Address->parse($string);
    is_deeply($address, $expect, "parse address $string");
}

my @error_tests = (
    'group: lkj',
    qr/incomplete or missing mailbox/,
    'group: name@example.com, name <xxx>',
    qr/invalid mailbox/,
);

for (my $i = 0; $i < @error_tests; $i += 2) {
    my ($string, $expect) = ($error_tests[$i], $error_tests[$i+1]);

    eval {
        Email::MIME::RFC2047::Address->parse($string)
    };
    like($@, $expect, 'parse error');
}

my @format_tests = (
    {
        name => 'Group 1 (Test)',
        mailbox_list => [
            { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
            { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
        ],
    },
    '"Group 1 (Test)": Keld =?ISO-8859-1?Q?J=f8rn?= Simonsen <keld@dkuug.dk>, =?ISO-8859-1?Q?Andr=e9?= Pirard <PIRARD@vm1.ulg.ac.be>;',
    {
        name => 'undisclosed-recipients',
        mailbox_list => [],
    },
    'undisclosed-recipients: ;',
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

    my $mailbox_list = Email::MIME::RFC2047::MailboxList->new;

    for my $mailbox_spec (@{ $spec->{mailbox_list} }) {
        my $mailbox = Email::MIME::RFC2047::Mailbox->new(
            $mailbox_spec
        );
        $mailbox_list->push($mailbox);
    }

    my $group = Email::MIME::RFC2047::Group->new({
        name         => $spec->{name},
        mailbox_list => $mailbox_list,
    });

    my $string = $group->format($encoder);
    is($string, $expect, "format $expect");

    my $round_trip = Email::MIME::RFC2047::Address->parse($string);
    is($round_trip->name, $spec->{name}, "round trip name $expect");
    is_deeply($round_trip->mailbox_list, $spec->{mailbox_list},
              "round trip mailbox_list $expect");
}

