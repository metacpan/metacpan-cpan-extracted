use strict;
use warnings;
use Test::More tests => 11;

use Inline::Ruby qw/rb_eval rb_call_instance_method rb_iter/;
use Inline::Ruby::dRuby::Client;

my $drb_port = $ENV{'DRB_PORT'} || 10011;

rb_eval <<END;
require 'drb'

class TestAccessor
  attr_accessor :name, :number
end

class TestObject
  def string 
    'string foo bar'
  end

  def array
    [1,2,3,4,5]
  end

  def hash_result
    {
        'foo' => 'bar',
        'baz' => 'foo'
    }
  end

  def reflection(*args)
    args
  end

  def accessor(name, number)
    a = TestAccessor.new
    a.name = name
    a.number = number
    DRbObject.new a
  end

  def block_call(*args)
    yield *args
  end

  def error
    raise Exception, 'testerr'
  end
end

DRb.start_service('druby://localhost:$drb_port', TestObject.new)
END

sleep 1;

my $obj = Inline::Ruby::dRuby::Client->new('druby://localhost:' . $drb_port);

is($obj->string, 'string foo bar');
is_deeply($obj->array, [1,2,3,4,5]);
is_deeply($obj->hash_result, {
    foo => 'bar',
    baz => 'foo',
});

is(@{['string']}, @{$obj->reflection('string')});
is(@{[{'a' => 'b'}]}, @{$obj->reflection({'a' => 'b'})});
is(@{['string','arg2']}, @{$obj->reflection('string', 'arg2')});
is(@{[100]}, @{$obj->reflection(100)});

my $struct = $obj->accessor('yuichi', 20);
is('yuichi', $struct->name);
is(20, $struct->number);

# FIXME operator's call(equal etc...)
rb_call_instance_method($struct, 'name=', 'tateno');
is('tateno', $struct->name, 'set value with "=" operator');

is(rb_iter($obj, sub { 
    my $arg = shift; 
    return $arg * $arg; 
})->block_call(3), 9, 'call block');

