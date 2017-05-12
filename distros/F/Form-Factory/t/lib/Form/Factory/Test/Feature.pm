package Form::Factory::Test::Feature;

use Test::Class::Moose::Role;

use Test::More;
use Test::Moose;

has interface => (
    is         => 'ro',
    does       => 'Form::Factory::Interface',
    required   => 1,
    lazy       => 1,
    default    => sub { Form::Factory->new_interface('HTML') },
);

has action => (
    is         => 'ro',
    does       => 'Form::Factory::Action',
    required   => 1,
    lazy       => 1,
    default    => sub { 
        shift->interface->new_action('TestApp::Action::Featureful') 
    },
);

has feature => (
    is         => 'ro',
    does       => 'Form::Factory::Feature',
    required   => 1,
);

sub basic_feature_checks : Tests(6) {
    my $self = shift;
    my $feature = $self->feature;

    does_ok($feature, 'Form::Factory::Feature');

    if ($feature->does('Form::Factory::Feature::Role::BuildAttribute')) {
        can_ok($feature, qw( build_attribute ));
    }
    else {
        pass('not a cleaner');
    }

    if ($feature->does('Form::Factory::Feature::Role::Clean')) {
        can_ok($feature, qw( clean ));
    }
    else {
        pass('not a cleaner');
    }

    if ($feature->does('Form::Factory::Feature::Role::Check')) {
        can_ok($feature, qw( check ));
    }
    else {
        pass('not a checker');
    }

    if ($feature->does('Form::Factory::Feature::Role::PreProcess')) {
        can_ok($feature, qw( pre_process ));
    }
    else {
        pass('not a pre_processor');
    }

    if ($feature->does('Form::Factory::Feature::Role::PostProcess')) {
        can_ok($feature, qw( post_process ));
    }
    else {
        pass('not a post_processor');
    }
};

sub test_teardown {
    my $self = shift;
    $self->action->clear;
};

1;
