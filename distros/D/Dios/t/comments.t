use strict;
use warnings;

use Test::More;
use Test::Exception;

use Dios;

func foo (
    Int :$foo,              # this is foo
    Int :$bar               # this is bar
)
{
    "$foo and $bar";
}

func bar ( Int :$foo, Int :$bar )       # this is a signature
{
    "$foo and $bar";
}

func special_comment (
    $foo, # )
    $bar
)
{ 42 }

is foo(foo=>1, bar=>2), '1 and 2' => 'foo';
is bar(bar=>1, foo=>2), '2 and 1' => 'bar';
is special_comment('a','b'), 42 => 'special';

done_testing();
