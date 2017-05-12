#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{AUTHOR_TESTING} or plan
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

plan tests => 8;

my @data = (
    {
        test   => '11_little_endian',
        path   => 'example',
        script => '-I../lib -T 11_little_endian.pl',
        result => <<'EOT',
$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgctxt' => 'c_context',
    'msgid' => 'c_o_singular',
    'msgstr_plural' => [
      'c_t_singular',
      'c_t_plural'
    ],
    'msgid_plural' => 'c_o_plural'
  },
  {
    'msgctxt' => 'context',
    'msgid' => 'c_original',
    'msgstr' => 'c_translated'
  },
  {
    'msgid' => 'o_singular',
    'msgstr_plural' => [
      't_singular',
      't_plural'
    ],
    'msgid_plural' => 'o_plural'
  },
  {
    'msgid' => 'original',
    'msgstr' => 'translated'
  }
];
EOT
    },
    {
        test   => '12_little_endian_fh',
        path   => 'example',
        script => '-I../lib -T 12_little_endian_fh.pl',
        result => <<'EOT',
$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgctxt' => 'c_context',
    'msgid' => 'c_o_singular',
    'msgstr_plural' => [
      'c_t_singular',
      'c_t_plural'
    ],
    'msgid_plural' => 'c_o_plural'
  },
  {
    'msgctxt' => 'context',
    'msgid' => 'c_original',
    'msgstr' => 'c_translated'
  },
  {
    'msgid' => 'o_singular',
    'msgstr_plural' => [
      't_singular',
      't_plural'
    ],
    'msgid_plural' => 'o_plural'
  },
  {
    'msgid' => 'original',
    'msgstr' => 'translated'
  }
];
EOT
    },
    {
        test   => '13_little_endian_utf-8',
        path   => 'example',
        script => '-I../lib -T 13_little_endian_utf-8.pl',
        result => <<'EOT',
$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgid' => "11\x{eb}",
    'msgstr' => "12\x{fc}"
  },
  {
    'msgctxt' => "21\x{e4}",
    'msgid' => "22\x{eb}",
    'msgstr' => "23\x{fc}"
  },
  {
    'msgid' => "31\x{eb}",
    'msgstr_plural' => [
      "33\x{fc}",
      "34\x{fc}"
    ],
    'msgid_plural' => "32\x{f6}"
  },
  {
    'msgctxt' => "41\x{e4}",
    'msgid' => "42\x{eb}",
    'msgstr_plural' => [
      "44\x{fc}",
      "45\x{fc}"
    ],
    'msgid_plural' => "43\x{f6}"
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
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgid' => "11\x{eb}",
    'msgstr' => "12\x{fc}"
  },
  {
    'msgctxt' => "21\x{e4}",
    'msgid' => "22\x{eb}",
    'msgstr' => "23\x{fc}"
  },
  {
    'msgid' => "31\x{eb}",
    'msgstr_plural' => [
      "33\x{fc}",
      "34\x{fc}"
    ],
    'msgid_plural' => "32\x{f6}"
  },
  {
    'msgctxt' => "41\x{e4}",
    'msgid' => "42\x{eb}",
    'msgstr_plural' => [
      "44\x{fc}",
      "45\x{fc}"
    ],
    'msgid_plural' => "43\x{f6}"
  }
];
EOT
    },
    {
        test   => '21_big_endian',
        path   => 'example',
        script => '-I../lib -T 21_big_endian.pl',
        result => <<'EOT',
$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgctxt' => 'c_context',
    'msgid' => 'c_o_singular',
    'msgstr_plural' => [
      'c_t_singular',
      'c_t_plural'
    ],
    'msgid_plural' => 'c_o_plural'
  },
  {
    'msgctxt' => 'context',
    'msgid' => 'c_original',
    'msgstr' => 'c_translated'
  },
  {
    'msgid' => 'o_singular',
    'msgstr_plural' => [
      't_singular',
      't_plural'
    ],
    'msgid_plural' => 'o_plural'
  },
  {
    'msgid' => 'original',
    'msgstr' => 'translated'
  }
];
EOT
    },
    {
        test   => '22_big_endian_fh',
        path   => 'example',
        script => '-I../lib -T 22_big_endian_fh.pl',
        result => <<'EOT',
$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgctxt' => 'c_context',
    'msgid' => 'c_o_singular',
    'msgstr_plural' => [
      'c_t_singular',
      'c_t_plural'
    ],
    'msgid_plural' => 'c_o_plural'
  },
  {
    'msgctxt' => 'context',
    'msgid' => 'c_original',
    'msgstr' => 'c_translated'
  },
  {
    'msgid' => 'o_singular',
    'msgstr_plural' => [
      't_singular',
      't_plural'
    ],
    'msgid_plural' => 'o_plural'
  },
  {
    'msgid' => 'original',
    'msgstr' => 'translated'
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
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgid' => "11\x{eb}",
    'msgstr' => "12\x{fc}"
  },
  {
    'msgctxt' => "21\x{e4}",
    'msgid' => "22\x{eb}",
    'msgstr' => "23\x{fc}"
  },
  {
    'msgid' => "31\x{eb}",
    'msgstr_plural' => [
      "33\x{fc}",
      "34\x{fc}"
    ],
    'msgid_plural' => "32\x{f6}"
  },
  {
    'msgctxt' => "41\x{e4}",
    'msgid' => "42\x{eb}",
    'msgstr_plural' => [
      "44\x{fc}",
      "45\x{fc}"
    ],
    'msgid_plural' => "43\x{f6}"
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
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgid' => "11\x{eb}",
    'msgstr' => "12\x{fc}"
  },
  {
    'msgctxt' => "21\x{e4}",
    'msgid' => "22\x{eb}",
    'msgstr' => "23\x{fc}"
  },
  {
    'msgid' => "31\x{eb}",
    'msgstr_plural' => [
      "33\x{fc}",
      "34\x{fc}"
    ],
    'msgid_plural' => "32\x{f6}"
  },
  {
    'msgctxt' => "41\x{e4}",
    'msgid' => "42\x{eb}",
    'msgstr_plural' => [
      "44\x{fc}",
      "45\x{fc}"
    ],
    'msgid_plural' => "43\x{f6}"
  }
];
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd;
    chdir "$dir/$data->{path}";
    my $result = qx{perl $data->{script} 2>&3};
    chdir $dir;
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
