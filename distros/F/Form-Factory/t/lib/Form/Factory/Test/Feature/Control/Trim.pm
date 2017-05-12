package Form::Factory::Test::Feature::Control::Trim;

use Test::Class::Moose;

use Test::More;

with qw( Form::Factory::Test::Feature );

has '+feature' => (
    lazy      => 1,
    default   => sub {
        my $self = shift;
        $self->action->controls;
        (grep { $_->isa('Form::Factory::Feature::Control::Trim') }
             @{ $self->action->features })[0];
    },
);

sub trim_ok : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    $action->consume(
        controls => [ 'trim' ],
        request  => { trim => '   trim this  ' },
    );
    $action->clean( controls => [ 'trim' ] );
    $action->check( controls => [ 'trim' ] );

    is($action->controls->{trim}->current_value, 'trim this', 
        'trimmed down to "trim this"');
};

1;

