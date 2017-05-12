package TestApp::Action::SplitValue;

use Form::Factory::Processor;

use TestApp::Feature::Control::SplitValue;

has_control manual_splitter => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },

    control   => 'text',
    options   => {
        value_to_control => '_join_value',
        control_to_value => '_split_value',
    },
    features  => {
        fill_on_assignment => 1,
    },
);

has_control feature_splitter => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },

    control   => 'text',
    features  => {
        split_value        => 1,
        fill_on_assignment => 1,
    },
);

sub _join_value {
    my ($self, $control, $value) = @_;
    return join ', ', @$value;
}

sub _split_value {
    my ($self, $control, $value) = @_;
    return [ split /\s*,\s*/, $value ];
}

sub run {
    my $self = shift;
    $self->result->content->{ran} = 1;
}

1;
