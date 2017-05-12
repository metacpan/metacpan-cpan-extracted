package Form::Factory::Test::Action::Controls;

use Test::Class::Moose;
use Test::More;
use Test::Moose;

with qw( Form::Factory::Test::Action );

has '+action' => (
    lazy       => 1,
    default    => sub { shift->interface->new_action('TestApp::Action::EveryControl') },
);

sub run_action : Tests(8) {
    my $self = shift;
    my $action = $self->action;

    $action->consume_and_clean_and_check_and_process(request => {
        button      => 'Bar',
        checkbox    => 'xyz',
        full_text   => "This is a test.\nTesting 1. 2. 3.",
        password    => 'secret',
        select_many => [ qw(
            one two three
        ) ],
        select_one  => 'see',
        text        => 'blanket',
        value       => 'universe',
    });

    is($action->content->{button}, undef, 'button is undef');
    is($action->content->{checkbox}, 'xyz', 'checkbox is xyz');
    is($action->content->{full_text}, "This is a test.\nTesting 1. 2. 3.", 
        'full_text is correct');
    is($action->content->{password}, 'secret', 'password is secret');
    is_deeply($action->content->{select_many}, [ qw( one two three ) ],
        'select_many is one, two, three');
    is($action->content->{select_one}, 'see', 'select_one is see');
    is($action->content->{text}, 'blanket', 'text is blanket');
    is($action->content->{value}, 'galaxy', 'value is galaxy');
};

1;
