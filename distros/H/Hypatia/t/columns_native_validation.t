#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
use Hypatia::Columns;
use Scalar::Util qw(blessed);

my $columns = Hypatia::Columns->new({columns=>{'x'=>'some_column_name',y=>'some_other_column_name'}});

ok(blessed($columns) eq 'Hypatia::Columns');
ok($columns->use_native_validation);
ok(@{$columns->column_types}==2 and $columns->column_types->[0] eq 'x' and $columns->column_types->[1] eq 'y');
ok($columns->columns->{x} eq 'some_column_name');
ok($columns->columns->{y} eq 'some_other_column_name');
