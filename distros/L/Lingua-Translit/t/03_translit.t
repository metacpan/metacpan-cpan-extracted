use strict;
use Test::More tests => 5;

my $truth;

my $script = "./blib/script/translit";


$truth = -e $script;

# 1
is($truth, 1, "translit found");


$truth = system($^X, $script, "-h");

# 2
is($truth, 0, "translit supports -h switch");


$truth = system($^X, $script, "--help");

# 3
is($truth, 0, "translit supports --help switch");


$truth = system($^X, $script, "-l");

# 4
is($truth, 0, "translit supports -l switch");


$truth = system($^X, $script, "--list");

# 5
is($truth, 0, "translit supports --list switch");
