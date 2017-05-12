use strict;
use utf8;

use Test::More tests => 2 + 7 * 2 + 2 + 4 * 3;

BEGIN {
    use_ok('Email::MIME::RFC2047::Mailbox');
    use_ok('Email::MIME::RFC2047::Address');
};

my @parse_tests = (
    '"Nick Wellnhofer" <wellnhofer@aevum.de>',
    { name => 'Nick Wellnhofer', address => 'wellnhofer@aevum.de' },
    'Nick Wellnhofer <wellnhofer@aevum.de>',
    { name => 'Nick Wellnhofer', address => 'wellnhofer@aevum.de' },
    '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
    { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
    '=?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>',
    { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
    '"Nick Wellnhofer" (This (is) (a) comment) <wellnhofer@aevum.de>',
    { name => 'Nick Wellnhofer', address => 'wellnhofer@aevum.de' },
    '"Nick" (comment) "Wellnhofer" <wellnhofer@aevum.de>',
    { name => 'Nick Wellnhofer', address => 'wellnhofer@aevum.de' },
    'wellnhofer@aevum.de',
    { address => 'wellnhofer@aevum.de' },
);

for (my $i = 0; $i < @parse_tests; $i += 2) {
    my ($string, $expect) = ($parse_tests[$i], $parse_tests[$i+1]);

    my $mailbox = Email::MIME::RFC2047::Mailbox->parse($string);
    is_deeply($mailbox, $expect, "parse mailbox $string");

    my $address = Email::MIME::RFC2047::Address->parse($string);
    is_deeply($address, $expect, "parse address $string");
}

my @error_tests = (
    'Name',
    qr/incomplete or missing mailbox/,
    '<address>',
    qr/invalid mailbox/,
);

for (my $i = 0; $i < @error_tests; $i += 2) {
    my ($string, $expect) = ($error_tests[$i], $error_tests[$i+1]);

    eval {
        Email::MIME::RFC2047::Mailbox->parse($string)
    };
    like($@, $expect, 'parse error');
}

my @format_tests = (
    { name => 'Nick Wellnhofer', address => 'wellnhofer@aevum.de' },
    'Nick Wellnhofer <wellnhofer@aevum.de>',
    { name => 'Keld Jørn Simonsen', address => 'keld@dkuug.dk' },
    'Keld =?ISO-8859-1?Q?J=f8rn?= Simonsen <keld@dkuug.dk>',
    { name => 'André Pirard', address => 'PIRARD@vm1.ulg.ac.be' },
    '=?ISO-8859-1?Q?Andr=e9?= Pirard <PIRARD@vm1.ulg.ac.be>',
    { address => 'wellnhofer@aevum.de' },
    'wellnhofer@aevum.de',
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

    my $mailbox = Email::MIME::RFC2047::Mailbox->new($spec);
    my $string  = $mailbox->format($encoder);
    is($string, $expect, "format mailbox $expect");

    my $round_trip = Email::MIME::RFC2047::Address->parse($string);
    is($round_trip->name, $spec->{name}, "round trip name $expect");
    is($round_trip->address, $spec->{address}, "round trip address $expect");
}

