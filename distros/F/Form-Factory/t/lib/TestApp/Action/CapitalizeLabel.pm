package TestApp::Action::CapitalizeLabel;

use Form::Factory::Processor;

use TestApp::Feature::Control::CapitalizeLabel;

has_control capitalize_label => (
    control   => 'text',
    options   => {
        label            => 'Capitalize Label',
    },
    features  => {
        capitalize_label => 1,
    },
);

sub run { }

1;
