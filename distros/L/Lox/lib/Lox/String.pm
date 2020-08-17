package Lox::String;
use strict;
use warnings;
use Lox::Bool;
use overload
  '""' => sub { ${$_[0]} },
  'bool' => sub { $True },
  '!' => sub { $False },
  fallback => 0;

our $VERSION = 0.02;

sub new {
  my ($class, $string) = @_;
  return bless \$string, $class;
}

1;
