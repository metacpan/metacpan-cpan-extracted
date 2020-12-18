#!perl

use Test2::V0;
use Test::Script 1.23;

use Path::Tiny;

my $expected = <<EOF;
const A = 100;
const B = 200;
EOF

script_runs(
    [qw( bin/js-const -I t/lib -m Consts2 )],
    {
        exit   => 0,
        stdout => \my $out
    }
);

is $out, $expected, 'expected output (stoud)';

my $file = Path::Tiny->tempfile;

script_runs(
    [qw( bin/js-const -I t/lib -m Consts2 ), "$file" ],
    {
        exit   => 0,
    }
);

is $file->slurp, $expected, "wrote to file";

done_testing;
