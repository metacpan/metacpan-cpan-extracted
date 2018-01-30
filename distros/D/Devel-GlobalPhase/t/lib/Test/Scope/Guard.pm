package
  Test::Scope::Guard;
use strict;
use warnings;
sub new { my ($class, $code) = @_; bless [$code], $class; }
sub DESTROY { my $self = shift; $self->[0]->() }
1;
