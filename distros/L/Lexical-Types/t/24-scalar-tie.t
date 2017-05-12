#!perl -T

use strict;
use warnings;

{
 package Lexical::Types::Test::Str;

 sub TIESCALAR {
  my ($class, $buf) = @_;
  $class = ref($class) || $class;
  unless (defined $buf) {
   $buf = '';
  } elsif ($buf->isa($class)) {
   $buf = $buf->{buffer};
  }
  bless { buffer => $buf }, $class;
 }

 sub FETCH { shift->{buffer} }

 sub STORE {
  my ($self, $val) = @_;
  $self->{buffer} = (ref($val) && $val->isa(ref($self))) ? $val->{buffer}
                                                         : $val;
 }

 sub TYPEDSCALAR { tie $_[1], __PACKAGE__; () }
}

{ package Str; }

use Test::More tests => 2 * 6;

use Lexical::Types as => 'Lexical::Types::Test';

for (1 .. 2) {
 my Str $x = "abc";

 is ref(tied($x)), 'Lexical::Types::Test::Str', '$x';
 is "$x",          'abc',                       '$x contains the right thing';

 $x .= "foo";
 is ref(tied($x)), 'Lexical::Types::Test::Str', '$x . "foo"';
 is "$x",          'abcfoo',                    '$x . "foo" contains the right thing';

 my Str $y = "bar" . $x;

 is ref(tied($y)), 'Lexical::Types::Test::Str', '$y';
 is "$y",          'barabcfoo',                 '$y contains the right thing';
}
