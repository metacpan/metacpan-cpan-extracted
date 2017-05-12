package TestApp::Feature::Control::CapitalizeLabel;

use Moose;

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::BuildControl
    Form::Factory::Feature::Role::Control
);

sub check_control { }

sub build_control {
    my ($class, $options, $action, $name, $control) = @_;
    $control->{options}{label} = uc $control->{options}{label};
}

package Form::Factory::Feature::Control::Custom::CapitalizeLabel;
sub register_implementation { 'TestApp::Feature::Control::CapitalizeLabel' }

1;
