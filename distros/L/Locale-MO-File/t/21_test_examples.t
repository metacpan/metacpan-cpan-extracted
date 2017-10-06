#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '11_little_endian',
        path   => 'example',
        script => '-I../lib -T 11_little_endian.pl',
        result => <<'EOT',
$messages_result = [
  {
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgctxt => 'c_context',
    msgid => 'c_o_singular',
    msgid_plural => 'c_o_plural',
    msgstr_plural => [
      'c_t_singular',
      'c_t_plural'
    ]
  },
  {
    msgctxt => 'context',
    msgid => 'c_original',
    msgstr => 'c_translated'
  },
  {
    msgid => 'o_singular',
    msgid_plural => 'o_plural',
    msgstr_plural => [
      't_singular',
      't_plural'
    ]
  },
  {
    msgid => 'original',
    msgstr => 'translated'
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
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgctxt => 'c_context',
    msgid => 'c_o_singular',
    msgid_plural => 'c_o_plural',
    msgstr_plural => [
      'c_t_singular',
      'c_t_plural'
    ]
  },
  {
    msgctxt => 'context',
    msgid => 'c_original',
    msgstr => 'c_translated'
  },
  {
    msgid => 'o_singular',
    msgid_plural => 'o_plural',
    msgstr_plural => [
      't_singular',
      't_plural'
    ]
  },
  {
    msgid => 'original',
    msgstr => 'translated'
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
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgctxt => 'c_context',
    msgid => 'c_o_singular',
    msgid_plural => 'c_o_plural',
    msgstr_plural => [
      'c_t_singular',
      'c_t_plural'
    ]
  },
  {
    msgctxt => 'context',
    msgid => 'c_original',
    msgstr => 'c_translated'
  },
  {
    msgid => 'o_singular',
    msgid_plural => 'o_plural',
    msgstr_plural => [
      't_singular',
      't_plural'
    ]
  },
  {
    msgid => 'original',
    msgstr => 'translated'
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
    msgid => '',
    msgstr => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    msgctxt => 'c_context',
    msgid => 'c_o_singular',
    msgid_plural => 'c_o_plural',
    msgstr_plural => [
      'c_t_singular',
      'c_t_plural'
    ]
  },
  {
    msgctxt => 'context',
    msgid => 'c_original',
    msgstr => 'c_translated'
  },
  {
    msgid => 'o_singular',
    msgid_plural => 'o_plural',
    msgstr_plural => [
      't_singular',
      't_plural'
    ]
  },
  {
    msgid => 'original',
    msgstr => 'translated'
  }
];
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
