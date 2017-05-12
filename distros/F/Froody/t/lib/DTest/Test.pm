# test that loading of FAPI classes occur
package DTest::Test;
use base qw(Froody::Implementation);

use strict;
use warnings;

sub implements { DTest => "foo.test.*" }

sub sloooow { sleep 300; die 'should never get here' }

sub add { return { '-text' => "\x{e9}" } }

sub echo { return { '-text' => $_[1]->{echo} } }

sub getGroups { return { '-text' => "\x{2264}" } }

sub thunktest { 
  my ($class, $params) = @_;
  return { '-text' => $params->{foo} + 1 }
}

sub empty { return {} }

use Froody::Error;
sub haltandcatchfire {
  Froody::Error->throw('test.error', "I'm on fire", {
    fire => '++good',
    napster => '++ungood',
  });
}

sub badhandler {
  Froody::Error->throw('test.badhandler.tripwire', "I'm just a catalyst for bad things");
}

sub badspec {
  return { bar => [1,2,3] };
}

sub error_handler {
  my ($self,$method, $error, $data) = @_;
  die "This shouldn't kill froody" if $method->name =~ /badhandler/;
  return $self->SUPER::error_handler($method, $error, $data);
}

1;
