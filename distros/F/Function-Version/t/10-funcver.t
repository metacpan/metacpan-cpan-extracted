# t/funcver.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(lib ../lib);
use Function::Version;

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);

$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);

BEGIN {
    use_ok( 'Function::Version' ) || print "Bail out!\n";
}

{ ## def() returns a class
$msg = 'def() returns a class';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" });
$got = $tmp;
$exp = 'Function::Version';
is($got, $exp, $msg);
}
{ ## func() returns a Function::Version instance
$msg = 'func() returns a Function::Version instance';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->func('load');
$got = ref $tmp;
$exp = 'Function::Version';
is($got, $exp, $msg);
}
{ ## func() selects the right function by name
$msg = 'func() selects the right function by name';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('dump', '1.5', sub { "dump v1.5: $_[0]" })
         ->func('dump');
$got = $tmp->ver('1.5')->with('words');
$exp = 'dump v1.5: words';
is($got, $exp, $msg);
}
{ ## ver() selects the correct function version
$msg = 'ver() selects the correct function version';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('load', '1.6', sub { "load v1.6: $_[0]" })
         ->func('load')
         ->ver('1.5');
$got = $tmp->with('vista');
$exp = 'load v1.5: vista';
is($got, $exp, $msg);
}
{ ## On the fly ver() call works
$msg = 'On the fly ver() call works';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('load', '1.6', sub { "load v1.6: $_[0]" })
         ->func('load')
         ->ver('1.5');
$got = $tmp->ver('1.6')->with('cats');
$exp = 'load v1.6: cats';
is($got, $exp, $msg);
}

{ ## Calling with without selecting a function dies
$msg = 'Calling with without selecting a function dies';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('load', '1.6', sub { "load v1.6: $_[0]" })
         ;
$tmp1 = eval { $tmp->with('cats') } || $@;
$got = $tmp1 =~ /Error. You have not selected a function./ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}
{ ## Reassigning to another function dies
$msg = 'Reassigning to another function dies';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('dump', '1.6', sub { "load v1.6: $_[0]" })
         ->func('dump')->ver('1.6')
         ;
$tmp1 = eval { $tmp->func('load')->with('cats') } || $@;
$got = $tmp1 =~ /Error: Assigned to 'dump' already./ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}
{ ## Selecting a function not in the definition dies
$msg = 'Selecting a function not in the definition dies';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('dump', '1.6', sub { "load v1.6: $_[0]" })
         ;
$tmp1 = eval { $tmp->func('loadx') } || $@;
$got = $tmp1 =~ /Error. Selected function 'loadx' not in definition./ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}
{ ## Selecting a version not in the definition dies
$msg = 'Selecting a version not in the definition dies';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('dump', '1.6', sub { "dump v1.6: $_[0]" })
         ->func('load')
         ;
$tmp1 = eval { $tmp->ver('1.60') } || $@;
$got = $tmp1 =~ /Error. Version '1.60' of 'load' not in definition./ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}
{ ## Must select a function before selecting the version
$msg = 'Must select a function before selecting the version';
$tmp = Function::Version
         ->def('load', '1.5', sub { "load v1.5: $_[0]" })
         ->def('dump', '1.6', sub { "dump v1.6: $_[0]" })
         ;
$tmp1 = eval { $tmp->ver('1.60') } || $@;
$got = $tmp1 =~ /Error. You have not selected a function./ ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}

done_testing;

