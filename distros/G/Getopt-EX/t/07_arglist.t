use v5.14;
use warnings;
use Test::More;
use Data::Dumper;

use Getopt::EX::Func;

*arg2kvlist = \&Getopt::EX::Func::arg2kvlist;

is_deeply([ arg2kvlist("arg1") ],
	  [ arg1 => 1 ], "no value");

is_deeply([ arg2kvlist("arg2=2") ],
	  [ arg2 => 2 ], "with value");

is_deeply([ arg2kvlist("arg1,arg2=2") ],
	  [ arg1 => 1, arg2 => 2 ], "mix");

is_deeply([ arg2kvlist("arg1,arg2=2,arg3=0") ],
	  [ arg1 => 1, arg2 => 2, arg3 => 0 ], "value 0");

is_deeply([ arg2kvlist("arg1,arg2=2,arg3=three") ],
	  [ arg1 => 1, arg2 => 2, arg3 => "three" ], "mix string");

is_deeply([ arg2kvlist("arg1,arg2=2,arg3=sub(),arg4") ],
	  [ arg1 => 1, arg2 => 2,
	    arg3 => "sub()", arg4 => 1 ], "paren");

is_deeply([ arg2kvlist("arg1,arg2=2,arg3=sub(x=1,y=sub(z(a,b))),arg4") ],
	  [ arg1 => 1, arg2 => 2,
	    arg3 => "sub(x=1,y=sub(z(a,b)))", arg4 => 1 ], "nested paren");

done_testing;

1;
