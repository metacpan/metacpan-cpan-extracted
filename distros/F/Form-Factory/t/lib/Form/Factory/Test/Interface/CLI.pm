package Form::Factory::Test::Interface::CLI;

use Test::Class::Moose;
use Test::More;
use Test::Moose;

with qw( Form::Factory::Test::Interface );

has '+name' => (
    default => 'CLI',
);

has '+interface_options' => (
    default => sub {
        my $self = shift;
        {
            renderer => sub { shift; $self->output(join '', $self->output, @_) },
            get_args => sub { $self->argv },
            get_file => sub { 
                my ($interface, $name) = @_;
                $self->files->{$name};
            },
        } 
    },
);

has output => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => '',
);

has argv => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    default   => sub { [] },
);

has files => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    required  => 1,
    default   => sub { {} },
);

sub render_usage : Tests(7) {
    my $self = shift;
    my $action = $self->interface->new_action('TestApp::Action::EveryControl');

    $action->render;

    my $output = $self->output;
    like($output, qr{--button\s+a button}, 'usage includes button');
    like($output, qr{--checkbox\s+a checkbox}, 
        'usage includes checkbox');
    like($output, qr{--full_text FILE\s+some text},
        'usage includes full_text');
    like($output, qr{--password TEXT\s+a password},
        'usage includes password');
    like($output, qr{--select_many \[ one \| two \| three \| four \| five \]\s+select a few},
        'usage includes select_many');
    like($output, qr{--select_one \[ ay \| bee \| see \| dee \| ee \]\s+pick one},
        'usage include select_one');
    like($output, qr{--text TEXT\s+short text}, 'usage includes text');
};

sub consume_values : Tests(8) {
    my $self = shift;
    my $action = $self->interface->new_action('TestApp::Action::EveryControl');

    $self->argv([ qw(
        --button
        --checkbox
        --full_text   -
        --password    secret
        --select_many one
        --select_many two
        --select_many three
        --select_one  see
        --text        blanket
    ) ]);

    $self->files({
        '-' => "This is a test.\nTesting 1. 2. 3.",
    });

    $action->consume_and_clean_and_check_and_process;

    is($action->content->{button}, 'Foo', 'button is Foo');
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
