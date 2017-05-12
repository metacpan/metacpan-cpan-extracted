#!perl -T

use Data::Dumper;
use Test::More tests => 14;
use Makefile::Parallel::Grammar;

my $struct = Makefile::Parallel::Grammar->parseFile('t/02-grammar.pmake');

is($struct->[0]{rule}{id}, "foo", "First rule name is 'foo'");
is($struct->[0]{walltime}, "5:00", "First rule walltime is '5:00'");
is($struct->[0]{cpus}, 0, "First rule requires '0' CPUs");
ok(defined($struct->[0]{action}[0]{shell}));
ok(!defined($struct->[0]{action}[0]{perl}));

is($struct->[1]{rule}{id}, "bar", "Second rule name is 'bar'");
is($struct->[1]{walltime}, "10:00", "Second rule walltime is '10:00'");
is($struct->[1]{cpus}, 50, "Second rule requires '50' CPUs");
is($struct->[1]{depend_on}[0]{id}, "foo", "Second rule depends on 'foo'");
ok(!defined($struct->[1]{action}[0]{shell}));
ok(defined($struct->[1]{action}[0]{perl}));

ok(defined($struct->[-1]{perl}));
#eval ($struct->[-1]{perl});
die($@) if $@;

is( abc("BA"),"BABABA");
is( abcd("BA"),"BABABABABA");



# print STDERR Dumper($struct);

