#!/usr/bin/perl

package Test;

use Benchmark;
$count = 10_000_000;
$foo = new Foo;

# import do_foo into this package, normally exported out of package Foo
# using Exporter but this is the key line of code that does it
*{Test::do_foo} = sub { Foo::do_foo() };

timethese( $count,
    {
        'OO'        => '$foo->do_foo()',
        'Function'  => 'Foo::do_foo()',
        'Import'    => 'do_foo()',
    }
);

# note that $oo and $ff got auto-vivified (not declared, made on first use)
# this is one of the reasons so many people write shit code in Perl.
printf "\nOO %d\nFF %d\n", $oo, $ff;

package Foo;

sub new { bless { key => 'val' }, shift }

sub do_foo { $_[0] ? $Test::oo++ : $Test::ff++ }

__DATA__
Benchmark: timing 10000000 iterations of Function, Import, OO...
  Function:  8 wallclock secs ( 7.99 usr +  0.00 sys =  7.99 CPU) @ 1251251.25/s (n=10000000)
    Import: 12 wallclock secs (12.72 usr +  0.00 sys = 12.72 CPU) @ 786225.33/s (n=10000000)
        OO:  9 wallclock secs ( 9.33 usr +  0.00 sys =  9.33 CPU) @ 1071352.05/s (n=10000000)

OO 10000000
FF 20000000
