# testing sort on dates


use strict;
use warnings;
use Test::More tests => 6 ;

BEGIN {use_ok("Hash::Type");}

my ($headerline, @datalines) =  map {chomp; $_} <DATA>;
my $ht = new Hash::Type(split /\t/, $headerline);
isa_ok($ht, 'Hash::Type');
my @vals;
push @vals, new $ht(split /\t/) foreach @datalines;

my $cmp = $ht->cmp("d1:d.m.y, line:num");
my @v1 = map {"$_->{txt} ($_->{line})"} sort $cmp @vals;
ok(eq_array(\@v1, [
          'jan 3d, 1999 (8)',
          'jan 2nd, 2000 (7)',
          'dec 31st, 2000 (5)',
          'jan 1st, 2001 (1)',
          'jan 1st, 2001 (2)',
          'jan 2nd, 2001 (6)',
          'feb 1st, 2001 (3)',
          'feb 2nd, 2001 (4)'
        ]), "sort d1:d.m.y, line:num");


$cmp = $ht->cmp("d1 : -d.m.y, line : -num");
@v1 = map {"$_->{txt} ($_->{line})"} sort $cmp @vals;
ok(eq_array(\@v1, [
          'feb 2nd, 2001 (4)',
          'feb 1st, 2001 (3)',
          'jan 2nd, 2001 (6)',
          'jan 1st, 2001 (2)',
          'jan 1st, 2001 (1)',
          'dec 31st, 2000 (5)',
          'jan 2nd, 2000 (7)',
          'jan 3d, 1999 (8)'
        ]), "sort d1 : -d.m.y, line : -num");

$cmp = $ht->cmp("d2: y-m-d, line: -num");
@v1 = map {"$_->{txt} ($_->{line})"} sort $cmp @vals;
ok(eq_array(\@v1, [
          'jan 3d, 1999 (8)',
          'jan 2nd, 2000 (7)',
          'dec 31st, 2000 (5)',
          'jan 1st, 2001 (2)',
          'jan 1st, 2001 (1)',
          'jan 2nd, 2001 (6)',
          'feb 1st, 2001 (3)',
          'feb 2nd, 2001 (4)'
        ]), "sort d2: y-m-d, line: -num");

$cmp = $ht->cmp("d3: m/d/y, line: -num");
@v1 = map {"$_->{txt} ($_->{line})"} sort $cmp @vals;
ok(eq_array(\@v1, [
          'jan 3d, 1999 (8)',
          'jan 2nd, 2000 (7)',
          'dec 31st, 2000 (5)',
          'jan 1st, 2001 (2)',
          'jan 1st, 2001 (1)',
          'jan 2nd, 2001 (6)',
          'feb 1st, 2001 (3)',
          'feb 2nd, 2001 (4)'
        ]), "sort d3: m/d/y, line: -num");

__DATA__
line	d1	d2	d3	txt
1	1.1.1	2001-1-1	1/1/1	jan 1st, 2001
2	01.01.0001	1-1-1	1/1/2001	jan 1st, 2001
3	1.2.1	1-2-1	2/1/2001	feb 1st, 2001
4	2.2.1	1-2-2	2/2/1	feb 2nd, 2001
5	31.12.2000	0-12-31	12/31/00	dec 31st, 2000
6	2.1.1	1-1-2	1/2/01	jan 2nd, 2001
7	2.1.0	0-2-1	1/2/2000	jan 2nd, 2000
8	3.1.99	1999-1-3	1/3/99	jan 3d, 1999
