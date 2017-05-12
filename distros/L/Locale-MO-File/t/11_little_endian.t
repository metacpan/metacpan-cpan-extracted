#!perl -T

use strict;
use warnings;

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

my @messages = (
    {
        msgid  => q{},
        msgstr => <<'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1
EOT
    },
    {
        msgid  => 'original',
        msgstr => 'translated',
    },
    {
        msgctxt => 'context',
        msgid   => 'c_original',
        msgstr  => 'c_translated',
    },
    {
        msgid         => 'o_singular',
        msgid_plural  => 'o_plural',
        msgstr_plural => [ qw(t_singular t_plural) ],
    },
    # shoud store a plural
    {
        msgid         => q{},
        msgid_plural  => 'o2_plural',
        msgstr_plural => [ qw(t2_singular) ],
    },
    # shoud store a plural
    {
        msgid         => q{},
        msgid_plural  => 'o2_plural',
        msgstr_plural => [ q{}, qw(t2_plural) ],
    },
    {
        msgctxt       => 'c_context',
        msgid         => 'c_o_singular',
        msgid_plural  => 'c_o_plural',
        msgstr_plural => [ qw(c_t_singular c_t_plural) ],
    },
);
for my $message (@messages) {
    lock_hash %{$message};
}

my $filename = '11_little_endian.mo';

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
0008 : 07000000 : number of strings
000C : 1C000000 : offset msgid
0010 : 54000000 : offset msgstr
0014 : 00000000 : hash size
0018 : 00000000 : hash offset
001C : 00 00 00 00 : ....
0020 : 8C 00 00 00 0A 00 00 00 : ........
0028 : 8D 00 00 00 0A 00 00 00 : ........
0030 : 98 00 00 00 21 00 00 00 : ....!...
0038 : A3 00 00 00 12 00 00 00 : ........
0040 : C5 00 00 00 13 00 00 00 : ........
0048 : D8 00 00 00 08 00 00 00 : ........
0050 : EC 00 00 00 67 00 00 00 : ....g...
0058 : F5 00 00 00 0B 00 00 00 : ........
0060 : 5D 01 00 00 0A 00 00 00 : ].......
0068 : 69 01 00 00 17 00 00 00 : i.......
0070 : 74 01 00 00 0C 00 00 00 : t.......
0078 : 8C 01 00 00 13 00 00 00 : ........
0080 : 99 01 00 00 0A 00 00 00 : ........
0088 : AD 01 00 00 00 00 6F 32 : ......o2
0090 : 5F 70 6C 75 72 61 6C 00 : _plural.
0098 : 00 6F 32 5F 70 6C 75 72 : .o2_plur
00A0 : 61 6C 00 63 5F 63 6F 6E : al.c_con
00A8 : 74 65 78 74 04 63 5F 6F : text.c_o
00B0 : 5F 73 69 6E 67 75 6C 61 : _singula
00B8 : 72 00 63 5F 6F 5F 70 6C : r.c_o_pl
00C0 : 75 72 61 6C 00 63 6F 6E : ural.con
00C8 : 74 65 78 74 04 63 5F 6F : text.c_o
00D0 : 72 69 67 69 6E 61 6C 00 : riginal.
00D8 : 6F 5F 73 69 6E 67 75 6C : o_singul
00E0 : 61 72 00 6F 5F 70 6C 75 : ar.o_plu
00E8 : 72 61 6C 00 6F 72 69 67 : ral.orig
00F0 : 69 6E 61 6C 00 4D 49 4D : inal.MIM
00F8 : 45 2D 56 65 72 73 69 6F : E-Versio
0100 : 6E 3A 20 31 2E 30 0A 43 : n:.1.0.C
0108 : 6F 6E 74 65 6E 74 2D 54 : ontent-T
0110 : 79 70 65 3A 20 74 65 78 : ype:.tex
0118 : 74 2F 70 6C 61 69 6E 3B : t/plain;
0120 : 20 63 68 61 72 73 65 74 : .charset
0128 : 3D 49 53 4F 2D 38 38 35 : =ISO-885
0130 : 39 2D 31 0A 50 6C 75 72 : 9-1.Plur
0138 : 61 6C 2D 46 6F 72 6D 73 : al-Forms
0140 : 3A 20 6E 70 6C 75 72 61 : :.nplura
0148 : 6C 73 3D 32 3B 20 70 6C : ls=2;.pl
0150 : 75 72 61 6C 3D 6E 20 21 : ural=n.!
0158 : 3D 20 31 0A 00 74 32 5F : =.1..t2_
0160 : 73 69 6E 67 75 6C 61 72 : singular
0168 : 00 00 74 32 5F 70 6C 75 : ..t2_plu
0170 : 72 61 6C 00 63 5F 74 5F : ral.c_t_
0178 : 73 69 6E 67 75 6C 61 72 : singular
0180 : 00 63 5F 74 5F 70 6C 75 : .c_t_plu
0188 : 72 61 6C 00 63 5F 74 72 : ral.c_tr
0190 : 61 6E 73 6C 61 74 65 64 : anslated
0198 : 00 74 5F 73 69 6E 67 75 : .t_singu
01A0 : 6C 61 72 00 74 5F 70 6C : lar.t_pl
01A8 : 75 72 61 6C 00 74 72 61 : ural.tra
01B0 : 6E 73 6C 61 74 65 64 00 : nslated.
EOT

# === file ===

lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
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
