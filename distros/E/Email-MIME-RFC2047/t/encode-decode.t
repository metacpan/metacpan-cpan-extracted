use strict;
use utf8;

use Test::More tests => 4 + 13 * 4;

BEGIN {
    use_ok('Email::MIME::RFC2047::Encoder');
    use_ok('Email::MIME::RFC2047::Decoder');
};

my $encoder = Email::MIME::RFC2047::Encoder->new();
ok(defined($encoder), 'new');

my $decoder = Email::MIME::RFC2047::Decoder->new();
ok(defined($decoder), 'new');

my @tests = (
    # white space stripping
    " \t\r\nte-xt\n\r \t", 'te-xt', undef,
    # encoding of encoded words
    '=?utf-8?Q?C=c3=a4sar?=', '=?utf-8?Q?=3d=3futf-8=3fQ=3fC=3dc3=3da4sar=3f=3d?=', undef,
    # quoted strings
    'te-xt te;xt', undef, '"te-xt te;xt"',
    'text(text) text, text.', undef, '"text(text) text, text."',
    'text"text\ntext\n"', undef, '"text\"text\\\\ntext\\\\n\""',
    # encoded words
    'Anton  :Berta Cäsar',  'Anton :Berta =?utf-8?Q?C=c3=a4sar?=', '"Anton :Berta" =?utf-8?Q?C=c3=a4sar?=',
    ':Anton Cäsar  Berta',  ':Anton =?utf-8?Q?C=c3=a4sar?= Berta', '":Anton" =?utf-8?Q?C=c3=a4sar?= Berta',
    'Cäsar  Anton  :Berta', '=?utf-8?Q?C=c3=a4sar?= Anton :Berta', '=?utf-8?Q?C=c3=a4sar?= "Anton :Berta"',
    # encoded word splitting
    'ö ö ö ööööööö',  '=?utf-8?Q?=c3=b6_=c3=b6_=c3=b6_=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6?=', undef,
    'ö ö ö ö öööööö', '=?utf-8?Q?=c3=b6_=c3=b6_=c3=b6_=c3=b6_=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6?= =?utf-8?Q?=c3=b6?=', undef,
    # space at boundaries
    'ö ö öööööööö ö',  '=?utf-8?Q?=c3=b6_=c3=b6_=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6_?= =?utf-8?Q?=c3=b6?=', undef,
    'ö ö ö ööööööö ö', '=?utf-8?Q?=c3=b6_=c3=b6_=c3=b6_=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6=c3=b6?= =?utf-8?Q?_=c3=b6?=', undef,
    # supplementary plane
    "\x{1F44D}", '=?utf-8?Q?=f0=9f=91=8d?=', undef,
);

for (my $i=0; $i<@tests; $i+=3) {
    my ($string, $expect_text, $expect_phrase) =
        ($tests[$i], $tests[$i+1], $tests[$i+2]);
    $expect_text = $string if !defined($expect_text);
    $expect_phrase = $expect_text if !defined($expect_phrase);

    my $decoded;
    my $normalized = $string;
    $normalized =~ s/[ \t\r\n]+/ /g;
    $normalized =~ s/^[ \t\r\n]+//;
    $normalized =~ s/[ \t\r\n]+\z//;

    my $text = $encoder->encode_text($string);
    is($text, $expect_text, "encode_text $string");
    $decoded = $decoder->decode_text($text);
    is($decoded, $normalized, "decode_text $text");

    my $phrase = $encoder->encode_phrase($string);
    is($phrase, $expect_phrase, "encode_phrase $string");
    $decoded = $decoder->decode_phrase($phrase);
    is($decoded, $normalized, "decode_phrase $phrase");
}

