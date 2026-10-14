#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Config;
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use HAMT::Map;
use HAMT::Vector;

# The C ABI against the Perl methods, doing the same work: what a consumer
# written in C saves by not making a Perl call for each element. It builds
# the consumer from xt/abi-consumer in a temporary directory first.
#
# Usage: perl bench/abi.pl [SIZE]

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my $n = shift(@ARGV) || 100_000;
my $dist = abs_path("$FindBin::Bin/..");
my $src  = "$dist/xt/abi-consumer";
die "no consumer source at $src\n" unless -f "$src/Consumer.xs";

my $build = tempdir(CLEANUP => 1);
make_path("$build/lib/HAMT/ABI");
copy("$src/$_", "$build/$_") or die "copy $_: $!" for 'Makefile.PL', 'Consumer.xs';
copy("$src/lib/HAMT/ABI/Consumer.pm", "$build/lib/HAMT/ABI/Consumer.pm") or die "copy: $!";
{
    local $ENV{PERL5LIB} = join $Config{path_sep}, "$dist/blib/arch", "$dist/blib/lib", grep { defined && length } $ENV{PERL5LIB};
    my $log = `cd "$build" && "$^X" Makefile.PL 2>&1 && "$Config{make}" 2>&1`;
    die "the consumer did not build:\n$log" if $?;
}
unshift @INC, "$build/blib/arch", "$build/blib/lib";
require HAMT::ABI::Consumer;

print "the C ABI against the Perl methods, $n elements; perl $], $^O\n";
my $m = HAMT::Map->new(map { ("key$_" => $_) } 1 .. $n);
my $v = HAMT::Vector->new(1 .. $n);

print "\nsumming a map's values\n";
cmpthese($T, {
    'perl values' => sub { my $s = 0; $s += $_ for $m->values },
    'perl each'   => sub { my $s = 0; $m->each(sub { $s += $_[1] }) },
    'C map_walk'  => sub { my $s = HAMT::ABI::Consumer::sum_values($m) },
});

print "\nfilling a transient\n";
cmpthese($T, {
    'perl set'    => sub { my $t = HAMT::Map->new->transient; $t->set("c$_", $_) for 0 .. $n - 1 },
    'C map_store' => sub { my $t = HAMT::Map->new->transient; HAMT::ABI::Consumer::fill($t, $n) },
});

print "\nreversing a vector\n";
cmpthese($T, {
    'perl list, new'   => sub { my $r = HAMT::Vector->new(reverse $v->list) },
    'C fetch and push' => sub { my $r = HAMT::ABI::Consumer::reversed($v) },
});
