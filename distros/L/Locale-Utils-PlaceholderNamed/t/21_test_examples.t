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
        test   => '01_expand_named',
        path   => 'example',
        script => '-I../lib -T 01_expand_named.pl',
        result => <<'EOT',
{count} EUR
0 EUR
1 EUR
2 EUR
345.678,90 EUR
45.678,9 EUR
 EUR
0 EUR
1 EUR
2 EUR
345678.90 EUR
45678.9 EUR
EOT
    },
    {
        test   => '02_modifier_code',
        path   => 'example',
        script => '-I../lib -T 02_modifier_code.pl',
        result => <<'EOT',
 EUR
0 EUR
1 EUR
2 EUR
345.678,90 EUR
45.678,9 EUR
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
    chdir $dir;
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
