package TestApp::Controller::Root;
use Moose;

use JSORB::Dispatcher::Catalyst::WithInvocant;

BEGIN { extends 'Catalyst::Controller' };


__PACKAGE__->config(
    'Action::JSORB' => JSORB::Dispatcher::Catalyst->new(
        namespace     => JSORB::Namespace->new(
            name     => 'Test',
            elements => [
                JSORB::Interface->new(
                    name       => 'App',
                    procedures => [
                        JSORB::Procedure->new(
                            name  => 'greeting',
                            body  => sub {
                                my ($c) = @_;
                                return 'Hello ' . $c->config->{'who'};
                            },
                            spec  => [ 'Catalyst' => 'Str' ],
                        ),
                    ]
                )
            ]
        )
    )
);

sub rpc : Global : ActionClass(JSORB) {}