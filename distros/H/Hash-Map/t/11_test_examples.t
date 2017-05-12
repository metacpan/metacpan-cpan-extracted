#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan(tests => 2);

my @data = (
    {
        test   => '01_oo_style',
        path   => 'example',
        script => '01_oo_style.pl',
        params => '-I../lib -T',
        result => <<'EOT',
$hash_map = {
  'account' => 'STEFFENW',
  'city' => 'Examplecity',
  'country_code' => 'DE',
  'mail_address' => 'steffenw@example.com',
  'mail_name' => 'Steffen Winkler',
  'name' => 'Steffen Winkler',
  'street' => 'Examplestreet',
  'zip_code' => '01234'
};
EOT
    },
    {
        test   => '02_functional_style',
        path   => 'example',
        script => '02_functional_style.pl',
        params => '-I../lib -T',
        result => <<'EOT',
$hash_map = {
  'account' => 'STEFFENW',
  'city' => 'Examplecity',
  'country_code' => 'DE',
  'mail_address' => 'steffenw@example.com',
  'mail_name' => 'Steffen Winkler',
  'name' => 'Steffen Winkler',
  'street' => 'Examplestreet',
  'zip_code' => '01234'
};
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
