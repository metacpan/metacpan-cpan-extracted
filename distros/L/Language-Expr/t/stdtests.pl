use boolean;

sub stdvars {
    return +{
        a => 1,
        b => 2,
        'a b' => 3,
        'Language::Expr::Compiler::perl::b' => 2,
        ary1 => [qw/one two three/],
        hash1 => {one=>1, two=>2, three=>3},
    };
}

sub stdtests {
    return (
    # literal num
    {category=>'literal num', text=>'-0x1f', result=>-31},
    {category=>'literal num', text=>'0b100', result=>4},
    {category=>'literal num', text=>'-0o17', result=>-15},
    {category=>'literal num', parse_error=>qr/invalid syntax/i, text=>'0x1g'},
    {category=>'literal num', parse_error=>qr/invalid syntax/i, text=>'-0b2'},
    {category=>'literal num', parse_error=>qr/invalid syntax/i, text=>'0o18'},

    # array
    {category=>'array', text=>'[]', result=>[]},
    {category=>'array', text=>'[1,2]', result=>[1, 2]},
    {category=>'array', text=>'[1, 2, 3+4]', result=>[1, 2, 7]},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>'['},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>']'},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>'[,]'},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>'[1,]'},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>'[1 2]'},
    {category=>'array', parse_error=>qr/invalid syntax/i, text=>'[a]'},

    # hash
    {category=>'hash', text=>'{}', result=>{}, php_result=>[]}, # due to ambiguity of php arrays
    {category=>'hash', text=>'{a=>1}', result=>{a=>1}},
    {category=>'hash', text=>q[{'a'=>1}], result=>{a=>1}},
    {category=>'hash', text=>q[{"a b"=>1}], result=>{"a b"=>1}},
    {category=>'hash', text=>'{("a"."b")=>1}', parse_error=>qr/invalid syntax/i, xresult=>{ab=>1}}, # many languages (e.g. php and js) don't support expression before "=>", so we disallow them for the moment
    {category=>'hash', text=>'{a=>1, "b c"=>1+1}', result=>{a=>1, "b c"=>2}},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{=>}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{a=>}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{=>1}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{a, 1}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{a=>1, }'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'{1=>a}'},
    {category=>'hash', parse_error=>qr/invalid syntax/i, text=>'a=>1'},

    # comparison equal
    {category=>'comparison equal num', text=>'1 == 2', result=>false},
    {category=>'comparison equal num', text=>'1 == 1', result=>true},
    {category=>'comparison equal num', text=>'1 != 2', result=>true},
    {category=>'comparison equal num', text=>'1 != 1', result=>false},
    {category=>'comparison equal num', text=>'0 == 0', result=>true},
    {category=>'comparison equal num', text=>'3 <=> 4', result=>-1},
    {category=>'comparison equal num', text=>'4 <=> 3', result=>1},
    {category=>'comparison equal num', text=>'3 <=> 3', result=>0},
    {category=>'comparison equal num', text=>'3 <=> 3', result=>0},

    {category=>'comparison equal chained', text=>"0 == 1 == 0", result=>false},
    {category=>'comparison equal chained', text=>"2 == 2 == 2", result=>true},
    {category=>'comparison equal chained', text=>"0 eq 1 eq ''", result=>false},
    {category=>'comparison equal chained', text=>"2 != 3 != 1", result=>true},

    {category=>'comparison equal str', text=>'"" eq ""', result=>true},
    {category=>'comparison equal str', text=>'"aa" cmp "ab"', result=>-1},

    # comparison less_greater
    {category=>'comparison less_greater', text=>'1<2', result=>true},
    {category=>'comparison less_greater', text=>'2<2', result=>false},
    {category=>'comparison less_greater', text=>'3<2', result=>false},
    {category=>'comparison less_greater', text=>'1 <= 2', result=>true},
    {category=>'comparison less_greater', text=>'1 <= 1', result=>true},
    {category=>'comparison less_greater', text=>'3 <= 2', result=>false},
    {category=>'comparison less_greater', text=>'1>2', result=>false},
    {category=>'comparison less_greater', text=>'2>2', result=>false},
    {category=>'comparison less_greater', text=>'3>2', result=>true},
    {category=>'comparison less_greater', text=>'1 >= 2', result=>false},
    {category=>'comparison less_greater', text=>'1 >= 1', result=>true},
    {category=>'comparison less_greater', text=>'3 >= 2', result=>true},

    {category=>'comparison less_greater chained', text=>'3 > 2 > 1', result=>true},
    {category=>'comparison less_greater chained', text=>'2 > 3 > 1', result=>false},
    {category=>'comparison less_greater chained', text=>'2 > 3 < 1', result=>false},

    {category=>'comparison less_greater', parse_error=>qr/invalid syntax/i, text=>'>'},
    {category=>'comparison less_greater', parse_error=>qr/invalid syntax/i, text=>'1 >'},
    {category=>'comparison less_greater', parse_error=>qr/invalid syntax/i, text=>'> 1'},
    #{category=>'comparison less_greater', parse_error=>qr/invalid syntax/i, text=>'1 > 0 >'}, # RG bug? causes subsequent parsing to fail
    {category=>'comparison less_greater', parse_error=>qr/invalid syntax/i, text=>'< 1 < 2'},

    # and
    {category=>'and', text=>'1 && 2', result=>'2'},
    {category=>'and', text=>'1 && 0', result=>'0'},
    {category=>'and', text=>'1 > 1 && 1 >= 1', result=>false},
    {category=>'and chained', text=>'1 > 1 && 1 > 1', result=>false},

    # or & xor
    {category=>'or_xor', text=>'1 || 2', result=>true},
    {category=>'or_xor', text=>'1 || 0', result=>true},
    {category=>'or_xor', text=>'1 > 1 || 1 >= 1', result=>true},
    {category=>'or_xor', text=>'1 > 1 || 1 > 1', result=>false},
    {category=>'or_xor', text=>'1 // 2', result=>1},
    {category=>'or_xor', text=>'1 // undef', result=>1},
    {category=>'or_xor', text=>'undef // 2', result=>2},
    {category=>'or_xor', text=>'undef // undef', result=>undef},

    # ternary

    # commented, if enabled, will cause further parsing to fail
    #{category=>'ternary', text=>'1 : 1', parse_error=>qr/invalid syntax for ternary/i},
    #{category=>'ternary', text=>'1 ? 1', parse_error=>qr/invalid syntax for ternary/i},
    #{category=>'ternary', text=>'1 ? 1 ? 1', parse_error=>qr/invalid syntax for ternary/i},
    #{category=>'ternary', text=>'1 : 1 ? 1', parse_error=>qr/invalid syntax for ternary/i},
    #{category=>'ternary', text=>'1 : 1 : 1', parse_error=>qr/invalid syntax for ternary/i},

    #{category=>'ternary', text=>'1 ? 1 ? 1 : 1 : 1', parse_error=>qr/invalid syntax for ternary/i}, # chained is not supported yet
    {category=>'ternary', text=>'1==1 ? "a":"b"', result=>"a"},
    {category=>'ternary', text=>'1==0 ? "a":"b"', result=>"b"},
    {category=>'ternary', text=>'1==1 ? (2==2 ? "a":"b") : "c"', result=>"a"},
    {category=>'ternary', text=>'1==1 ? (2==3 ? "a":"b") : "c"', result=>"b"},
    {category=>'ternary', text=>'1==0 ? (2==2 ? "a":"b") : "c"', result=>"c"},
    {category=>'ternary', text=>'1==0 ? (2==3 ? "a":"b") : "c"', result=>"c"},

    # add
    {category=>'add', text=>'1+1', result=>'2'},
    {category=>'add', text=>'1+1+4+7', result=>'13'},
    {category=>'add', text=>'1-1', result=>'0'},
    {category=>'add', text=>'10-2-5-1', result=>'2'},
    {category=>'add', text=>'10+2-5+1', result=>'8'},
    {category=>'add', text=>'1 . 1', result=>'11'},
    {category=>'add', text=>'"satu "."dua"', result=>'satu dua'},

    # mult
    {category=>'mult', text=>'2*4', result=>'8'},
    {category=>'mult', text=>'2*-1*-4*7', result=>'56'},
    {category=>'mult', text=>'6/2', result=>'3'},
    {category=>'mult', text=>'80/2/5/4', result=>'2'},
    {category=>'mult', text=>'80/2/5*4', result=>'32'},
    {category=>'mult', text=>'80 % 3', result=>'2'},
    {category=>'mult', text=>'800 % 30 % 3', result=>'2'},
    {category=>'mult', text=>'"ab" x 2', result=>'abab'},
    {category=>'mult', text=>'"ab" x 2 x 2', result=>'abababab'},

    # pow
    {category=>'power', text=>'2**4', result=>'16'},
    {category=>'power', text=>'2**4**2', result=>'65536'},

    # unary
    {category=>'unary', text=>'!2', result=>false},
    {category=>'unary', text=>'!!2', result=>true},
    {category=>'unary', text=>'!!2', result=>true},
    {category=>'unary', text=>'--2', result=>2},
    {category=>'unary', text=>'---2', result=>-2},
    {category=>'unary', text=>'~2', result=>~2, js_result=>(-(2)-1), php_result=>(-(2)-1)},

    # bitwise
    {category=>'bit', text=>'3|5', result=>'7'},
    {category=>'bit', text=>'3 & 5', result=>'1'},
    {category=>'bit', text=>'3 ^ 5', result=>'6'},
    # ~, see unary
    {category=>'bit', text=>'3 << 2', result=>'12'},
    {category=>'bit', text=>'3 << 2+1', result=>'24'},
    {category=>'bit', text=>'12 >> 2', result=>'3'},
    {category=>'bit', text=>'24 >> 2+1', result=>'3'},

    # term:literal
    {category=>'undef', text=>'undef', result=>undef},
    {category=>'true', text=>'true', result=>true},
    {category=>'false', text=>'false', result=>false},
    {category=>'num', text=>'1', result=>'1'},
    {category=>'num', text=>'1.1', result=>'1.1'},
    {category=>'dquotestr', text=>q("satu ' dua"), result=>"satu ' dua"},
    {category=>'squotestr', text=>q('satu " dua'), result=>'satu " dua'},
    {category=>'squotestr escape sequence', text=>q('\\''), result=>'\''},
    {category=>'squotestr escape sequence', text=>q('\\"'), result=>'\\"'},
    {category=>'squotestr escape sequence', text=>q('\\\\'), result=>'\\'},
    {category=>'squotestr escape sequence', text=>q('\\n'), result=>'\n'},

    {category=>'dquotestr escape sequence', text=>q("\\'"), result=>'\''},
    {category=>'dquotestr escape sequence', text=>q("\\""), result=>'"'},
    {category=>'dquotestr escape sequence', text=>q("\\\\"), result=>'\\'},
    {category=>'dquotestr escape sequence', text=>q("\\$"), result=>'$'},
    {category=>'dquotestr escape sequence', text=>q("\\t"), result=>"\t"},
    {category=>'dquotestr escape sequence', text=>q("\\n"), result=>"\n"},
    {category=>'dquotestr escape sequence', text=>q("\\f"), result=>"\f"},
    {category=>'dquotestr escape sequence', text=>q("\\b"), result=>"\b"},
    {category=>'dquotestr escape sequence', text=>q("\\a"), result=>"\a"},
    {category=>'dquotestr escape sequence', text=>q("\\e"), result=>"\e"},
    {category=>'squotestr', text=>q('@b'), result=>'@b'}, # to test perl compiler properly escaping "@foo"
    {category=>'dquotestr', text=>'"@b"', result=>'@b'}, # to test perl compiler properly escaping "@foo"
    {category=>'squotestr interpolate var', text=>q('$a'), result=>'$a'},
    {category=>'squotestr interpolate var', text=>q('${a}'), result=>'${a}'},
    {category=>'dquotestr interpolate var', text=>q("$a"), result=>1},
    {category=>'dquotestr interpolate var', text=>q("${a}"), result=>1},

    # term:paren
    {category=>'paren', text=>'4*(2 + 3)', result=>'20'},
    {category=>'paren', text=>'-(1+1)', result=>'-2'},
    {category=>'paren', text=>'(((2)))', result=>'2'},
    {category=>'paren', text=>'2**(1+1+1+1+1 + 1+1+1+1+1)', result=>'1024'},
    {category=>'paren', text=>'(2)+((3))+(((4)))+((((5))))+(((((6)))))', result=>'20'},

    # term:var
    {category=>'var', text=>'$b', result=>'2'},
    {category=>'var', text=>q[${a b}], result=>'3', compiler_run_error=>qr/Bareword found|Syntax error/i, js_compiler_run_error=>qr/syntax\s*error/i, php_compiler_run_error=>qr/syntax error/i},
    {category=>'var', text=>'$a+2*$b', result=>'5'},
    {category=>'var', text=>'$.', parse_error=>qr/invalid syntax/i}, # no longer allowed since 0.16
    {category=>'var', text=>'$..', parse_error=>qr/invalid syntax/i}, # no longer allowed since 0.16
    {category=>'var', text=>'$Language::Expr::Compiler::perl::b', result=>2, js_compiler_run_error=>qr/.*/, php_compiler_run_error=>qr/.*/}, # allowed since 0.16

    # term:subscript
    {category=>'subscripting', text => '$ary1[1]', result=>'two'},
    {category=>'subscripting', text => '$hash1["two"]', result=>'2'},
    {category=>'subscripting', text => '([10, 20, 30])[0]', result=>'10'},
    {category=>'subscripting', text => '([10, 20, 30])[2]', result=>'30'},
    {category=>'subscripting', text => '([1, 2, 3])[3]', result=>undef},
    {category=>'subscripting', text => '({a=>10, b=>20, "c 2" => 30})["b"]', result=>'20'},
    {category=>'subscripting', text => '({a=>10, b=>20, "c 2" => 30})["c 2"]', result=>'30'},
    {category=>'subscripting', text => '({a=>10, b=>20, "c 2" => 30})["x"]', result=>undef},
    {category=>'subscripting', text => '{a=>[10, 20]}["a"][1]', result=>20},
    #{category=>'subscripting', parse_error=>qr/subscript/i, text => '1[1]'}, # currently doesn't work, RG bug?

    {category=>'func', text=>'floor(3.6)', result=>'3'},
    {category=>'func', parse_error=>qr/invalid syntax/i, text => 'floor'},
    {category=>'func', parse_error=>qr/invalid syntax/i, text => 'floor 3.6'},
    {category=>'func', text=>'floor(3.6 + 0.4)', result=>4},
    {category=>'func', text=>'ceil(0.7)+floor(0.3+0.6)', result=>1},
    #{category=>'func', run_error => qr/unknown func|undefined sub/i, text=>'foo(1)', result=>'1'}, # BUG in RG? causes error: Can't use an undefined value as an ARRAY reference at (re_eval 252) line 2.

    # map=7
    {category=>'map', has_subexpr=>1, text=>'map {}, []', parse_error=>qr/invalid syntax/i}, # lack parenthesis
    {category=>'map', has_subexpr=>1, text=>'map({1<}, [])', parse_error=>qr/invalid syntax/i}, # invalid subexpression

    {category=>'map', has_subexpr=>1, text=>'map()', compiler_run_error=>qr/not enough arg/i, js_compiler_run_error=>qr/.+/i, php_compiler_run_error=>qr/undefined function map/i},
    #{category=>'map', has_subexpr=>1, text=>'map({}, [])'}, # empty subexpression. won't be parsed as map(), but ok.
    #{category=>'map', has_subexpr=>1, text=>'map(1, [])'}, # not subexpression. won't be parsed as map(), but ok. but in perl result will be 1.

    {category=>'map', has_subexpr=>1, text=>'map({$_*2}, {})', compiler_run_error=>qr/syntax error|unmatched right/i, js_compiler_run_error=>qr/.+/i, php_result=>[]}, # although doesn't make sense, parses. in php {} will become array() == [].
    {category=>'map', has_subexpr=>1, text=>'map({$_*2}, [])', result=>[]},
    {category=>'map', has_subexpr=>1, text=>'map({$_*2}, [1,2,3])', result=>[2, 4, 6]},
    {category=>'map', has_subexpr=>1, text=>'map({ map({$_+1}, [$_])[0] }, [1,2,3])', result=>[2, 3, 4]}, # nested map

    # grep=7
    {category=>'grep', has_subexpr=>1, text=>'grep {}, []', parse_error=>qr/invalid syntax/i}, # lack parenthesis
    {category=>'grep', has_subexpr=>1, text=>'grep({1<}, [])', parse_error=>qr/invalid syntax/i}, # invalid subexpression

    {category=>'grep', has_subexpr=>1,  text=>'grep()', compiler_run_error=>qr/not enough arg/i, js_compiler_run_error=>qr/.+/i, php_compiler_run_error=>qr/undefined function grep/i}, # lack arguments. won't be parsed as grep(), but ok
    #{category=>'grep', has_subexpr=>1, text=>'grep({}, [])'}, # empty subexpression. won't be parsed as grep(), but ok
    #{category=>'grep', has_subexpr=>1, text=>'grep(1, [])'}, # not subexpression. won't be parsed as grep(), but ok

    {category=>'grep', has_subexpr=>1, text=>'grep({$_>1}, {})', compiler_run_error=>qr/syntax error|unmatched right/i, js_compiler_run_error=>qr/.+/i, php_result=>[]}, # although doesn't make sense, parses. in php {} will become array() == [].
    {category=>'grep', has_subexpr=>1, text=>'grep({$_>1}, [])', result=>[]},
    {category=>'grep', has_subexpr=>1, text=>'grep({$_>1}, [1,2,3])', result=>[2, 3]},
    {category=>'grep', has_subexpr=>1, text=>'grep({ grep({$_ > 1}, [$_])[0] }, [1,2,3])', result=>[2, 3]}, # nested grep

    # usort=7
    {category=>'usort', has_subexpr=>1, text=>'usort {}, []', parse_error=>qr/invalid syntax/i}, # lack parenthesis
    {category=>'usort', has_subexpr=>1, text=>'usort({1<}, [])', parse_error=>qr/invalid syntax/i}, # invalid subexpression

    {category=>'usort', has_subexpr=>1, text=>'usort()', compiler_run_error=>qr/undefined sub.+usort/i, js_compiler_run_error=>qr/.+/i, php_compiler_run_error=>qr/usort\(\) expects exactly 2 parameters/i}, # lack arguments. won't be parsed as usort(), but ok
    #{category=>'usort', has_subexpr=>1, text=>'usort({}, [])'}, # empty subexpression. won't be parsed as usort(), but ok
    #{category=>'usort', has_subexpr=>1, text=>'usort(1, [])'}, # not subexpression. won't be parsed as usort(), but ok

    {category=>'usort', has_subexpr=>1, text=>'usort({uc($a) cmp uc($b)}, {})', compiler_run_error=>qr/syntax error|unmatched right/i, js_compiler_run_error=>qr/.+/i, php_result=>[]}, # although doesn't make sense, parses. in php {} becomes [].
    {category=>'usort', has_subexpr=>1, text=>'usort({uc($a) cmp uc($b)}, [])', result=>[]},
    {category=>'usort', has_subexpr=>1, text=>'usort({uc($a) cmp uc($b)}, ["B", "a", "C"])', result=>["a", "B", "C"]},
    {category=>'usort', has_subexpr=>1, text=>'usort({ usort({$b <=> $a}, [$a])[0] <=> usort({$b<=>$a}, [$b])[0] }, [3, 2, 1])', result=>[1, 2, 3]}, # nested usort

    # php compiler still has problems with use()
    {category=>'usort', has_subexpr=>1, php_skip=>1, text=>'map({$_[0]}, usort( {$a[1]<=>$b[1]}, map({[$_, length($_)]}, ["four", "one", "three"])))', result=>["one", "four", "three"]}, # schwartzian transform, map+usort+map, unnested
    {category=>'usort', has_subexpr=>1, php_skip=>1, text=>'usort({ map({length($_)}, $a)[0] <=> map({length($_)}, $b)[0] }, [["four"], ["one"], ["three"]])', result=>[["one"], ["four"], ["three"]]}, # map inside usort
    {category=>'usort', has_subexpr=>1, php_skip=>1, text=>'map({ usort({length($a)<=>length($b)}, $_) }, [["empat", "four"], ["one", "satu"], ["three", "tiga"]])', result=>[["four","empat"], ["one","satu"], ["tiga", "three"]]}, # map inside usort

);
}

1;
