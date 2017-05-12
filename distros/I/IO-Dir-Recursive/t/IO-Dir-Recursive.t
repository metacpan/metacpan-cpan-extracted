use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok('IO::Dir::Recursive', 'DIR_NOUPWARDS') };

tie my %dirs, 'IO::Dir::Recursive', 't/tests';

is_deeply([sort keys %dirs], [qw(. .. bar foo)]);
is_deeply([sort keys %{$dirs{foo}}], [qw(. .. foobar moo)]);

tie %dirs, 'IO::Dir::Recursive', 't/tests', DIR_NOUPWARDS;

is_deeply([sort keys %dirs], [qw(bar foo)]), 
is_deeply([sort keys %{$dirs{foo}}], [qw(foobar moo)]);

isa_ok($dirs{bar}, 'IO::All');
isa_ok($dirs{foo}->{moo}, 'IO::All');
isa_ok($dirs{foo}->{foobar}->{moo}, 'IO::All');
