package Form::Factory::Test::Action::Basic;

use Test::Class::Moose;
use Test::More;
use Test::Moose;

with qw( Form::Factory::Test::Action );

has '+action' => (
    lazy       => 1,
    default    => sub { shift->interface->new_action('TestApp::Action::Basic' => {
        value_to_defer => 'Superbark',
    }) },
);

sub run_action : Tests(5) {
    my $self = shift;
    my $action = $self->action;

    $action->consume_and_clean_and_check_and_process( request => {} );

    is($action->content->{one}, 1, 'clean is first');
    is($action->content->{two}, 2, 'check is second');
    is($action->content->{three}, 3, 'pre_process is third');
    is($action->content->{four}, 4, 'run is fourth');
    is($action->content->{five}, 5, 'post_process is fifth');
};

sub meta_class : Tests(1) {
    my $self = shift;
    my $meta = $self->action->meta;

    does_ok($meta, 'Form::Factory::Action::Meta::Class');
};

sub meta_class_controls : Tests(3) {
    my $self     = shift;
    my @controls = $self->action->meta->get_controls;

    is(scalar @controls, 1, 'we have one control');
    does_ok($controls[0], 'Form::Factory::Action::Meta::Attribute::Control');
    is($controls[0]->name, 'name', 'control is named name');
};

sub meta_class_features : Tests(3) {
    my $self     = shift;
    my $features = $self->action->meta->features;

    ok($features, 'has features');
    is_deeply([ sort keys %{ $features } ], [ qw( functional ) ], 
        'has one feature');
    is_deeply([ sort keys %{ $features->{functional} } ],
        [ qw( checker_code cleaner_code post_processor_code pre_processor_code ) ],
        'functional feature has expected code keys');
};

sub meta_class_all_features : Tests(3) {
    my $self = shift;
    my $features = $self->action->meta->get_all_features;

    ok($features, 'has features');
    is_deeply([ sort keys %{ $features } ], [ 'functional#TestApp::Action::Basic' ], 
        'has one feature');
    is_deeply([ sort keys %{ $features->{'functional#TestApp::Action::Basic'} } ],
        [ qw( checker_code cleaner_code post_processor_code pre_processor_code ) ],
        'functional feature has expected code keys');
};

sub meta_control_name : Tests(6) {
    my $self = shift;
    my @controls = $self->action->meta->get_controls;
    my $control  = $controls[0];

    ok($control, 'got control');
    is($control->name, 'name', 'control is named name');
    is($control->placement, 0, 'control placement is 0');
    is($control->control, 'text', 'control control is text');
    is_deeply([ keys %{ $control->options } ], ['default_value'], 
        'control options sets default_value');
    is_deeply($control->features, {}, 'control features are empty');
};

sub control_name : Tests(12) {
    my $self = shift;
    my $control = $self->action->controls->{name};

    ok($control, 'got control');
    does_ok($control, 'Form::Factory::Control');
    isa_ok($control, 'Form::Factory::Control::Text');
    does_ok($control, 'Form::Factory::Control::Role::Labeled');
    does_ok($control, 'Form::Factory::Control::Role::ScalarValue');
    is($control->name, 'name', 'control is named name');
    is_deeply($control->features, [], 'control features are empty');
    is($control->has_value, '', 'control has no value');
    is($control->value, undef, 'control value is undef');
    is($control->has_default_value, 1, 'control has a default value');
    is($control->default_value, 'Superbark', 'control default value is Superbark');
    is($control->current_value, 'Superbark', 'control current value is Superbark');
};

sub render_control : Tests(5) {
    my $self = shift;
    my $action = $self->action;

    my $control = $action->render_control(button => {
        name  => 'submit',
        label => 'Testing',
    });

    ok(length($self->output) > 0, 'got some output');
    ok($control, 'got a control back');
    isa_ok($control, 'Form::Factory::Control::Button');
    is($control->label, 'Testing', 'button label is Testing');
    is($control->current_value, undef, 'current_value is empty');
};

sub consume_control_empty : Tests(4) {
    my $self = shift;
    my $action = $self->action;

    my $control = $action->consume_control(button => {
        name  => 'submit',
        label => 'Testing',
    }, request => {});

    ok($control, 'got a control back');
    isa_ok($control, 'Form::Factory::Control::Button');
    is($control->label, 'Testing', 'button label is Testing');
    is($control->current_value, undef, 'current_value is empty');
};

sub consume_control_full : Tests(4) {
    my $self = shift;
    my $action = $self->action;

    my $control = $action->consume_control(button => {
        name  => 'submit',
        label => 'Testing',
    }, request => { submit => 'Testing' });

    ok($control, 'got a control back');
    isa_ok($control, 'Form::Factory::Control::Button');
    is($control->label, 'Testing', 'button label is Testing');
    is($control->current_value, 'Testing', 'current_value is Testing');
};

# TODO test stash_and_clear_and_unstash => sub { ... }
# TODO test render => sub { ... }

1;
