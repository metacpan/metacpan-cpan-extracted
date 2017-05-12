use strict;
use warnings;

use Test::More;
use Dios;

plan tests => 3;

func returns_int_1 (--> Int) { return 1;   }

func returns_num_1 (       --> Num) { return 1;   }
func returns_num_2 (       --> Num) { return 1.1; }
func returns_num_N (Num $x --> Num) { return $x; }

func returns_val_1 (         --> Value) { return 1;   }
func returns_val_2 (         --> Value) { return 1.1; }
func returns_val_3 (         --> Value) { return 'a'; }
func returns_val_N (Value $x --> Value) { return $x; }

func returns_def_1 (--> Def) { return 1;   }
func returns_def_2 (--> Def) { return 1.1; }
func returns_def_3 (--> Def) { return 'a'; }
func returns_def_4 (--> Def) { return [];  }

func returns_bool_1 (--> Bool) { return 1;     }
func returns_bool_2 (--> Bool) { return 1.1;   }
func returns_bool_3 (--> Bool) { return 'a';   }
func returns_bool_4 (--> Bool) { return [];    }
func returns_bool_5 (--> Bool) { return undef; }

func returns_any_1 (--> Any) { return 1;     }
func returns_any_2 (--> Any) { return 1.1;   }
func returns_any_3 (--> Any) { return 'a';   }
func returns_any_4 (--> Any) { return [];    }
func returns_any_5 (--> Any) { return undef; }

subtest 'Simple successful return' => sub {
    ok eval{ my $result = returns_int_1();     1; }, 'returns_int()'   ;
    ok eval{ my $result = returns_num_1();     1; }, 'returns_num_1()' ;
    ok eval{ my $result = returns_num_2();     1; }, 'returns_num_2()' ;
    ok eval{ my $result = returns_num_N(1);    1; }, 'returns_num_N()' ;
    ok eval{ my $result = returns_val_1();     1; }, 'returns_val_1()' ;
    ok eval{ my $result = returns_val_2();     1; }, 'returns_val_2()' ;
    ok eval{ my $result = returns_val_3();     1; }, 'returns_val_3()' ;
    ok eval{ my $result = returns_val_N('n');  1; }, 'returns_val_N()' ;
    ok eval{ my $result = returns_def_1();     1; }, 'returns_def_1()' ;
    ok eval{ my $result = returns_def_2();     1; }, 'returns_def_2()' ;
    ok eval{ my $result = returns_def_3();     1; }, 'returns_def_3()' ;
    ok eval{ my $result = returns_def_4();     1; }, 'returns_def_4()' ;
    ok eval{ my $result = returns_bool_1();    1; }, 'returns_bool_1()';
    ok eval{ my $result = returns_bool_2();    1; }, 'returns_bool_2()';
    ok eval{ my $result = returns_bool_3();    1; }, 'returns_bool_3()';
    ok eval{ my $result = returns_bool_4();    1; }, 'returns_bool_4()';
    ok eval{ my $result = returns_bool_5();    1; }, 'returns_bool_5()';
    ok eval{ my $result = returns_any_1();     1; }, 'returns_any_1()' ;
    ok eval{ my $result = returns_any_2();     1; }, 'returns_any_2()' ;
    ok eval{ my $result = returns_any_3();     1; }, 'returns_any_3()' ;
    ok eval{ my $result = returns_any_4();     1; }, 'returns_any_4()' ;
    ok eval{ my $result = returns_any_5();     1; }, 'returns_any_5()' ;
};

func doesnt_return_int_1 (--> Int)   { return 1.1;    }
func doesnt_return_num_1 (--> Num)   { return 'a';    }
func doesnt_return_num_2 (--> Num)   { return [];     }
func doesnt_return_val_1 (--> Value) { return [];     }
func doesnt_return_val_2 (--> Value) { return {a=>1}; }
func doesnt_return_def_1 (--> Def)   { return undef;  }

subtest 'Simple failure' => sub {
    ok !eval{ my $result = doesnt_return_int_1();  1; }, 'doesnt_return_int()'   ;
    ok !eval{ my $result = doesnt_return_num_1();  1; }, 'doesnt_return_num_1()' ;
    ok !eval{ my $result = doesnt_return_num_2();  1; }, 'doesnt_return_num_2()' ;
    ok !eval{ my $result = doesnt_return_num_2();  1; }, 'doesnt_return_num_2()' ;
    ok !eval{ my $result = doesnt_return_val_1();  1; }, 'doesnt_return_val_1()' ;
    ok !eval{ my $result = doesnt_return_val_2();  1; }, 'doesnt_return_val_2()' ;
    ok !eval{ my $result = doesnt_return_val_3();  1; }, 'doesnt_return_val_3()' ;
    ok !eval{ my $result = doesnt_return_def_1();  1; }, 'doesnt_return_def_1()' ;
};


func returns_in_context ($context --> Int|List[Int]|Void) {
    if (wantarray) {
        ok $context eq 'list',   'propagated list context into sub';
        return 1, 2, 3;
    }
    elsif (defined wantarray) {
        ok $context eq 'scalar', 'propagated scalar context into sub';
        return 42;
    }
    else {
        ok $context eq 'void',   'propagated void context into sub'
    }
}

func returns_in_void_context ($context --> Void) {}

subtest 'Context success' => sub {
    my @result;
    ok eval{ @result = returns_in_context('list'); 1; },   'list context tested correctly';
    is_deeply \@result, [1,2,3],                           'list context returned correct values';

    ok eval{ @result = scalar returns_in_context('scalar'); 1; },  'scalar context tested correctly';
    is_deeply \@result, [42],                              'scalar context returned correct values';

    local $SIG{__WARN__} = sub {
        like shift,
             qr/\QExplicit return type (--> Int) ignored by call to returns_in_context() in void context\E/,
             'correct warning in void context';
    };
    ok eval{ returns_in_context('void'); 1; },  'void context tested correctly';

    local $SIG{__WARN__} = sub {
        fail 'correct lack of warning in void context: ' . shift;
    };
    ok eval{ returns_in_void_context('void'); 1; },  'void context tested correctly';
};

done_testing();

