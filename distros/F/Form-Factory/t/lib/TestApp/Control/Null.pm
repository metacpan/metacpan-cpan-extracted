package TestApp::Control::Null;

use Moose;

with qw( 
    Form::Factory::Control
    Form::Factory::Control::Role::ScalarValue
);

sub current_value { }

sub has_current_value { }

package Form::Factory::Control::Custom::Null;
sub register_implementation { 'TestApp::Control::Null' }

1;
