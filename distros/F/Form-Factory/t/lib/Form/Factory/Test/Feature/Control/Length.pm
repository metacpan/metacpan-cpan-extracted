package Form::Factory::Test::Feature::Control::Length;

use Test::Class::Moose;

use Test::More;

with qw( Form::Factory::Test::Feature );

has '+feature' => (
    lazy      => 1,
    default   => sub {
        my $self = shift;
        $self->action->controls;
        (grep { $_->isa('Form::Factory::Feature::Control::Length') }
             @{ $self->action->features })[0];
    },
);

sub length_ok : Tests(5) {
    my $self = shift;
    my $action = $self->action;

    my $test_string = 'X' x 5;
    for my $i (1 .. 5) {
        $action->consume( 
            controls => [ 'length' ], 
            request  => { length => $test_string } 
        );
        $action->clean( controls => [ 'length' ] );
        $action->check( controls => [ 'length' ] );

        ok($action->is_valid, qq[string "$test_string" is OK]);
    }
    continue { $test_string .= $i }
};

sub length_too_short : Tests(6) {
    my $self = shift;
    my $action = $self->action;

    my $test_string = 'X';
    for my $i (1 .. 3) {
        $action->consume( 
            controls => [ 'length' ], 
            request  => { length => $test_string } 
        );
        $action->clean( controls => [ 'length' ] );
        $action->check( controls => [ 'length' ] );

        ok(!$action->is_valid, qq[string "$test_string" is not OK]);
        my @messages = $action->field_error_messages('length');
        is(scalar @messages, 1, qq[string "$test_string" caused one error]);
    }
    continue { 
        $action->results->clear_all;
        $test_string .= $i;
    }
};

sub length_too_long : Tests(8) {
    my $self = shift;
    my $action = $self->action;

    my $test_string = 'X' x 11;
    for my $i (1 .. 4) {
        $action->consume( 
            controls => [ 'length' ], 
            request  => { length => $test_string } 
        );
        $action->clean( controls => [ 'length' ] );
        $action->check( controls => [ 'length' ] );

        ok(!$action->is_valid, qq[string "$test_string" is not OK]);
        my @messages = $action->field_error_messages('length');
        is(scalar @messages, 1, qq[string "$test_string" caused one error]);
    }
    continue { 
        $action->results->clear_all;
        $test_string .= $i;
    }
};

1;
