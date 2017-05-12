package TestApp::Feature::Control::SplitValue;

use Moose;

with qw( 
    Form::Factory::Feature
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::ControlValueConverter
);

has join_by => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => ', ',
);

has split_by => (
    is        => 'ro',
    isa       => 'RegexpRef',
    required  => 1,
    default   => sub { qr{\s*,\s*} },
);

sub check_control { 
    my ($self, $control) = @_;
    die "not a scalar valued control"
        unless $control->does('Form::Factory::Control::Role::ScalarValue');
}

sub value_to_control {
    my ($self, $value) = @_;
    return join $self->join_by, @$value;
}

sub control_to_value {
    my ($self, $value) = @_;
    return [ split $self->split_by, $value ];
}

package Form::Factory::Feature::Control::Custom::SplitValue;
sub register_implementation { 'TestApp::Feature::Control::SplitValue' }

1;
