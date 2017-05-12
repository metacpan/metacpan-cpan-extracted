package TestApp::Action::Basic;

use Form::Factory::Processor;

my $counter = 0;

has value_to_defer => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has_control name => (
    control   => 'text',
    options   => {
        default_value => deferred_value { shift->value_to_defer },
    },
);

has_cleaner one => sub {
    my $self = shift;
    $self->result->content->{one} = ++$counter;
};

has_checker two => sub {
    my $self = shift;
    $self->result->content->{two} = ++$counter;
};

has_pre_processor three => sub {
    my $self = shift;
    $self->result->content->{three} = ++$counter;
};

has_post_processor five => sub {
    my $self = shift;
    $self->result->content->{five} = ++$counter;
};

sub run {
    my $self = shift;
    $self->result->content->{four} = ++$counter;
}

1;
