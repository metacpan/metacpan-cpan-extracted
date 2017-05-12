# various sort tests
# test data borrowed from Sort::Field module by Joseph N. Hall

use strict;
use warnings;
use Test::More tests => 7 ;

BEGIN {use_ok("Hash::Type");}


my ($headerline, @datalines) =  map {chomp; $_} <DATA>;
my $ht = new Hash::Type(split /\t/, $headerline);
isa_ok($ht, 'Hash::Type');
my @vals;
push @vals, new $ht(split /\t/) foreach @datalines;


my $cmp = $ht->cmp("f1");
my @v1 = map {@{$_}{qw(f1 f2 f3 f4)}} sort $cmp @vals;
ok(eq_array(\@v1, [qw{
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet
}]), "alpha sort on column 1");

$cmp = $ht->cmp("f1:num");
@v1 = map {@{$_}{qw(f1 f2 f3 f4)}} sort $cmp @vals;


ok(eq_array(\@v1, [qw{
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
}]), "numeric sort on column 1");

$cmp = $ht->cmp("f1:-num");
@v1 = map {@{$_}{qw(f1 f2 f3 f4)}} sort $cmp @vals;

ok(eq_array(\@v1, [qw{
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  91    fdgs  3.43   ewet
  51    erwt  34.2   ewet
  43    rewq  2.12   ewet
  32    ewq   2.32   asdd
  23    erww  4.21   ewet
}]), "reverse numeric sort on column 1");


$cmp = $ht->cmp("f2");
@v1 = map {@{$_}{qw(f1 f2 f3 f4)}} sort {
	&{$cmp} || "@{$a}{qw(f1 f2 f3 f4)}" cmp "@{$b}{qw(f1 f2 f3 f4)}" 
} @vals;
ok(eq_array(\@v1, [qw{
  123   asd   1.22   asdd
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  91    fdgs  3.43   ewet
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  43    rewq  2.12   ewet
}]), "alpha sort on column 2, then alpha on entire line");


$cmp = $ht->cmp("f4, f1 : <=>, f3 : -num");
@v1 = map {@{$_}{qw(f1 f2 f3 f4)}} sort $cmp @vals;
ok(eq_array(\@v1, [qw{
  32    ewq   2.32   asdd
  123   refs  4.32   asdd
  123   refs  3.22   asdd
  123   asd   1.22   asdd
  23    erww  4.21   ewet
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet
}]), "alpha sort on column 4, then numeric on column 1, then reverse numeric on column 3");


__DATA__
f1	f2	f3	f4
123	asd	1.22	asdd
32	ewq	2.32	asdd
43	rewq	2.12	ewet
51	erwt	34.2	ewet
23	erww	4.21	ewet
91	fdgs	3.43	ewet
123	refs	3.22	asdd
123	refs	4.32	asdd
