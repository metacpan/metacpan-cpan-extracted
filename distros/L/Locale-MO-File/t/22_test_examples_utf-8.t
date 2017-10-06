#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use Encode qw(decode_utf8);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '13_little_endian_utf-8',
        path   => 'example',
        script => '-I../lib -T 13_little_endian_utf-8.pl',
        result => <<'EOT',
$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgid => '11ë',
    msgstr => '12ü'
  },
  {
    msgctxt => '21ä',
    msgid => '22ë',
    msgstr => '23ü'
  },
  {
    msgid => '31ë',
    msgid_plural => '32ö',
    msgstr_plural => [
      '33ü',
      '34ü'
    ]
  },
  {
    msgctxt => '41ä',
    msgid => '42ë',
    msgid_plural => '43ö',
    msgstr_plural => [
      '44ü',
      '45ü'
    ]
  }
];
EOT
    },
    {
        test   => '14_little_endian_fh_utf-8',
        path   => 'example',
        script => '-I../lib -T 14_little_endian_fh_utf-8.pl',
        result => <<'EOT',
$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgid => '11ë',
    msgstr => '12ü'
  },
  {
    msgctxt => '21ä',
    msgid => '22ë',
    msgstr => '23ü'
  },
  {
    msgid => '31ë',
    msgid_plural => '32ö',
    msgstr_plural => [
      '33ü',
      '34ü'
    ]
  },
  {
    msgctxt => '41ä',
    msgid => '42ë',
    msgid_plural => '43ö',
    msgstr_plural => [
      '44ü',
      '45ü'
    ]
  }
];
EOT
    },
    {
        test   => '23_big_endian_utf-8',
        path   => 'example',
        script => '-I../lib -T 23_big_endian_utf-8.pl',
        result => <<'EOT',
$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgid => '11ë',
    msgstr => '12ü'
  },
  {
    msgctxt => '21ä',
    msgid => '22ë',
    msgstr => '23ü'
  },
  {
    msgid => '31ë',
    msgid_plural => '32ö',
    msgstr_plural => [
      '33ü',
      '34ü'
    ]
  },
  {
    msgctxt => '41ä',
    msgid => '42ë',
    msgid_plural => '43ö',
    msgstr_plural => [
      '44ü',
      '45ü'
    ]
  }
];
EOT
    },
    {
        test   => '24_big_endian_fh_utf-8',
        path   => 'example',
        script => '-I../lib -T 24_big_endian_fh_utf-8.pl',
        result => <<'EOT',
$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgid => '11ë',
    msgstr => '12ü'
  },
  {
    msgctxt => '21ä',
    msgid => '22ë',
    msgstr => '23ü'
  },
  {
    msgid => '31ë',
    msgid_plural => '32ö',
    msgstr_plural => [
      '33ü',
      '34ü'
    ]
  },
  {
    msgctxt => '41ä',
    msgid => '42ë',
    msgid_plural => '43ö',
    msgstr_plural => [
      '44ü',
      '45ü'
    ]
  }
];
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = decode_utf8( qx{perl $data->{script} 2>&1} );
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
