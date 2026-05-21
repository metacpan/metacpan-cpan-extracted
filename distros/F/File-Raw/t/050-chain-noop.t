#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# Single-element arrayref [csv] is equivalent to the scalar form 'csv'
# across the plugin-aware XSUBs (slurp / spew / append / atomic_spew /
# lines). This is the load-bearing backward-compat property: callers
# who already passed a scalar plugin name keep working byte-for-byte;
# callers who switch to [name] (e.g. as a stepping stone before adding
# more layers) get identical behaviour.

my $dir = tempdir(CLEANUP => 1);

File::Raw::register_plugin('uc_chain', {
    read  => sub { my ($p, $b, $o) = @_; uc $b },
    write => sub { my ($p, $r, $o) = @_; lc $r },
});

subtest 'slurp scalar vs [name] match' => sub {
    my $f = "$dir/r.txt";
    File::Raw::spew($f, 'hello WORLD');
    my $scalar  = File::Raw::slurp($f, plugin => 'uc_chain');
    my $chained = File::Raw::slurp($f, plugin => ['uc_chain']);
    is($scalar, $chained, 'slurp returns the same SV value either way');
    is($scalar, 'HELLO WORLD', 'and the value is the uppercase form');
};

subtest 'spew scalar vs [name] match on disk' => sub {
    my $a = "$dir/wa.txt";
    my $b = "$dir/wb.txt";
    File::Raw::spew($a, 'MIXED', plugin => 'uc_chain');
    File::Raw::spew($b, 'MIXED', plugin => ['uc_chain']);
    is(File::Raw::slurp($a), File::Raw::slurp($b),
        'identical bytes written regardless of plugin shape');
    is(File::Raw::slurp($a), 'mixed', 'and the bytes are lowercased');
};

subtest 'append scalar vs [name] match on disk' => sub {
    my $a = "$dir/aa.txt";
    my $b = "$dir/ab.txt";
    File::Raw::spew($a, 'pre-');
    File::Raw::spew($b, 'pre-');
    File::Raw::append($a, 'TAIL', plugin => 'uc_chain');
    File::Raw::append($b, 'TAIL', plugin => ['uc_chain']);
    is(File::Raw::slurp($a), File::Raw::slurp($b),
        'append produces identical bytes');
    is(File::Raw::slurp($a), 'pre-tail', 'and the result is correct');
};

subtest 'atomic_spew scalar vs [name] match on disk' => sub {
    my $a = "$dir/sa.txt";
    my $b = "$dir/sb.txt";
    File::Raw::atomic_spew($a, 'ATOMIC', plugin => 'uc_chain');
    File::Raw::atomic_spew($b, 'ATOMIC', plugin => ['uc_chain']);
    is(File::Raw::slurp($a), File::Raw::slurp($b),
        'atomic_spew produces identical bytes');
    is(File::Raw::slurp($a), 'atomic', 'and the result is correct');
};

done_testing;
