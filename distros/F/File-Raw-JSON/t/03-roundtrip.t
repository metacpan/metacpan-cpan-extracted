#!/usr/bin/perl
use strict;
use warnings;
use utf8;             # source has Cyrillic + emoji literals
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Round-trip a varied set of structures. If Cpanel::JSON::XS is around,
# also cross-check decoded output.

my $dir = tempdir(CLEANUP => 1);

sub _round_trip {
    my ($value) = @_;
    my $f = "$dir/rt.json";
    File::Raw::spew($f, $value, plugin => 'json', sort_keys => 1);
    return File::Raw::slurp($f, plugin => 'json');
}

my @cases = (
    { name => 'flat scalar',      data => "hi" },
    { name => 'integer',          data => 42 },
    { name => 'array of mixed',   data => [1, "two", undef, [3, 4]] },
    { name => 'nested object',
      data => { user => { name => "alice", roles => ["admin", "user"] },
                ts => 12345 } },
    { name => 'deep nesting',
      data => { l1 => { l2 => { l3 => { l4 => { l5 => "leaf" }}}}} },
    { name => 'empty containers', data => { a => [], b => {} } },
    { name => 'unicode strings',  data => { name => "Жorgë", emoji => "\x{1f600}" } },
);

for my $c (@cases) {
    my $back = _round_trip($c->{data});
    is_deeply($back, $c->{data}, $c->{name});
}

SKIP: {
    eval { require Cpanel::JSON::XS; 1 }
        or skip "Cpanel::JSON::XS not installed", 1;
    my $cjxs = Cpanel::JSON::XS->new->utf8(1);
    my $f = "$dir/cmp.json";
    my $value = { a => 1, b => [2, 3, 4], c => { d => "hi" } };
    File::Raw::spew($f, $value, plugin => 'json', sort_keys => 1);
    my $bytes  = File::Raw::slurp($f);
    my $parsed = $cjxs->decode($bytes);
    is_deeply($parsed, $value, 'Cpanel::JSON::XS decodes our output identically');
}

done_testing;
