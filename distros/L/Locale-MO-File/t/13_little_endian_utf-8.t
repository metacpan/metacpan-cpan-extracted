#!perl -T

use strict;
use warnings;
use charnames ':full';

use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Hash::Util qw(lock_hash);
use IO::File qw(SEEK_SET);

use Test::More tests => 10;
use Test::NoWarnings;
use Test::Differences;
use Test::Exception;
use Test::HexDifferences;

BEGIN {
    require_ok 'Locale::MO::File';
}

my $CRLF = "\r\n";

my @messages = (
    {
        msgid  => q{},
        msgstr => <<'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1
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
);
for my $message (@messages) {
    lock_hash %{$message};
}

my $filename = '13_little_endian_utf-8.mo';

my @sorted_messages = (
    map {
        $_->[0];
    }
    sort {
        $a->[1] cmp $b->[1];
    }
    map {
        [
            $_,
            Locale::MO::File->new(filename => $filename)->_pack_message($_)->{msgid},
        ];
    } @messages
);

my $hex_dump = <<'EOT';
0000 : DE120495 : magic number
0004 : 00000000 : revision
0008 : 05000000 : number of strings
000C : 1C000000 : offset msgid
0010 : 44000000 : offset msgstr
0014 : 00000000 : hash size
0018 : 00000000 : hash offset
001C : 00 00 00 00 : ....
0020 : 6C 00 00 00 04 00 00 00 : l.......
0028 : 6D 00 00 00 09 00 00 00 : m.......
0030 : 72 00 00 00 09 00 00 00 : r.......
0038 : 7C 00 00 00 0E 00 00 00 : |.......
0040 : 86 00 00 00 65 00 00 00 : ....e...
0048 : 95 00 00 00 04 00 00 00 : ........
0050 : FB 00 00 00 04 00 00 00 : ........
0058 : 00 01 00 00 09 00 00 00 : ........
0060 : 05 01 00 00 09 00 00 00 : ........
0068 : 0F 01 00 00 00 31 31 C3 : .....11.
0070 : AB 00 32 31 C3 A4 04 32 : ..21...2
0078 : 32 C3 AB 00 33 31 C3 AB : 2...31..
0080 : 00 33 32 C3 B6 00 34 31 : .32...41
0088 : C3 A4 04 34 32 C3 AB 00 : ...42...
0090 : 34 33 C3 B6 00 4D 49 4D : 43...MIM
0098 : 45 2D 56 65 72 73 69 6F : E-Versio
00A0 : 6E 3A 20 31 2E 30 0D 0A : n:.1.0..
00A8 : 43 6F 6E 74 65 6E 74 2D : Content-
00B0 : 54 79 70 65 3A 20 74 65 : Type:.te
00B8 : 78 74 2F 70 6C 61 69 6E : xt/plain
00C0 : 3B 20 63 68 61 72 73 65 : ;.charse
00C8 : 74 3D 55 54 46 2D 38 0D : t=UTF-8.
00D0 : 0A 50 6C 75 72 61 6C 2D : .Plural-
00D8 : 46 6F 72 6D 73 3A 20 6E : Forms:.n
00E0 : 70 6C 75 72 61 6C 73 3D : plurals=
00E8 : 32 3B 20 70 6C 75 72 61 : 2;.plura
00F0 : 6C 3D 6E 20 21 3D 20 31 : l=n.!=.1
00F8 : 0D 0A 00 31 32 C3 BC 00 : ...12...
0100 : 32 33 C3 BC 00 33 33 C3 : 23...33.
0108 : BC 00 33 34 C3 BC 00 34 : ..34...4
0110 : 34 C3 BC 00 34 35 C3 BC : 4...45..
0118 : 00                      : .
EOT

# === file ===

lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_encoding('UTF-8');
        $mo->set_newline($CRLF);
        $mo->set_messages(\@messages);
        $mo->write_file;
    },
    "write mo file $filename";

ok
    -f $filename,
    "mo file $filename exists";

dumped_eq_dump_or_diff
    do {
        my $file_handle = IO::File->new($filename, '< :raw')
            or confess "Can not open $filename\n$OS_ERROR";
        local $INPUT_RECORD_SEPARATOR = ();
        <$file_handle>;
    },
    $hex_dump,
    { format => <<"EOT" },
%a : %N : magic number\n%1x%
%a : %N : revision\n%1x%
%a : %N : number of strings\n%1x%
%a : %N : offset msgid\n%1x%
%a : %N : offset msgstr\n%1x%
%a : %N : hash size\n%1x%
%a : %N : hash offset\n%1x%
%a : %4C : %d\n%1x%
%a : %8C : %d\n%*x%
EOT
    'compare hex dump';

my $messages_result;
lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_encoding('UTF-8');
        $mo->set_newline("\n");
        $mo->read_file;
        $messages_result = $mo->get_messages;
    },
    "read mo $filename";

eq_or_diff
    $messages_result,
    \@sorted_messages,
    'check messages';

# === file handle ===

$filename =~ s{[.]}{_fh.}xms;

my $file_handle = IO::File->new($filename, '+> :raw')
    or confess "Can not open $filename\n$OS_ERROR";

lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_file_handle($file_handle);
        $mo->set_encoding('UTF-8');
        $mo->set_newline($CRLF);
        $mo->set_messages(\@messages);
        $mo->write_file;
    },
    "using open file handle: write mo file $filename";

$file_handle->seek(0, SEEK_SET)
    or confess "Can not seek $filename\n$OS_ERROR";

$messages_result = ();
lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_file_handle($file_handle);
        $mo->set_encoding('UTF-8');
        $mo->set_newline("\n");
        $mo->read_file;
        $messages_result = $mo->get_messages;
    },
    "using open file handle: read mo file $filename";

eq_or_diff
    $messages_result,
    \@sorted_messages,
    'using open file handle: check messages';

$file_handle->close
    or confess "Can not close $filename\n$OS_ERROR";
