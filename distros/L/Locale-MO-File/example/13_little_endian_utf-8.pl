#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use charnames ':full';

our $VERSION = 0;

require Data::Dumper; # to visualize output only
require Locale::MO::File;

binmode STDOUT, ':encoding(UTF-8)';
my $filename = '13_little_endian_utf-8.mo';

# The content of the "messages" array reference is first sorted and then written.
# The transferred "messages" array reference remains unchanged.
# A given file handle is used but not closed.
# This example shows you how to handle encoding and newline.
Locale::MO::File
    ->new(
        filename => $filename,
        encoding => 'UTF-8', # encode from unicode chars to UTF-8 bytes
        newline  => "\r\n",  # change all newlines in messages to CRLF
        messages => [
            {
                msgid  => q{},
                msgstr => <<'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
EOT
            },
            {
                msgid  => "11\N{LATIN SMALL LETTER E WITH DIAERESIS}",
                msgstr => "12\N{LATIN SMALL LETTER U WITH DIAERESIS}",
            },
            {
                msgctxt => "21\N{LATIN SMALL LETTER A WITH DIAERESIS}",
                msgid   => "22\N{LATIN SMALL LETTER E WITH DIAERESIS}",
                msgstr  => "23\N{LATIN SMALL LETTER U WITH DIAERESIS}",
            },
            {
                msgid         => "31\N{LATIN SMALL LETTER E WITH DIAERESIS}",
                msgid_plural  => "32\N{LATIN SMALL LETTER O WITH DIAERESIS}",
                msgstr_plural => [
                    "33\N{LATIN SMALL LETTER U WITH DIAERESIS}",
                    "34\N{LATIN SMALL LETTER U WITH DIAERESIS}",
                ],
            },
            {
                msgctxt       => "41\N{LATIN SMALL LETTER A WITH DIAERESIS}",
                msgid         => "42\N{LATIN SMALL LETTER E WITH DIAERESIS}",
                msgid_plural  => "43\N{LATIN SMALL LETTER O WITH DIAERESIS}",
                msgstr_plural => [
                    "44\N{LATIN SMALL LETTER U WITH DIAERESIS}",
                    "45\N{LATIN SMALL LETTER U WITH DIAERESIS}",
                ],
            },
        ],
    )
    ->write_file;

my $messages_result = Locale::MO::File
    ->new(
        filename => $filename,
        encoding => 'UTF-8', # decode from UTF-8 bytes to unicode chars
        newline  => "\n",    # change all newlines in messages to \n
    )
    ->read_file
    ->get_messages;

() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new([$messages_result], [qw(messages_result)])
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Useperl(1)
    ->Dump;

# $Id: 12_build_header.pl 513 2010-07-29 15:16:57Z steffenw $

__END__

Output:

$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgid => '11\xc3\xab',
    msgstr => '12\xc3\xbc'
  },
  {
    msgctxt => '21\xc3\xa4',
    msgid => '22\xc3\xab',
    msgstr => '23\xc3\xbc'
  },
  {
    msgid => '31\xc3\xab',
    msgid_plural => '32\xc3\xb6',
    msgstr_plural => [
      '33\xc3\xbc',
      '34\xc3\xbc'
    ]
  },
  {
    msgctxt => '41\xc3\xa4',
    msgid => '42\xc3\xab',
    msgid_plural => '43\xc3\xb6',
    msgstr_plural => [
      '44\xc3\xbc',
      '45\xc3\xbc'
    ]
  }
];
