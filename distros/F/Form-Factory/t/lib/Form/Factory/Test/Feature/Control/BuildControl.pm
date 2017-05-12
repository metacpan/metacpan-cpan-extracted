package Form::Factory::Test::Feature::Control::BuildControl;

use Test::Class::Moose;

use Test::More;

with qw( Form::Factory::Test::Feature );

has '+action' => (
    default   => sub {
        shift->interface->new_action('TestApp::Action::CapitalizeLabel')
    },
);

has '+feature' => (
    lazy      => 1,
    default   => sub {
        my $self = shift;
        $self->action->controls;
        (grep { $_->isa('TestApp::Feature::Control::CapitalizeLabel') }
            @{ $self->action->features })[0];
    },
);

sub modify_control_ok : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    my $control = $action->controls->{capitalize_label};
    is($control->label, 'CAPITALIZE LABEL', 'label is capitalized');
};

1;
