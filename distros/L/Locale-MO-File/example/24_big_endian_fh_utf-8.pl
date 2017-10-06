#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use charnames ':full';

our $VERSION = 0;

use Carp qw(confess);
require Data::Dumper; # to visualize output only
use English qw(-no_match_vars $OS_ERROR);
use IO::File qw(SEEK_SET);
require Locale::MO::File;

binmode STDOUT, ':encoding(UTF-8)';
my $filename = '24_big_endian_fh_utf-8.mo';

my $file_handle = IO::File->new($filename, '+> :raw')
    or confess "Can not open $filename\n$OS_ERROR";

# The content of the "messages" array reference is first sorted and then written.
# The transferred "messages" array reference remains unchanged.
# A given file handle is used but not closed.
# This example shows you how to handle encoding and newline.
Locale::MO::File
    ->new(
        filename      => $filename,
        file_handle   => $file_handle,
        encoding      => 'UTF-8', # encode from unicode chars to UTF-8 bytes
        newline       => "\r\n",  # change all newlines in messages to CRLF
        is_big_endian => 1,
        messages      => [
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

$file_handle->seek(0, SEEK_SET)
    or confess "Can not seek $filename\n$OS_ERROR";

my $messages_result = Locale::MO::File
    ->new(
        filename    => $filename,
        file_handle => $file_handle,
        encoding    => 'UTF-8', # encode from unicode chars to UTF-8 bytes
        newline     => "\n",    # change all newlines in messages to \n
    )
    ->read_file
    ->get_messages;

$file_handle->close
    or confess "Can not close $filename\n$OS_ERROR";

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
