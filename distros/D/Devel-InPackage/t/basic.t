use strict;
use warnings;
use Devel::InPackage qw(in_package);
use Test::TableDriven (
    trivial     => { 1 => 'main' },
    foo         => { 1 => 'Foo', 2 => 'Foo' },
    bar         => { 1 => 'Foo', 2 => 'Foo', 4 => 'Bar' },
    nested      => { 1 => 'main', 2 => 'Foo', 3 => 'Foo', 4 => 'main', 5 => 'main' },
    class       => { 1 => 'Foo', 2 => 'Foo', 4 => 'main' },
    role        => { 1 => 'Foo', 2 => 'Foo', 4 => 'main' },
    pre_comment => { 1 => 'A', 2 => 'B', 3 => 'B' },
    comment     => { 1 => 'A', 2 => 'A', 3 => 'A' },
);

my %data = (
    trivial     => '1;',
    foo         => "package Foo;\n1;",
    bar         => "package Foo;\n1;\npackage Bar;\n1;",
    nested      => "{\n package Foo;\n 1;\n}\n2;\n",
    class       => "class Foo {\n <foo>\n}\n1;",
    role        => "role Foo with Baz {\n <foo>\n}\n1;",
    pre_comment => "package A;\n <code> package B;\n 1;",
    comment     => "package A;\n <code> # package B;\n 1;",
);

for my $func (keys %data){
    no strict 'refs';
    *{$func} = sub { my $line = shift; in_package( code => $data{$func}, line => $line ) };
}

runtests;
