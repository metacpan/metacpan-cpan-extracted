package TestApp::Feature::Null;

use Moose;

with qw( Form::Factory::Feature );

package Form::Factory::Feature::Custom::Null;
sub register_implementation { 'TestApp::Feature::Null' }

1;
