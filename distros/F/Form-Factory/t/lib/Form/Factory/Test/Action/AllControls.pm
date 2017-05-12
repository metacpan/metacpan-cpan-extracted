package Form::Factory::Test::Action::AllControls;

use Test::Class::Moose;

use Test::More;

with qw( Form::Factory::Test::Action );

has '+action' => (
    lazy       => 1,
    default    => sub { shift->interface->new_action('TestApp::Action::Featureful') },
);

# There's a bug in Form-Feature-0.006 that causes an action to die when clean or
# check is run without the controls option being sent. This tests for that bug.
sub run_checks_on_all : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    $action->consume(
        request  => { 
            match_code              => '0',
            required                => 'foo',
            match_regex             => 'abccba',
            match_available_choices => 'one',
        },
    );
    $action->clean;
    $action->check;

    #diag(scalar $action->all_messages);
    ok($action->is_valid, qq{action with just the required input is OK});
};

1;
