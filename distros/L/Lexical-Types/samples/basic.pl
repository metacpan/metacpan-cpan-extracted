#!perl

use strict;
use warnings;

use blib;

{ package Str; }

{
 package My::Types::Str;

 sub new { bless { }, shift }
}

use Lexical::Types as => sub { 'My::Types::' . $_[0] => 'new' };

my Str $x; # $x is now a My::Types::Str object
print ref($x), "\n"; # My::Types::Str;

{
 package My::Types::Int;

 sub TYPEDSCALAR { bless { }, shift }
}

use Lexical::Types;

use constant Int => 'My::Types::Int';

my Int $y; # $y is now a My::Types::Int object
print ref($y), "\n"; # My::Types::Int;
