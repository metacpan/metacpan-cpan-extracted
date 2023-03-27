use strict;
use Lexical::Var '$foo' => \(my$x=2);
push @main::values, $foo;
1;
