use 5.014;
use Test::More;

plan tests => 18;

use Keyword::Declare;

keyword test ()             { q{pass 'test with no args'} }
keyword test (/\d+/ $n)     { qq{ for my \$n (1..$n) { pass "counted test \$n" } } }
keyword test (Block $block) {{{ subtest 'test with block' => sub <{$block}>; }}}

test;

test {
    pass 'test 1 in block';
    pass 'test 2 in block';
}

test 3;

{
    keyword test (Num $n) :prefer {{{ for my $n (1..<{$n}>) { pass "nested counted test $n" } }}}

    test {
        pass 'test 1 in nested block';
        pass 'test 2 in nested block';
    }

    test 3;
}

test 3;

{
    unkeyword test;

    sub test { is shift, 4 => 'non-keyword test'; }

    test 4;
}

test 5;

done_testing;

