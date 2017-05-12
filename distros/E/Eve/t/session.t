# -*- mode: Perl; -*-
package SessionTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use File::Spec;
use Time::HiRes ();

use Eve::Session;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'session'} = Eve::Session->new(
        id => undef,
        storage_path => File::Spec->catdir(
            File::Spec->tmpdir(), 'test_session_storage'),
        expiration_interval => 3600);
    $self->{'session'}->session->flush();
}

sub test_init : Test(5) {
    my $self = shift;

    isa_ok($self->{'session'}->session, 'CGI::Session');

    is($self->{'session'}->session->expire(), 3600);
    is(
        Eve::Session->new(
            id => undef,
            storage_path => File::Spec->catdir(
                File::Spec->tmpdir(), 'test_session_storage'),
            expiration_interval => 600)->session->expire(),
        600);

    is(
        $self->{'session'}->session->id(),
        Eve::Session->new(
            id => $self->{'session'}->session->id(),
            storage_path => File::Spec->catfile(
                File::Spec->tmpdir(), 'test_session_storage'),
            expiration_interval => 3600)->session->id());

    ok(
        -f File::Spec->catfile(
             File::Spec->tmpdir(), 'test_session_storage',
             'cgisess_'.$self->{'session'}->session->id()));
}

sub test_init_error : Test {
    throws_ok(
        sub {
            Eve::Session->new(
                id => {},
                storage_path => File::Spec->catfile(
                    File::Spec->tmpdir(), 'test_session_storage'),
                expiration_interval => 3600);
        },
        'Eve::Error::Session');
}

sub test_get_id : Test {
    my $self = shift;

    is(
        $self->{'session'}->get_id(),
        Eve::Session->new(
            id => $self->{'session'}->session->id(),
            storage_path => File::Spec->catfile(
                File::Spec->tmpdir(), 'test_session_storage'),
            expiration_interval => 3600)->get_id());
}

sub test_parameter_set_get : Test(7) {
    my $self = shift;

    is(
        $self->{'session'}->set_parameter(name => 'some', value => 'thing'),
        'thing');
    is($self->{'session'}->get_parameter(name => 'some'), 'thing');

    is(
        $self->{'session'}->set_parameter(name => 'another', value => 'one'),
       'one');
    is($self->{'session'}->get_parameter(name => 'another'), 'one');

    $self->{'session'}->set_parameter(
        name => 'live', value => 'hello dude', expiration_interval => 600);
    $self->{'session'}->set_parameter(
        name => 'dead', value => 'RIP', expiration_interval => 1);
    $self->{'session'}->set_parameter(
        name => 'cat', value => 'meow', expiration_interval => 0);

    $self->{'session'}->session->flush();
    sleep(1);

    is($self->{'session'}->get_parameter(name => 'live'), 'hello dude');
    is(
        Eve::Session->new(
            id => $self->{'session'}->session->id(),
            storage_path => File::Spec->catfile(
                File::Spec->tmpdir(),
                'test_session_storage'),
            expiration_interval => 600)->get_parameter(name => 'dead'),
            undef);
    is($self->{'session'}->get_parameter(name => 'cat'), 'meow');
}

sub test_parameter_clear : Test(2) {
    my $self = shift;

    $self->{'session'}->set_parameter(name => 'clear me', value => 'please');
    is($self->{'session'}->clear_parameter(name => 'clear me'), 'please');
    is($self->{'session'}->get_parameter(name => 'clear me'), undef);
};

sub test_expiration_interval : Test(2) {
    my $session;

    for my $interval (3600, 1800) {
        $session = Eve::Session->new(
            id => undef,
            storage_path => File::Spec->catdir(
                File::Spec->tmpdir(), 'test_session_storage'),
            expiration_interval => $interval);

        is($session->expiration_interval, $interval);
    }
}

sub test_init_flush_error : Test {
    throws_ok(
        sub {
            Eve::Session->new(
                id => undef,
                storage_path => '/',
                expiration_interval => 3600);
        },
        'Eve::Error::Session');
}

sub test_flush : Test(2) {
    my $self = shift;

    my $session_file_name = File::Spec->catfile(
        File::Spec->tmpdir(), 'test_session_storage',
        'cgisess_'.$self->{'session'}->get_id());

    my $old_mtime = (stat($session_file_name))[9];

    sleep(1);
    $self->{'session'}->set_parameter(name => 'some', value => 'thing');

    isnt((stat($session_file_name))[9], $old_mtime);

    $old_mtime = (stat($session_file_name))[9];

    sleep(1);
    $self->{'session'}->clear_parameter(name => 'some');

    isnt((stat($session_file_name))[9], $old_mtime);
}

1;
