package TestApp::Action::Role::PartOne;

use Form::Factory::Processor::Role;

has_control part_one => (
    control => 'text',

    features => {
        required => 1,
        trim     => 1,
    },
);

has_cleaner foo => sub {
    my $self = shift;
    my $value = $self->controls->{part_one}->current_value;
    $self->controls->{part_one}->current_value(
        join '', reverse split //, $value
    );
};

1;
