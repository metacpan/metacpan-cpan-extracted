package TestApp::Controller::Foo;
use Moose;

use JSORB::Dispatcher::Catalyst::WithInvocant;

BEGIN { extends 'Catalyst::Controller' };

{
    package Test::App;
    use Moose;

    has 'greeting_prefix' => (
        is      => 'ro',
        isa     => 'Str',
        default => sub { 'Yo!' },
    );

    sub foo {
        my ($self, $who) = @_;
        return $self->greeting_prefix . " What's up $who";
    }

    package Test::App::Foo;
    use Moose;

    has 'counter' => (
        is      => 'ro',
        isa     => 'Int',
    );

    sub bar { 'FOO::BAR(' . (shift)->counter . ')' }
}

my $COUNTER = 1;

__PACKAGE__->config(
    'Action::JSORB' => JSORB::Dispatcher::Catalyst::WithInvocant->new(
        constructor_arg_generators => {
            'Test::App' => sub {
                my ($c) = @_;
                return (
                    $c->req->param('greeting_prefix')
                        ? (greeting_prefix => $c->req->param('greeting_prefix'))
                        : ()
                );
            },
            'Test::App::Foo' => sub {
                my ($c) = @_;
                return (
                    counter => $COUNTER++
                );
            }
        },
        namespace     => JSORB::Namespace->new(
            name     => 'Test',
            elements => [
                JSORB::Interface->new(
                    name       => 'App',
                    procedures => [
                        JSORB::Method->new(
                            name        => 'greeting',
                            method_name => 'foo',
                            spec        => [ 'Str' => 'Str' ],
                        ),
                    ],
                    elements => [
                        JSORB::Interface->new(
                            name       => 'Foo',
                            procedures => [
                                JSORB::Method->new(
                                    name => 'bar',
                                    spec => [ 'Unit' => 'Str' ],
                                ),
                            ]
                        )
                    ]
                )
            ]
        )
    )
);

sub rpc : Local : ActionClass(JSORB::WithInvocant) {}


1;