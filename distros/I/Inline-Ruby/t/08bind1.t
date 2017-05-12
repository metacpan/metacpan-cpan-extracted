#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 3 }

# Bind only to classes
use Inline RUBY => 'DATA', BIND_TYPE => [undef, 'classes'];
ok(1);

my $obj = Smell->new;
ok($obj->how_bad, "very");

eval { some_func() };
ok($@);

__END__
__RUBY__

def some_func
  return "Not allowed to bind to me!"
end

class Smell
  def how_bad
    return "very"
  end
end
