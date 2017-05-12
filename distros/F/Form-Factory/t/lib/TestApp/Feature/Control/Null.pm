package TestApp::Feature::Control::Null;

use Moose;

with qw( 
    Form::Factory::Feature
    Form::Factory::Feature::Role::Control
);

sub check_control { }

package Form::Factory::Feature::Control::Custom::Null;
sub register_implementation { 'TestApp::Feature::Control::Null' }

1;
