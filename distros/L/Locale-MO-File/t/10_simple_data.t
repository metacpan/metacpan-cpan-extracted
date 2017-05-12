#!perl -T

use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
require IO::File;

use Test::More tests => 7;
use Test::NoWarnings;
use Test::Differences;
use Test::Exception;
use Test::HexDifferences;

BEGIN {
    require_ok 'Locale::MO::File';
}

my @messages = (
    { msgid  => 'I2', msgstr => 'S2' },
    { msgid  => 'I1', msgstr => 'S1' },
);

my $filename = '10_simple_data.mo';

my $hex_dump = <<'EOT';
0000 : 950412DE : magic number
0004 : 00000000 : revision
0008 : 00000002 : number of strings
000C : 0000001C : offset msgid
0010 : 0000002C : offset msgstr
0014 : 00000000 : hash size
0018 : 00000000 : hash offset
001C : 00 00 00 02 : ....
0020 : 00 00 00 3C 00 00 00 02 : ...<....
0028 : 00 00 00 3F 00 00 00 02 : ...?....
0030 : 00 00 00 42 00 00 00 02 : ...B....
0038 : 00 00 00 45 49 31 00 49 : ...EI1.I
0040 : 32 00 53 31 00 53 32 00 : 2.S1.S2.
EOT

lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_is_big_endian(1);
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
    [
        { msgid  => 'I1', msgstr => 'S1' },
        { msgid  => 'I2', msgstr => 'S2' },
    ],
    'check messages';
