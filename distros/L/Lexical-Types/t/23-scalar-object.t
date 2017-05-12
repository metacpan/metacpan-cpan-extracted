#!perl -T

use strict;
use warnings;

{
 package Lexical::Types::Test::Str;

 use overload '.'      => \&_concat,
              '""'     => \&_interpolate,
              'cmp'    => \&_cmp,
              fallback => 1;

 sub new {
  my ($class, $buf) = @_;
  $class = ref($class) || $class;
  unless (defined $buf) {
   $buf = '';
  } elsif ($buf->isa($class)) {
   $buf = $buf->{buffer};
  }
  bless { buffer => $buf }, $class;
 }

 sub _concat {
  my ($self, $str, $r) = @_;
  $self->new($r ? $str . $self->{buffer} : $self->{buffer} . $str);
 }

 sub _interpolate { shift->{buffer} }

 sub _cmp {
  my ($a, $b, $r) = @_;
  my $bufa = ref($a) ? $a->{buffer} : $a;
  my $bufb = ref($b) ? $b->{buffer} : $b;
  my $res = $bufa cmp $bufb;
  $res = -$res if $r;
  return $res;
 }

 sub _typedscalar { __PACKAGE__->new() }
}

{
 package Str;
}

use Test::More tests => 2 * 6;

use Lexical::Types as => sub {
 return 'Lexical::Types::Test::' . $_[0],
        '_' . lc($_[1])
};

for (1 .. 2) {
 my Str $x;

 isa_ok $x,   'Lexical::Types::Test::Str', '$x';
 is     "$x", '',                          '$x contains the right thing';

 $x .= "foo";
 isa_ok $x,   'Lexical::Types::Test::Str', '$x . "foo"';
 is     "$x", 'foo',                       '$x . "foo" contains the right thing';

 $x = "bar" . $x;
 isa_ok $x,   'Lexical::Types::Test::Str', '"bar" . $x';
 is     "$x", 'barfoo',                    '"bar" . $x contains the right thing';
}
