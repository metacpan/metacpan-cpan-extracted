package TestApp::Action::Bottom;

use Form::Factory::Processor;

extends qw( TestApp::Action::Middle );

has_control '+foo' => (
    features   => {
        fill_on_assignment => {
            no_warning => 1,
        },
        required => 0,
        length   => {
            maximum => 20,
        },
    },
); 

has_control baz => (
    control    => 'text',
);

has_checker foo_must_not_have_lowercase_letters => sub {
    my $self = shift;
    if ($self->controls->{foo}->current_value =~ /\p{IsLower}/) {
        $self->error('Foo must not contain lowercase letters');
        $self->result->is_valid(0);
    }
};

sub run {
    my $self = shift;
    $self->success('Done.');
}

1;
