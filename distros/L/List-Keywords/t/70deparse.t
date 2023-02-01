#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Keywords ':all';

use B::Deparse;
my $deparser = B::Deparse->new();

sub is_deparsed
{
   my ( $sub, $exp, $name ) = @_;

   my $got = $deparser->coderef2text( $sub );

   # Deparsed output is '{ ... }'-wrapped
   $got = ( $got =~ m/^{\n(.*)\n}$/s )[0];

   # Deparsed output will have a lot of pragmata and so on; just grab the
   # final line
   $got = ( split m/\n/, $got )[-1];
   $got =~ s/^\s+//;

   is( $got, $exp, $name );
}

is_deparsed
   sub { first { $_ > 10 } 1 .. 10 },
   'first {$_ > 10;} 1..10;',
   'first {}';

is_deparsed
   sub { first my $x { $x > 10 } 1 .. 10 },
   'first my $x {$x > 10;} 1..10;',
   'first my $x {}';

is_deparsed
   sub { any { $_ > 10 } 1 .. 10 },
   'any {$_ > 10;} 1..10;',
   'any {}';

is_deparsed
   sub { all { $_ > 10 } 1 .. 10 },
   'all {$_ > 10;} 1..10;',
   'all {}';

is_deparsed
   sub { none { $_ > 10 } 1 .. 10 },
   'none {$_ > 10;} 1..10;',
   'none {}';

is_deparsed
   sub { notall { $_ > 10 } 1 .. 10 },
   'notall {$_ > 10;} 1..10;',
   'notall {}';

is_deparsed
   sub { reduce { $a + $b } 1 .. 5 },
   'reduce {$a + $b;} 1..5;',
   'reduce {}';

done_testing;
