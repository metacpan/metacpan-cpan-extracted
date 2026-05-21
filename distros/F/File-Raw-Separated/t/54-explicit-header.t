#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# `header => [name, name, ...]` (caller-supplied names) for files that
# do NOT have a header row of their own. Distinct from `header => 1`,
# which consumes the first row of the file as keys. All read-side
# entry points should produce hashrefs from row 0.

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/no-header.csv";
File::Raw::spew($f, "alice,30,NYC\nbob,25,LA\ncarol,40,Chicago\n");

my @names = qw(name age city);

subtest 'slurp returns AoH using explicit names' => sub {
    my $rows = File::Raw::slurp($f, plugin => 'csv', header => \@names);
    is(scalar @$rows, 3, 'three rows (no row consumed for header)');
    is_deeply($rows->[0], { name => 'alice', age => '30', city => 'NYC' });
    is_deeply($rows->[2], { name => 'carol', age => '40', city => 'Chicago' });
};

subtest 'lines returns AoH using explicit names' => sub {
    my $rows = File::Raw::lines($f, plugin => 'csv', header => \@names);
    is(scalar @$rows, 3, 'three rows');
    is_deeply($rows->[1], { name => 'bob', age => '25', city => 'LA' });
};

subtest 'head + explicit names' => sub {
    my $h = File::Raw::head($f, 2, plugin => 'csv', header => \@names);
    is(scalar @$h, 2);
    is_deeply($h->[0], { name => 'alice', age => '30', city => 'NYC' });
};

subtest 'tail + explicit names' => sub {
    my $t = File::Raw::tail($f, 2, plugin => 'csv', header => \@names);
    is(scalar @$t, 2);
    is_deeply($t->[-1], { name => 'carol', age => '40', city => 'Chicago' });
};

subtest 'grep_lines predicate sees hashrefs' => sub {
    my $kept = File::Raw::grep_lines(
        $f, sub { $_[0]{age} > 26 },
        plugin => 'csv', header => \@names,
    );
    is(scalar @$kept, 2, 'two rows above 26');
    is_deeply($kept->[0], { name => 'alice', age => '30', city => 'NYC' });
};

subtest 'count_lines counts matching hashrefs' => sub {
    my $n = File::Raw::count_lines(
        $f, sub { $_[0]{city} =~ /^[A-M]/ },
        plugin => 'csv', header => \@names,
    );
    is($n, 2, 'NYC + LA + Chicago - only Chicago and LA start with A-M wait... A-M includes L, C; not N');
    # Actually: NYC=N (excluded), LA=L (included), Chicago=C (included) → 2.
};

subtest 'find_line returns first matching hashref' => sub {
    my $row = File::Raw::find_line(
        $f, sub { $_[0]{city} eq 'LA' },
        plugin => 'csv', header => \@names,
    );
    is_deeply($row, { name => 'bob', age => '25', city => 'LA' });
};

subtest 'map_lines transforms hashrefs' => sub {
    my $cities = File::Raw::map_lines(
        $f, sub { $_[0]{city} },
        plugin => 'csv', header => \@names,
    );
    is_deeply($cities, ['NYC', 'LA', 'Chicago']);
};

subtest 'each_line callback receives hashref' => sub {
    my @rows;
    File::Raw::each_line(
        $f, sub { push @rows, { %{$_[0]} } },
        plugin => 'csv', header => \@names,
    );
    is(scalar @rows, 3);
    is_deeply($rows[0], { name => 'alice', age => '30', city => 'NYC' });
};

subtest 'parse_buf with explicit header' => sub {
    my $rows = File::Raw::Separated::parse_buf(
        "alice,30\nbob,25\n", { header => [qw(name age)] },
    );
    is_deeply($rows, [
        { name => 'alice', age => '30' },
        { name => 'bob',   age => '25' },
    ]);
};

subtest 'csv_parse_buf with explicit header (dialect alias)' => sub {
    my $rows = File::Raw::Separated::csv_parse_buf(
        "alice,30\nbob,25\n", { header => [qw(name age)] },
    );
    is_deeply($rows, [
        { name => 'alice', age => '30' },
        { name => 'bob',   age => '25' },
    ]);
};

subtest 'parse_stream with explicit header' => sub {
    my @rows;
    File::Raw::Separated::parse_stream(
        $f, sub { push @rows, { %{$_[0]} } }, { header => \@names },
    );
    is(scalar @rows, 3);
    is_deeply($rows[2], { name => 'carol', age => '40', city => 'Chicago' });
};

subtest 'tsv plugin accepts explicit header' => sub {
    my $tf = "$dir/no-header.tsv";
    File::Raw::spew($tf, "alice\t30\nbob\t25\n");
    my $rows = File::Raw::slurp($tf, plugin => 'tsv', header => [qw(name age)]);
    is_deeply($rows, [
        { name => 'alice', age => '30' },
        { name => 'bob',   age => '25' },
    ]);
};

subtest 'short rows pad missing keys with undef' => sub {
    my $sf = "$dir/short.csv";
    File::Raw::spew($sf, "alice,30\nbob\n");   # row 2 has only one field
    my $rows = File::Raw::slurp(
        $sf, plugin => 'csv', header => [qw(name age city)],
    );
    is_deeply($rows->[0], { name => 'alice', age => '30', city => undef });
    is_deeply($rows->[1], { name => 'bob',   age => undef, city => undef });
};

subtest 'rows wider than the header croak' => sub {
    my $wf = "$dir/wide.csv";
    File::Raw::spew($wf, "alice,30,extra\n");
    eval {
        File::Raw::slurp($wf, plugin => 'csv', header => [qw(name age)]);
    };
    like($@, qr/row has 3 field.*header has 2/,
        'wider-than-header row caught');
};

subtest 'validation: empty arrayref croaks' => sub {
    eval { File::Raw::slurp($f, plugin => 'csv', header => []) };
    like($@, qr/header => \[\] is empty/, 'empty array rejected');
};

subtest 'validation: undef entry croaks' => sub {
    eval {
        File::Raw::slurp($f, plugin => 'csv', header => ['ok', undef, 'also']);
    };
    like($@, qr/header => \[\.\.\.\] entry 1 is undef/);
};

subtest 'validation: duplicate keys croak' => sub {
    eval {
        File::Raw::slurp($f, plugin => 'csv',
                         header => [qw(name age name)]);
    };
    like($@, qr/duplicate header key 'name'/);
};

subtest 'header => 1 still consumes first row (regression)' => sub {
    my $hf = "$dir/with-header.csv";
    File::Raw::spew($hf, "name,age\nalice,30\nbob,25\n");
    my $rows = File::Raw::slurp($hf, plugin => 'csv', header => 1);
    is(scalar @$rows, 2, 'header row consumed, two data rows left');
    is_deeply($rows->[0], { name => 'alice', age => '30' });
};

done_testing;
