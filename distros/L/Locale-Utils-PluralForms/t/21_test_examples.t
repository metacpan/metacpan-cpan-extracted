#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 3);

my @data = (
    {
        test   => '01_plural_forms_from_web',
        path   => 'example',
        script => '-I../lib -T 01_plural_forms_from_web.pl',
        result => <<'EOT',
English:
plural_forms = 'nplurals=2; plural=(n != 1)'
nplurals = 2

The en plural from for 0 is 1
The en plural from for 1 is 0
The en plural from for 2 is 1
Russian:
plural_forms = 'nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
nplurals = 3

The ru plural from for 0 is 2
The ru plural from for 1 is 0
The ru plural from for 2 is 1
The ru plural from for 5 is 2
The ru plural from for 100 is 2
The ru plural from for 101 is 0
The ru plural from for 102 is 1
The ru plural from for 105 is 2
The ru plural from for 110 is 2
The ru plural from for 111 is 2
The ru plural from for 112 is 2
The ru plural from for 115 is 2
The ru plural from for 120 is 2
The ru plural from for 121 is 0
The ru plural from for 122 is 1
The ru plural from for 125 is 2
EOT
    },
    {
        test   => '02_plural_forms_from_data_struct',
        path   => 'example',
        script => '-I../lib -T 02_plural_forms_from_data_struct.pl',
        result => <<'EOT',
English:
plural_forms = 'nplurals=2; plural=(n != 1)'
nplurals = 2

The en plural from for 0 is 1
The en plural from for 1 is 0
The en plural from for 2 is 1
Russian:
plural_forms = 'nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
nplurals = 3

The ru plural from for 0 is 2
The ru plural from for 1 is 0
The ru plural from for 2 is 1
The ru plural from for 5 is 2
The ru plural from for 100 is 2
The ru plural from for 101 is 0
The ru plural from for 102 is 1
The ru plural from for 105 is 2
The ru plural from for 110 is 2
The ru plural from for 111 is 2
The ru plural from for 112 is 2
The ru plural from for 115 is 2
The ru plural from for 120 is 2
The ru plural from for 121 is 0
The ru plural from for 122 is 1
The ru plural from for 125 is 2
EOT
    },
    {
        test   => '03_calculate_plural_forms_only',
        path   => 'example',
        script => '-I../lib -T 03_calculate_plural_forms_only.pl',
        result => <<'EOT',
English:
plural_forms = 'nplurals=2; plural=(n != 1)'
nplurals = 2

The en plural from for 0 is 1
The en plural from for 1 is 0
The en plural from for 2 is 1
Russian:
plural_forms = 'nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
nplurals = 3

The ru plural from for 0 is 2
The ru plural from for 1 is 0
The ru plural from for 2 is 1
The ru plural from for 5 is 2
The ru plural from for 100 is 2
The ru plural from for 101 is 0
The ru plural from for 102 is 1
The ru plural from for 105 is 2
The ru plural from for 110 is 2
The ru plural from for 111 is 2
The ru plural from for 112 is 2
The ru plural from for 115 is 2
The ru plural from for 120 is 2
The ru plural from for 121 is 0
The ru plural from for 122 is 1
The ru plural from for 125 is 2
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
