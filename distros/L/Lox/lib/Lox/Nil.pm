package Lox::Nil;
use strict;
use warnings;
use Lox::Bool;
use overload
  '""' => sub { 'nil' },
  '!'  => sub { $True },
  'bool' => sub { $False },
  fallback => 1;

use Exporter 'import';
my $u = undef;
our $Nil = bless \$u, 'Lox::Nil';
our @EXPORT = qw($Nil);
our $VERSION = 0.02;

1;
