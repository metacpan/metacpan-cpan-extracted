#!perl
use 5.010;
use strict;
use warnings;
use Benchmark qw(timeit timestr :hireswallclock);

# What the pre-5.14 call-site wrapper costs a call to a plain sub: compile
# 10,000 such calls with Ex::Op loaded and without. From 5.14 the check
# is on each op's own sub and a plain call never meets it, so this is run on
# a build made with EX_OP_CHECK_WRAP=1, or on 5.10 and 5.12.

if (@ARGV && $ARGV[0] eq '--child') {
    require Ex::Op if $ARGV[1];
    my $src = "no warnings q{redefine};\nsub plain { \$_[0] }\nsub body {\n" . join('', map { "plain($_);\n" } 1 .. 10_000) . "}\n1;";
    my $t = timeit(50, sub { eval $src or die $@ });
    printf "%.6f\n", $t->real / $t->iters;
    exit;
}

my @inc = map { "-I$_" } @INC;
my %per;
for my $loaded (0, 1) {
    my ($best) = sort { $a <=> $b } map { `$^X @inc $0 --child $loaded` + 0 } 1 .. 3;
    $per{$loaded} = $best;
}
printf "compile of 10,000 plain calls: %.2f ms without Ex::Op, %.2f ms with it, %+.1f%%\n",
    $per{0} * 1000, $per{1} * 1000, ($per{1} / $per{0} - 1) * 100;
