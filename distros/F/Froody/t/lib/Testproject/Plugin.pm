package Testproject::Plugin;
use strict;
use warnings;
use base 'Froody::Plugin';
use Froody::Invoker::PluginService;
use Froody::Method;
use Froody::API::XML;

sub new {
    my ($class, $impl, @arg) = @_;
    $impl->mk_accessors('session');
    return $class->SUPER::new($impl, @arg);
}

sub get_plugin_methods {
    my ($self, $impl) = @_;
    my (undef, $foo) = $impl->implements;
    $foo =~ s/\.\*//;
    
    return Froody::API::XML->load_spec(<<"XML");
<spec>
  <methods>
  <method name="$foo.session.invalidate">
     <response>
     </response>
  </method>
  </methods>
</spec>
XML
}

sub pre_process {
    my ($impl, $method, $params) = @_;
    my $session_id = delete $params->{session_id} || "";
    $impl->session($session_id);
    return;
}

## provided service methods:

sub invalidate {
    $main::plugin_invalidate_called = \@_;
    return {};
}

1;
 
