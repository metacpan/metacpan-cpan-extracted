package TestApp::Action::Featureful;

use Form::Factory::Processor;

has_control fill_on_assignment => (
    is        => 'rw',
    control   => 'text',
    features  => {
        fill_on_assignment => 1,
    },
);

has_control length => (
    control   => 'text',
    features  => {
        length => {
            minimum => 5, 
            maximum => 10,
        },
    },
);

has_control match_available_choices => (
    control   => 'select_one',
    options   => {
        available_choices => [
            map { Form::Factory::Control::Choice->new($_) } qw( one two three )
        ],
    },
    features  => {
        match_available_choices => 1,
    },
);

has_control match_code => (
    control   => 'text',
    features  => {
        match_code => {
            code => sub { $_[0] % 2 == 0 },
        },
    },
);

has_control match_regex => (
    control   => 'text',
    features  => {
        match_regex => {
            regex => qr/(.)(.)(.)\3\2\1/,
        },
    },
);

has_control required => (
    control   => 'text',
    features  => {
        required => 1,
    },
);

has_control trim => (
    control   => 'text',
    features  => {
        trim => 1,
    },
);

sub run {
    my $self = shift;

    $self->result->content->{length}      = $self->length;
    $self->result->content->{match_available_choices} 
                                          = $self->match_available_choices;
    $self->result->content->{match_code}  = $self->match_code;
    $self->result->content->{match_regex} = $self->match_regex;
    $self->result->content->{required}    = $self->required;
    $self->result->content->{trim}        = $self->trim;
}

1;
