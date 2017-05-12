package TestApp::Action::Role::PartTwo;

use Form::Factory::Processor::Role;

has_control part_two => (
    control => 'text',

    features => {
        required => 1,
        trim     => 1,
    },
);

has_cleaner bar => sub {
    my $self = shift;
    my $value = $self->controls->{part_two}->current_value;
    $self->controls->{part_two}->current_value(
        join '', reverse split //, $value
    );
};

1;
