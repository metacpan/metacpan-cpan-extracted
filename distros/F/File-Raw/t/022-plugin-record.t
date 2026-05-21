#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# grep_lines / count_lines / find_line / map_lines / head / tail
# with a parsing plugin (READ-then-iterate path).

my $dir = tempdir(CLEANUP => 1);

# Minimal CSV-ish plugin, sep configurable per call.
File::Raw::register_plugin('csv', {
    read => sub {
        my ($p, $bytes, $opts) = @_;
        my $sep = $opts->{sep} // ',';
        return [ map { [split /\Q$sep\E/, $_, -1] } split /\n/, $bytes ];
    },
});

my $f = "$dir/data.csv";
File::Raw::spew($f, "a;1\nb;2\nc;3\nd;\ne;5");

subtest 'grep_lines filters parsed records' => sub {
    my $kept = File::Raw::grep_lines($f, sub { length $_[0][1] },
                                     plugin => 'csv', sep => ';');
    is(scalar @$kept, 4, 'kept 4 rows with non-empty col 1');
    is_deeply($kept->[0], ['a', '1'], 'first kept row is correct');
};

subtest 'count_lines counts matching records' => sub {
    my $n = File::Raw::count_lines($f, sub { length $_[0][1] },
                                   plugin => 'csv', sep => ';');
    is($n, 4, 'count matches grep_lines result');
};

subtest 'count_lines with undef predicate counts all records' => sub {
    my $n = File::Raw::count_lines($f, undef, plugin => 'csv', sep => ';');
    is($n, 5, 'undef predicate counts every record');
};

subtest 'find_line returns first match' => sub {
    my $row = File::Raw::find_line($f, sub { $_[0][0] eq 'c' },
                                   plugin => 'csv', sep => ';');
    is_deeply($row, ['c', '3'], 'found target row');
};

subtest 'find_line returns undef when nothing matches' => sub {
    my $row = File::Raw::find_line($f, sub { 0 }, plugin => 'csv', sep => ';');
    is($row, undef, 'no match returns undef');
};

subtest 'map_lines transforms records' => sub {
    my $cols = File::Raw::map_lines($f, sub { $_[0][0] },
                                    plugin => 'csv', sep => ';');
    is_deeply($cols, ['a', 'b', 'c', 'd', 'e'], 'mapped first column');
};

subtest 'head with plugin slices first N records' => sub {
    my $h = File::Raw::head($f, 2, plugin => 'csv', sep => ';');
    is(scalar @$h, 2, 'returned 2 records');
    is_deeply($h->[0], ['a', '1'], 'first record correct');
    is_deeply($h->[1], ['b', '2'], 'second record correct');
};

subtest 'head with plugin and no $n uses default 10' => sub {
    my $h = File::Raw::head($f, plugin => 'csv', sep => ';');
    is(scalar @$h, 5, 'capped at file size when default exceeds it');
};

subtest 'tail with plugin slices last N records' => sub {
    my $t = File::Raw::tail($f, 2, plugin => 'csv', sep => ';');
    is(scalar @$t, 2, 'returned 2 records');
    is_deeply($t->[0], ['d', ''],  'penultimate record correct');
    is_deeply($t->[1], ['e', '5'], 'last record correct');
};

subtest 'predicate-name + plugin tail croaks' => sub {
    eval { File::Raw::grep_lines($f, 'is_blank', plugin => 'csv') };
    like($@, qr/predicate-name sugar is legacy/, 'rejected with helpful error');
};

subtest 'plugin must return arrayref for predicate-style ops' => sub {
    File::Raw::register_plugin('not_aref', { read => sub { "just bytes" } });
    eval { File::Raw::grep_lines($f, sub { 1 }, plugin => 'not_aref') };
    like($@, qr/arrayref of records/, 'non-arrayref READ rejected');
    File::Raw::unregister_plugin('not_aref');
};

subtest 'legacy 2-arg grep / count / find still work' => sub {
    File::Raw::spew("$dir/blanks.txt", "ok\n\n  \nok2\n");
    my $blanks = File::Raw::grep_lines("$dir/blanks.txt", 'is_blank');
    is(scalar @$blanks, 2, 'legacy predicate name path intact');

    my $cnt = File::Raw::count_lines("$dir/blanks.txt", sub { $_[0] =~ /^ok/ });
    is($cnt, 2, 'legacy coderef path intact');

    my $first = File::Raw::find_line("$dir/blanks.txt", sub { $_[0] =~ /ok2/ });
    is($first, 'ok2', 'find_line returns string in legacy mode');
};

done_testing;
