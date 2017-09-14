#!/usr/bin/perl

# Test, whether the code that evaluates the namespace of loaded classes
# and modules compiles (was broken in Inline::Ruby 0.08).

use strict;

use Test::More tests => 2;

use Inline 'Ruby';

ok 1 => 'compiles';

is(httpdate(), 'Fri, 18 Aug 2017 01:23:45 GMT', 'httpdate')

__END__
__Ruby__
# Require a class with dependencies.
require 'time'

# Require a module with dependencies.
require 'tsort'

class Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end
end

{1=>[2, 3], 2=>[3], 3=>[], 4=>[]}.tsort

# Ruby seems to ignore the timezone.  So we have to use UTC.
def httpdate
    t = Time.parse('2017-08-18 01:23:45 UTC')
    return t.httpdate
end

