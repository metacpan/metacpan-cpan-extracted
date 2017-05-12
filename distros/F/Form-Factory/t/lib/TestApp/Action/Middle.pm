package TestApp::Action::Middle;

use Form::Factory::Processor;

extends qw( TestApp::Action::Top );

has_control bar => (
    control    => 'text',
);

has_checker foo_must_not_have_digits => sub {
    my $self = shift;
    if ($self->controls->{foo}->current_value =~ /\d/) {
        $self->error('Foo must not contain numbers');
        $self->result->is_valid(0);
    }
};

1;
