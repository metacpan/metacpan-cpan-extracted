# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
use Data::Dumper;
use IO::Handle;


BEGIN { plan tests => 15 }
END {print "not ok 1\n" unless $loaded;}
use Inline 'Ruby';
IO::Handle->autoflush(1);

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# A non-method:
print "not " unless some_function(17) == 42;
print "ok 2\n";

# A non-method with an iterator:
print "not " unless iter(sub{ $_[0] + 25 })->some_iter(17) == 42;
print "ok 3\n";

# Create a new object:
my $o = Stumpme->new;

# Instance and class methods:
$o->inst_method(4, 5, 6);
Stumpme->class_method(7, 8, 9);

# With iterators:
$o->iter(sub{ print "ok $_[0]\n" })->inst_iterator(10, 11, 12);
Stumpme->iter(sub{ print "ok $_[0]\n" })->class_iterator(13, 14, 15);

__END__
__Ruby__

class Stumpme
  # This method does nothing important but happens to fix the call of
  # inst_method() upon first run - I'll investigate the exact problem
  # further -- Shlomi Fish
  def myfunc()
    return 3098;
  end
  def inst_method(*args)
    args.each { |x| print "ok #{x}\n" ; $stdout.flush; }
  end
  def Stumpme.class_method(*args)
    args.each { |x| print "ok #{x}\n" ; $stdout.flush; }
  end
  def inst_iterator(*args)
    args.each { |x| yield x }	# calls back into Perl
  end
  def Stumpme.class_iterator(*args)
    args.each { |x| yield x}	# calls back into Perl
  end
end

def some_function(a)
  print "Inside ruby's some_function(a) method. A is '#{a}'.\n"
  return 42
end

def some_iter(a)
  yield a
end

require 'stringio'

# Inherit from StringIO to test fix for https://rt.cpan.org/Ticket/Display.html?id=128484
class Test128484 < StringIO
  def a_method()
      # The code from the script attached to the bug report didn't
      # include this method and didn't reproduce the error when I put
      # it here. I'm not sure why, but adding this method caused the
      # bug to be provoked in this test script.
  end
end
