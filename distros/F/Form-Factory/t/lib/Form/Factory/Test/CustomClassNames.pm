package Form::Factory::Test::CustomClassNames;

use Test::Class::Moose;
use Test::More;
use Test::Moose;

use Form::Factory;
use TestApp::Control::Null;
use TestApp::Feature::Null;
use TestApp::Feature::Control::Null;
use TestApp::Interface::Null;

sub custom_interface : Tests(1) {
    my $interface = Form::Factory->new_interface('Null');
    isa_ok($interface, 'TestApp::Interface::Null');
};

sub custom_control : Tests(1) {
    my $control = Form::Factory->control_class('null');
    is($control, 'TestApp::Control::Null');
};

sub custom_feature : Tests(1) {
    my $feature = Form::Factory->feature_class('null');
    is($feature, 'TestApp::Feature::Null');
};

sub custom_control_features : Tests(1) {
    my $feature = Form::Factory->control_feature_class('null');
    is($feature, 'TestApp::Feature::Control::Null');
};

1;
