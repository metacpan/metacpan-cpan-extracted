package Form::Factory::Test::Feature::Control::Required;

use Test::Class::Moose;

use Test::More;

with qw( Form::Factory::Test::Feature );

has '+feature' => (
    lazy      => 1,
    default   => sub {
        my $self = shift;
        $self->action->controls;
        (grep { $_->isa('Form::Factory::Feature::Control::Required') }
            @{ $self->action->features })[0];
    },
);

sub scalar_required_ok : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    $action->consume(
        controls => [ 'required' ],
        request  => { required => 'foo' },
    );
    $action->clean( controls => [ 'required' ] );
    $action->check( controls => [ 'required' ] );

    ok($action->is_valid, qq{string "foo" is OK});
};

sub scalar_required_not_ok : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    $action->consume(
        controls => [ 'required' ],
        request  => { required => '' },
    );
    $action->clean( controls => [ 'required' ] );
    $action->check( controls => [ 'required' ] );

    ok(!$action->is_valid, qq{string "" is not OK});
};

1;
