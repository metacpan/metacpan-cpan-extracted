use Test::More;

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

done_testing;
