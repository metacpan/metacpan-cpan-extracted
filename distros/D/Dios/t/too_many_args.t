use strict;
use warnings;

use Test::More;

use Dios;

func no_sig                                { return @_             }
func no_args()                             { return @_             }
func one_arg($foo)                         { return $foo           }
func two_args($foo, $bar)                  { return ($foo, $bar)   }
func array_at_end($foo, *@stuff)           { return ($foo, @stuff) }
func one_named(:$foo)                      { return $foo;          }
func one_named_one_positional($bar, :$foo) { return($foo, $bar)    }

note "too many arguments"; {
    ok !eval { no_sig(42); 1 },                                   "no args";
    like $@, qr{Func no_sig takes no arguments};

    ok !eval { no_args(42); 1 },                                   "no args";
    like $@, qr{Func no_args takes no arguments};

    ok !eval { one_arg(23, 42); 1 },                               "one arg";
    like $@, qr{Unexpected extra argument \(42\) in call to func one_arg};

    ok !eval { two_args(23, 42, 99, 100); 1 },                          "two args";
    like $@, qr{Unexpected extra arguments \(99, 100\) in call to func two_args};

    is_deeply [array_at_end(23, 42, 99)], [23, 42, 99],         "array at end";
}


note "with positionals"; {
    is one_named(foo => 42), 42;
    ok !eval { one_named(foo => 23, foo => 42); 1 };
    like $@, qr{Unexpected second value \(42\) for named 'foo' parameter in call to func one_named};


    is_deeply [one_named_one_positional(23, foo => 42)], [42, 23];
    ok !eval { one_named_one_positional(23, foo => 42, foo => 23); 1 };
    like $@, qr{Unexpected second value \(23\) for named 'foo' parameter in call to func one_named_one_positional};
}


#func slurpy_named (*:foo(@bar), *:@baz, *%etc) {
#    return { bar=>\@bar, baz=>\@baz, etc=>\%etc };
#}
#
#is_deeply [slurpy_named( baz=>'a', foo=>1, foo=>2, other=>'other', baz=>'b', foo=>3, nother=>'nother'),
#          {
#            bar => [1,2,3],
#            baz => ['a','b'],
#            etc => {other=>'other', nother=>'nother',
#          }
#          => 'Named slurpies';


done_testing;
