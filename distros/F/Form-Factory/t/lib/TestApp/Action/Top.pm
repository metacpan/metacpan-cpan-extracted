package TestApp::Action::Top;

use Form::Factory::Processor;

has_control foo => (
    control   => 'text',
    features  => {
        trim     => 1,
        required => 1,
        length   => {
            minimum => 10,
        },
    },
);

has_checker foo_must_not_have_uppercase_letters => sub {
    my $self = shift;
    if ($self->controls->{foo}->current_value =~ /\p{IsUpper}/) {
        $self->error('Foo must not contain uppercase letters');
        $self->result->is_valid(0);
    }
};

1;
