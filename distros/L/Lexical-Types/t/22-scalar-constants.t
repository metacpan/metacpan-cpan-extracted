#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use constant Str => 'MyTypes::Str';
use constant Int => 'MyTypes::Int';
use constant Num => 'MyTypes::Num';

sub MyTypes::Str::new { "str:$_[0]" }

sub MyTypes::Int::new { "int:$_[0]" }

{ package MyTypes::Num }

{
 use Lexical::Types as => sub { $_[0] =~ /(?:Str|Int)/ ? ($_[0], 'new') : () };

 my Str $x;
 is $x, "str:MyTypes::Str", 'my constant_type $x';

 my Int ($y, $z);
 is $y, "int:MyTypes::Int", 'my constant_type ($y,';
 is $z, "int:MyTypes::Int", 'my constant_type  $z)';

 my Num $t;
 is $t, undef, 'my constant_type_skipped $t';

 my MyTypes::Str $u;
 is $u, "str:MyTypes::Str", 'my MyTypes::Str $u';

 my MyTypes::Num $v;
 is $v, undef, 'my MyTypes::Num $v';
}
