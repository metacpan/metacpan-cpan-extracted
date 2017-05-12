package Form::Factory::Test::Action::Inheritance;

use Test::Class::Moose;
use Test::More;
use Test::Moose;

with qw( Form::Factory::Test::Action );

use TestApp::Action::Bottom;

has '+action' => (
    lazy      => 1,
    default   => sub {
        shift->interface->new_action('TestApp::Action::Bottom');
    },
);

sub run_action : Tests(1) {
    my $self = shift;
    my $action = $self->action;

    $action->consume_and_clean_and_check_and_process( request => {} );

    ok($action->is_success, 'action runs');
};

sub inherited_checks : Tests(5) {
    my $self = shift;
    my $action = $self->action;

    $action->consume_and_clean_and_check_and_process( request => {
        foo => 'Aa1',
    });

    ok(!$action->is_valid, 'action does not validate');
    
    my @errors = sort { $a->message cmp $b->message } $action->results->regular_error_messages;
    is(scalar @errors, 3, 'got three errors');

    like($errors[0]->message, qr/lowercase letters/, 'got lowercase letters error');
    like($errors[1]->message, qr/numbers/, 'got numbers error');
    like($errors[2]->message, qr/uppercase letters/, 'got uppsercase letters error');
};

sub top_foo_has_features_trim : Tests(3) {
    my $self = shift;

    my $meta = Class::MOP::class_of('TestApp::Action::Top');
    ok($meta, 'found TestApp::Action::Top');
    my $foo  = $meta->get_attribute('foo');
    ok($foo, 'found foo');

    is_deeply($foo->features, {
        trim     => {},
        required => {},
        length   => { minimum => 10 },
    }, 'top foo has just trim in the features');
};

sub bottom_foo_has_features_trim_and_length : Tests(3) {
    my $self = shift;

    my $meta = Class::MOP::class_of('TestApp::Action::Bottom');
    ok($meta, 'found TestApp::Action::Bottom');
    my $foo  = $meta->get_attribute('foo');
    ok($foo, 'found foo');

    is_deeply($foo->features, {
        fill_on_assignment => { no_warning => 1 },
        trim     => {},
        length   => { maximum => 20 },
    }, 'bottom foo has trim and length in the features');
};

1;
