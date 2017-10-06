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
    # should store more than nplurals
    {
        msgid         => 'o_singular',
        msgid_plural  => 'o_plural',
        msgstr_plural => [ qw(t_singular t_plural_0 t_plural_1 t_plural_2) ],
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
        msgid_plural  => 'o3_plural',
        msgstr_plural => [ q{}, qw(t3_plural) ],
    },
    # shoud store a plural
    {
        msgid         => 'o4_singular',
        msgid_plural  => 'o4_plural',
        msgstr_plural => [ q{}, q{} ],
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
0008 : 08000000 : number of strings
000C : 1C000000 : offset msgid
0010 : 5C000000 : offset msgstr
0014 : 00000000 : hash size
0018 : 00000000 : hash offset
001C : 00 00 00 00 : ....
0020 : 9C 00 00 00 0A 00 00 00 : ........
0028 : 9D 00 00 00 0A 00 00 00 : ........
0030 : A8 00 00 00 21 00 00 00 : ....!...
0038 : B3 00 00 00 12 00 00 00 : ........
0040 : D5 00 00 00 15 00 00 00 : ........
0048 : E8 00 00 00 13 00 00 00 : ........
0050 : FE 00 00 00 08 00 00 00 : ........
0058 : 12 01 00 00 67 00 00 00 : ....g...
0060 : 1B 01 00 00 0B 00 00 00 : ........
0068 : 83 01 00 00 0A 00 00 00 : ........
0070 : 8F 01 00 00 17 00 00 00 : ........
0078 : 9A 01 00 00 0C 00 00 00 : ........
0080 : B2 01 00 00 01 00 00 00 : ........
0088 : BF 01 00 00 2B 00 00 00 : ....+...
0090 : C1 01 00 00 0A 00 00 00 : ........
0098 : ED 01 00 00 00 00 6F 32 : ......o2
00A0 : 5F 70 6C 75 72 61 6C 00 : _plural.
00A8 : 00 6F 33 5F 70 6C 75 72 : .o3_plur
00B0 : 61 6C 00 63 5F 63 6F 6E : al.c_con
00B8 : 74 65 78 74 04 63 5F 6F : text.c_o
00C0 : 5F 73 69 6E 67 75 6C 61 : _singula
00C8 : 72 00 63 5F 6F 5F 70 6C : r.c_o_pl
00D0 : 75 72 61 6C 00 63 6F 6E : ural.con
00D8 : 74 65 78 74 04 63 5F 6F : text.c_o
00E0 : 72 69 67 69 6E 61 6C 00 : riginal.
00E8 : 6F 34 5F 73 69 6E 67 75 : o4_singu
00F0 : 6C 61 72 00 6F 34 5F 70 : lar.o4_p
00F8 : 6C 75 72 61 6C 00 6F 5F : lural.o_
0100 : 73 69 6E 67 75 6C 61 72 : singular
0108 : 00 6F 5F 70 6C 75 72 61 : .o_plura
0110 : 6C 00 6F 72 69 67 69 6E : l.origin
0118 : 61 6C 00 4D 49 4D 45 2D : al.MIME-
0120 : 56 65 72 73 69 6F 6E 3A : Version:
0128 : 20 31 2E 30 0A 43 6F 6E : .1.0.Con
0130 : 74 65 6E 74 2D 54 79 70 : tent-Typ
0138 : 65 3A 20 74 65 78 74 2F : e:.text/
0140 : 70 6C 61 69 6E 3B 20 63 : plain;.c
0148 : 68 61 72 73 65 74 3D 49 : harset=I
0150 : 53 4F 2D 38 38 35 39 2D : SO-8859-
0158 : 31 0A 50 6C 75 72 61 6C : 1.Plural
0160 : 2D 46 6F 72 6D 73 3A 20 : -Forms:.
0168 : 6E 70 6C 75 72 61 6C 73 : nplurals
0170 : 3D 32 3B 20 70 6C 75 72 : =2;.plur
0178 : 61 6C 3D 6E 20 21 3D 20 : al=n.!=.
0180 : 31 0A 00 74 32 5F 73 69 : 1..t2_si
0188 : 6E 67 75 6C 61 72 00 00 : ngular..
0190 : 74 33 5F 70 6C 75 72 61 : t3_plura
0198 : 6C 00 63 5F 74 5F 73 69 : l.c_t_si
01A0 : 6E 67 75 6C 61 72 00 63 : ngular.c
01A8 : 5F 74 5F 70 6C 75 72 61 : _t_plura
01B0 : 6C 00 63 5F 74 72 61 6E : l.c_tran
01B8 : 73 6C 61 74 65 64 00 00 : slated..
01C0 : 00 74 5F 73 69 6E 67 75 : .t_singu
01C8 : 6C 61 72 00 74 5F 70 6C : lar.t_pl
01D0 : 75 72 61 6C 5F 30 00 74 : ural_0.t
01D8 : 5F 70 6C 75 72 61 6C 5F : _plural_
01E0 : 31 00 74 5F 70 6C 75 72 : 1.t_plur
01E8 : 61 6C 5F 32 00 74 72 61 : al_2.tra
01F0 : 6E 73 6C 61 74 65 64 00 : nslated.
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
