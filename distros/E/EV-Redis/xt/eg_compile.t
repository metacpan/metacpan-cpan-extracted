use strict;
use warnings;
use Test::More;

# The shipped examples get no other coverage; at least they must compile.
my @eg = sort glob 'eg/*.pl';
plan skip_all => 'no eg/*.pl found' unless @eg;
plan tests => scalar @eg;

for my $f (@eg) {
    my $out = qx{$^X -c @{[ quotemeta $f ]} 2>&1};
    SKIP: {
        skip "$f needs $1", 1
            if $? && $out =~ /^Can't locate (\S+)\.pm in \@INC/m && $1 ne 'EV/Redis';
        is $?, 0, "$f compiles";
        diag $out if $?;
    }
}
