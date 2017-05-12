#!/usr/bin/perl -w

use strict;
use Config;
use File::Spec::Functions;
use Java::JVM::Classfile::Perl;
use Test::More tests => 7;
use lib 'lib';

my $perl = $Config{'perlpath'};
$perl = $^X if $^O eq 'VMS';

my %classfiles = (
  Ackermann  => "Ack(3,5): 253\n",
  Bench      => '1, 1
1, 2
1, 3
1, 4
1, 5
1, 6
1, 7
1, 8
1, 9
2, 1
2, 2
2, 3
2, 4
2, 5
2, 6
2, 7
2, 8
2, 9
3, 1
3, 2
3, 3
3, 4
3, 5
3, 6
3, 7
3, 8
3, 9
4, 1
4, 2
4, 3
4, 4
4, 5
4, 6
4, 7
4, 8
4, 9
5, 1
5, 2
5, 3
5, 4
5, 5
5, 6
5, 7
5, 8
5, 9
6, 1
6, 2
6, 3
6, 4
6, 5
6, 6
6, 7
6, 8
6, 9
7, 1
7, 2
7, 3
7, 4
7, 5
7, 6
7, 7
7, 8
7, 9
8, 1
8, 2
8, 3
8, 4
8, 5
8, 6
8, 7
8, 8
8, 9
9, 1
9, 2
9, 3
9, 4
9, 5
9, 6
9, 7
9, 8
9, 9
',
  Fibo       => "89\n",
  FloatMath  => "3.25\n",
  HelloWorld => 'Hello, world!',
  LongMath   => "4294967296\n",
  Spin       => '1000',
);

foreach my $classfile (sort keys %classfiles) {
  my $expect = $classfiles{$classfile};
  $classfile = catfile('examples', $classfile . '.class');
  my $result = qx($perl class2perl.pl $classfile);
  is($result, $expect, "$classfile ok");
}


