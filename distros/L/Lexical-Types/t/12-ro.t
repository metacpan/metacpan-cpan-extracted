#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

sub Str::TYPEDSCALAR { }

sub Str1::TYPEDSCALAR {
 $_[0] = 'derp';
 ();
}

sub Str2::TYPEDSCALAR {
 $_[2] = 'herp';
 ();
}

sub ro_re {
 my ($file, $line) = map quotemeta, @_;
 $file = '\\(eval \\d+\\)' unless $file;
 return qr/^Modification of a read-only value attempted at $file line $line/;
}

sub maybe_warn {
 diag 'This will throw two warnings' if "$]" >= 5.008_008 and "$]" < 5.009;
}

{
 maybe_warn();
 local $@;
 eval q!
  use Lexical::Types as => sub { $_[0] = 'derp'; () };
  my Str $x;
 !;
 like $@, ro_re('', 2), '$_[0] in initializer is read only';
}

SKIP: {
 skip 'Kinda broken on old 5.8.x' => 1 if "$]" <= 5.008_006;
 maybe_warn();
 local $@;
 eval q!
  use Lexical::Types as => sub { $_[1] = 'herp'; () };
  my Str $x;
 !;
 like $@, ro_re('', 2), '$_[1] in initializer is read only';
}

{
 local $@;
 eval q[
  use Lexical::Types;
  my Str1 $x;
 ];
 like $@, ro_re($0, 11), '$_[0] in initializer is read only';
}

{
 local $@;
 eval q[
  use Lexical::Types;
  my Str2 $x;
 ];
 like $@, ro_re($0, 16), '$_[2] in initializer is read only';
}
