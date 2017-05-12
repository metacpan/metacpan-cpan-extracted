package Form::Factory::Test::Action::ValueConversion;

use Test::Class::Moose;
use Test::More;

with qw( Form::Factory::Test::Action );

has '+action' => (
    lazy      => 1,
    default   => sub { shift->interface->new_action('TestApp::Action::SplitValue') },
);

sub conversion_ok : Tests(11) {
    my $self   = shift;
    my $action = $self->action;

    is_deeply($action->manual_splitter, [], 
        'manual_splitter starts with empty array');
    is_deeply($action->feature_splitter, [],
        'feature_splitter starts with empty array');

    $action->manual_splitter([qw( foo bar baz )]);
    $action->feature_splitter([qw( one two three )]);

    is_deeply($action->manual_splitter, [qw( foo bar baz )],
        'manual_splitter is now foo, bar, baz');
    is_deeply($action->feature_splitter, [qw( one two three )],
        'feature_splitter is now one, two, three');

    is($action->controls->{manual_splitter}->current_value, 'foo, bar, baz',
        'manual_splitter control is foo, bar, baz');
    is($action->controls->{feature_splitter}->current_value, 'one, two, three',
        'feature_splitter control is one, two, three');

    $action->consume_and_clean_and_check_and_process( request => {
        manual_splitter  => 'one, two, three',
        feature_splitter => 'foo, bar, baz',
    });

    ok($action->result->content->{ran}, 'action ran');

    is_deeply($action->manual_splitter, [qw( one two three )],
        'manual_splitter is now one, two, three');
    is_deeply($action->feature_splitter, [qw( foo bar baz )],
        'feature_splitter is now foo, bar, baz');

    is($action->controls->{manual_splitter}->current_value, 'one, two, three',
        'manual_splitter control is one, two, three');
    is($action->controls->{feature_splitter}->current_value, 'foo, bar, baz',
        'feature_splitter control is foo, bar, baz');

};

1;
