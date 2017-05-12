#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'String';
}

BEGIN { $t->use_ok('List::Parseable'); }

sub test {
  (@test)=@_;
  my $obj = new List::Parseable;
  $obj->string("a",@test);
  return $obj->eval("a");
}

$tests = '
"( scalar a b )"            => a b

"( ( a ) ( b ) )"           => a b

"(count a b)"               => 2

"( count a b )"             => 2

"( count ( list a b ) c )"  => 2

"( minval 3 5 7 )"          => 3

"( maxval 3 5 7 )"          => 7

"( mintrue 1 0 0 1 1 )"     => 1

"( mintrue 2 0 0 1 1 )"     => 1

"( mintrue 3 0 0 1 1 )"     => 0

"( maxtrue 1 0 0 1 1 )"     => 0

"( maxtrue 2 0 0 1 1 )"     => 1

"( maxtrue 3 0 0 1 1 )"     => 1

"( minfalse 1 0 0 1 1 )"    => 1

"( minfalse 2 0 0 1 1 )"    => 1

"( minfalse 3 0 0 1 1 )"    => 0

"( maxfalse 1 0 0 1 1 )"    => 0

"( maxfalse 2 0 0 1 1 )"    => 1

"( maxfalse 3 0 0 1 1 )"    => 1

"( numtrue 1 0 0 1 1 )"     => 0

"( numtrue 2 0 0 1 1 )"     => 1

"( numtrue 3 0 0 1 1 )"     => 0

"( numfalse 1 0 0 1 1 )"    => 0

"( numfalse 2 0 0 1 1 )"    => 1

"( numfalse 3 0 0 1 1 )"    => 0

"( and 0 0 0 )"             => 0

"( and 1 1 0 )"             => 0

"( and 1 1 1 )"             => 1

"( or 0 0 0 )"              => 0

"( or 1 1 0 )"              => 1

"( or 1 1 1 )"              => 1

"( not 0 0 0 )"             => 1

"( not 1 1 0 )"             => 0

"(sort foo bar baz)"        => bar baz foo

"(sort_by_method alphabetic (list foo bar baz))"
                            => bar baz foo

"(sort_by_method length (list bb x ccc))"
                            => x bb ccc

"(member a x y z)"          => 0

"(member y x y z)"          => 1

"(absent a x y z)"          => 1

"(absent y x y z)"          => 0

"(union (list a b) c (list d e))"
                            => a b c d e

"(unique a b [a c] [list a d])"
                            => a b c d

"(nth 0 a b [list a c] [d])" => a

"(nth 3 a b [list a c] [d])" => d

"(nth 4 a b [list a c] [d])" => __undef__

"(nth -1 a b [list a c] [d])" => d

"(nth -4 a b [list a c] [d])" => a

"(flatten (list a b) c (list d e))" => a b c d e

"(padchar 3 : a aa aaa aaaa)" => a:: aa: aaa aaaa

"(padchar -3 : a aa aaa aaaa)" => ::a :aa aaa aaaa

"(column 1 (list a b c) (list d) (list e f g))" => b f

"(case 1 a 1 b 1 c)" => a

"(case 0 a 0 b 1 c)" => c

"(case 0 a 0 b 0 c)" =>

"(case 1 a 1 b 1 c d)" => a

"(case 0 a 0 b 1 c d)" => c

"(case 0 a 0 b 0 c d)" => d

"(reverse a b c)" => c b a

"(rotate 2 a b c d e)" => c d e a b

"(rotate -2 a b c d e)" => d e a b c

"(delete a a b a c a d)" => b c d

"(clear a b c)" =>

"(append .txt a b c)" => a.txt b.txt c.txt

"(prepend foo .a .b .c)" => foo.a foo.b foo.c

"(splice [list a b c d] 1 0)" => a b c d

"(splice [list a b c d] 1 2)" => a d

"(splice [list a b c d] 1 0 e f)" => a e f b c d

"(splice [list a b c d] 1 2 e f)" => a e f d

"(slice 1 0 a b c d)" =>

"(slice 1 2 a b c d)" => b c

"( > 4 2 )" => 1

"( < 4 2 )" => 0

"(gt aa bb)" => 0

"(lt aa bb)" => 1

"(if 1)" => 1

"(if 0)" => 0

"(if 1 a)" => a

"(if 0 a)" => 0

"(if 1 a b)" => a

"(if 0 a b)" => b

"(is_equal [list a b c a] [list a a b c])" => 1

"(is_equal [list a b c a] [list a b c])" => 0

"(fill [list a a a])" => "" "" ""

"(fill [list a a a] 1)" => a "" ""

"(fill [list a a a] -2)" => a "" ""

"(fill [list a a a] 4)" => a a a "" ""

"(fill [list a a a] -5)" => "" "" a a a

"(fill [list a a a a] 1 2)" => a "" "" a

"(fill [list a a a a] 2 -2)" => a "" "" a

"(fill [list a a a a] -6 1)" => "" "" a a a a

"(fill [list a a a a] -5 2)" => "" "" a a a

"(fill [list a a a a] -5 6)" => "" "" "" "" "" ""

"(fill [list a a a a] 2 3)" => a a "" "" ""

"(fill [list a a] 3 1)" => a a "" ""

"(fill [list a a] 3 1 b)" => a a "" b

"(fill [list a a] -4 1 b)" => b "" a a

"(indexval a b a b a b)" => 1

"(indexval c b a b a b)" => -1

"(rindexval a b a b a b)" => 3

"(rindexval c b a b a b)" => -1

"(join a b c)" => "a b c"

"(join delim : a b c)" => a:b:c

"(difference [list a a b c] [list a])" => b c

"(d_difference [list a a b c] [list a])" => a b c

"(intersection [list a a b c] [list a a a b])" => a b

"(d_intersection [list a a b c] [list a a a b])" => a a b

"(symdiff [list a a b c] [list a a a b])" => c

"(d_symdiff [list a a b c] [list a a a b])" => c a

"( + 1 2 3 )" => 6

"( * 2 3 4 )" => 24

"( - 8.7 6.2 )" => 2.5

"( / 12 3 )" => 4

"(\ a [ ] )" => a "[" "]"

"(\ -- [ ] )" => "[" "]"

"(iff 0 1 0)" => 0

"(iff 0 0 0)" => 1

"(iff 1 1 1)" => 1

"(range 3 1 5)" => 1

"(range 1 1 5)" => 1

"(range 5 1 5)" => 1

"(range 0 1 5)" => 0

"(range 6 1 5)" => 0

"(rangeL 3 1 5)" => 1

"(rangeL 1 1 5)" => 0

"(rangeL 5 1 5)" => 1

"(rangeL 0 1 5)" => 0

"(rangeL 6 1 5)" => 0

"(rangeR 3 1 5)" => 1

"(rangeR 1 1 5)" => 1

"(rangeR 5 1 5)" => 0

"(rangeR 0 1 5)" => 0

"(rangeR 6 1 5)" => 0

"(rangeLR 3 1 5)" => 1

"(rangeLR 1 1 5)" => 0

"(rangeLR 5 1 5)" => 0

"(rangeLR 0 1 5)" => 0

"(rangeLR 6 1 5)" => 0

';

$t->tests(func => \&test,
          tests => $tests);
$t->done_testing();


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

