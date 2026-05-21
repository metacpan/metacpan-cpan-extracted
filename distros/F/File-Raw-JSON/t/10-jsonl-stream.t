#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

# Basic streaming: each_line emits parsed values one at a time
subtest 'basic each_line + jsonl' => sub {
    my $f = "$dir/s.jsonl";
    File::Raw::spew($f, qq({"a":1}\n{"b":2}\n{"c":3}\n));
    my @rows;
    File::Raw::each_line($f, sub { push @rows, $_[0] }, plugin => 'jsonl');
    is(scalar @rows, 3, 'three records emitted');
    is_deeply($rows[0], {a=>1}, 'first');
    is_deeply($rows[2], {c=>3}, 'third');
};

# Pretty-printed JSONL streamed correctly (records span lines)
subtest 'pretty-printed jsonl streams' => sub {
    my $f = "$dir/pretty.jsonl";
    File::Raw::spew($f, qq({\n  "a": 1\n}\n{\n  "b": 2\n}\n));
    my @rows;
    File::Raw::each_line($f, sub { push @rows, $_[0] }, plugin => 'jsonl');
    is(scalar @rows, 2, 'multi-line records counted');
    is_deeply($rows[0], {a=>1}, 'first multi-line record');
    is_deeply($rows[1], {b=>2}, 'second');
};

# Multiple values on one line
subtest 'multiple values per line' => sub {
    my $f = "$dir/mp.jsonl";
    File::Raw::spew($f, q|{"a":1}{"b":2}{"c":3}|);
    my @rows;
    File::Raw::each_line($f, sub { push @rows, $_[0] }, plugin => 'jsonl');
    is(scalar @rows, 3, 'three records on one line');
};

# Large file streams across chunk boundaries (>64 KiB)
subtest 'large file streams across chunks' => sub {
    my $f = "$dir/big.jsonl";
    open my $fh, '>', $f or die $!;
    for my $i (1..5000) {
        print $fh qq({"id":$i,"name":"row$i"}\n);
    }
    close $fh;

    my $count = 0;
    my ($first, $last);
    File::Raw::each_line($f, sub {
        $count++;
        $first ||= { %{$_[0]} };
        $last    = { %{$_[0]} };
    }, plugin => 'jsonl');

    is($count, 5000, 'all 5000 records seen across chunks');
    is_deeply($first, {id => 1,    name => "row1"},    'first intact');
    is_deeply($last,  {id => 5000, name => "row5000"}, 'last intact');
};

# Die in callback propagates
subtest 'callback die propagates' => sub {
    my $f = "$dir/die.jsonl";
    File::Raw::spew($f, qq({"id":1}\n{"id":2}\n{"id":3}\n));
    eval {
        File::Raw::each_line($f, sub {
            die "stop\n" if $_[0]{id} == 2;
        }, plugin => 'jsonl');
    };
    like($@, qr/stop/, 'die in callback re-raised');
};

done_testing;
