package TestApp::Action::EveryControl;

use Form::Factory::Processor;

has_control button => (
    control   => 'button',
    options   => {
        label => 'Foo',
    },
    documentation => 'a button',
);

has_control checkbox => (
    control   => 'checkbox',
    options   => {
        true_value  => 'xyz',
        false_value => 'abc',
    },
    documentation => 'a checkbox',
);

has_control full_text => (
    control   => 'full_text',
    documentation => 'some text',
);

has_control password  => (
    control   => 'password',
    documentation => 'a password',
);

has_control select_many => (
    control   => 'select_many',
    options   => {
        available_choices => [
            map { Form::Factory::Control::Choice->new($_) } 
              qw( one two three four five )
        ],
    },
    documentation => 'select a few',
);

has_control select_one => (
    control   => 'select_one',
    options   => {
        available_choices => [
            map { Form::Factory::Control::Choice->new($_) } 
              qw( ay bee see dee ee )
        ],
    },
    documentation => 'pick one',
);

has_control text => (
    documentation => 'short text',
);

has_control value => (
    control   => 'value',
    options   => {
        value => 'galaxy',
    },
    documentation => 'a value',
);

sub run {
    my $self = shift;

    $self->result->content->{button}      = $self->button;
    $self->result->content->{checkbox}    = $self->checkbox;
    $self->result->content->{full_text}   = $self->full_text;
    $self->result->content->{password}    = $self->password;
    $self->result->content->{select_many} = $self->select_many;
    $self->result->content->{select_one}  = $self->select_one;
    $self->result->content->{text}        = $self->text;
    $self->result->content->{value}       = $self->value;
}

1;
