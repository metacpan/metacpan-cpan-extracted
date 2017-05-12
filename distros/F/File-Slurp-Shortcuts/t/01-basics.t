#!perl -T

use 5.010;
use strict;
no strict 'refs';
use warnings;

use Test::More tests => 12;

use File::Temp qw(tempdir);
use File::Slurp::Shortcuts qw(write_file
                              read_file_c  slurp_c
                              read_file_q  slurp_q
                              read_file_cq slurp_cq
                         );

my $dir = tempdir(CLEANUP => 1);

write_file("$dir/1", "test\n");

for my $sub (qw(read_file_c slurp_c)) {
    is(&$sub("$dir/1"), "test", "$sub: autochomping");
    eval { &$sub("$dir/2") }; my $err = $@; ok($err, "$sub: err_mode default");
}

for my $sub (qw(read_file_q slurp_q)) {
    is(&$sub("$dir/1"), "test\n", "$sub: no autochomping");
    ok(!defined(&$sub("$dir/2")), "$sub: err_mode quiet");
}

for my $sub (qw(read_file_cq slurp_cq)) {
    is(&$sub("$dir/1"), "test", "$sub: autochomping");
    ok(!defined(&$sub("$dir/2")), "$sub: err_mode quiet");
}
