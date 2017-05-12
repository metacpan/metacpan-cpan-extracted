#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

# Bind only to functions
use Inline RUBY => 'DATA', BIND_TYPE => [undef, 'functions'];

eval { my $obj = Smell->new };
# TEST
ok ($@, 'Unknown object Smell');

# TEST
is (some_func(), "bound", "some_func() exists and returns.");

__END__
__RUBY__

def some_func
  return "bound"
end

class Smell
  def how_bad
    return "very"
  end
end
