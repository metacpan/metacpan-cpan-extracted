#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IPC::Open3 ();
use Symbol ();

# NO TEST FILE WARNS WHEN IT IS COMPILED. A warning from a test scrolls past
# under a green result: the owner saw `"my" variable $sink masks earlier
# declaration` in a sibling's terminal test before any test did. Each file is compiled
# by the perl running this, with the same @INC, and whatever it says besides
# "syntax OK" is a failure. No shell: the command is a list.

my @files = sort glob('t/*.t'), glob('xt/*.t'), 'bin/sternhalma';
cmp_ok(scalar(@files), '>=', 30, scalar(@files) . ' files to compile');

for my $file (@files) {
    my $err = Symbol::gensym();
    my $pid = IPC::Open3::open3(my $in, my $out, $err, $^X, (map { "-I$_" } grep { !ref } @INC), '-It/lib', '-wc', $file);
    close $in;
    my @said = grep { !/ syntax OK$/ } <$err>, <$out>;
    waitpid $pid, 0;
    is(join('', @said), '', "$file compiles and says nothing");
}

done_testing();
