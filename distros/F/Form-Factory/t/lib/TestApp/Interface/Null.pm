package TestApp::Interface::Null;

use Moose;

with qw( Form::Factory::Interface );

sub render_control {}

sub consume_control {}

package Form::Factory::Interface::Custom::Null;
sub register_implementation { 'TestApp::Interface::Null' }

1;
