package Test2::Require::Perl510;

use strict;
use warnings;
use base qw( Test2::Require );

sub skip
{
  my($class) = @_;
  return undef if $] >= 5.010;
  return 'This test requires Perl 5.10';
}

1;
