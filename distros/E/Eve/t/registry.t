# -*- mode: Perl; -*-
package RegistryTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use File::Basename ();
use File::Spec ();

use Test::More;

use Eve::RegistryStub;

use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'registry'} = Eve::Registry->new();
}

sub test_properties : Test(14) {
    my $self = shift;

    is($self->{'registry'}->base_uri_string, 'http://example.com');

    is_deeply($self->{'registry'}->alias_base_uri_string_list, []);

    is($self->{'registry'}->email_from_string, 'Someone <someone@example.com>');

    is($self->{'registry'}->pgsql_database, undef);
    is($self->{'registry'}->pgsql_host, undef);
    is($self->{'registry'}->pgsql_port, undef);
    is($self->{'registry'}->pgsql_user, undef);
    is($self->{'registry'}->pgsql_password, undef);

    is(
        $self->{'registry'}->session_storage_path,
        File::Spec->catdir(File::Spec->tmpdir(), 'test_session_storage'));
    is($self->{'registry'}->session_expiration_interval, 3600);
    is($self->{'registry'}->session_cookie_domain, undef);

    is($self->{'registry'}->template_path, File::Spec->catdir(
            File::Spec->curdir(), 'template'));
    is($self->{'registry'}->template_compile_path, File::Spec->catdir(
            File::Spec->curdir(), 'tmp', 'template'));
    is($self->{'registry'}->template_expiration_interval, 60);
}

sub test_lazy_load : Test(6) {
    my $registry = Eve::Registry->new();
    my $code = sub {
        return bless({}, 'Eve::Registry');
    };

    for my $name ('some_name', 'other_name') {
        isa_ok(
            $registry->lazy_load(name => $name, code => $code),
            'Eve::Registry');
        is(
            $registry->lazy_load(name => $name, code => $code),
            $registry->lazy_load(name => $name, code => $code));
        isnt(
            $registry->lazy_load(name => $name, code => $code),
            $registry->lazy_load(
                name => 'third_name', code => $code));
    }
}

sub test_get_uri : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_uri(
                string => 'http://www.domain.com/path');
        },
        class_name => 'Eve::Uri');
}

sub test_get_base_uri : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_base_uri();
        },
        class_name => 'Eve::Uri');
}

sub test_get_alias_base_uri_list : Test(3) {
    my $self = shift;

    $self->{'registry'}->set_always(
        'alias_base_uri_string_list',
        [
        'http://some.example.com/',
        'http://another.example.com/with/path']);

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_alias_base_uri_list();
        },
        class_name => 'ARRAY');

    is_deeply(
        $self->{'registry'}->get_alias_base_uri_list(),
        [map {
             Eve::Uri->new(string => $_);
         } @{$self->{'registry'}->alias_base_uri_string_list}]);
}

sub test_get_http_request : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_http_request(env_hash => {});
        },
        class_name => 'Eve::HttpRequest');
}

sub test_get_http_response : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_http_response();
        },
        class_name => 'Eve::HttpResponse::Psgi');
}

sub test_get_event_map : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_event_map();
        },
        class_name => 'Eve::EventMap');
}

sub test_get_email : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_email();
        },
        class_name => 'Eve::Email');
}

sub test_get_http_dispatcher : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_http_dispatcher();
        },
        class_name => 'Eve::HttpDispatcher');
}

sub test_get_http_output : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_http_output();
        },
        class_name => 'Eve::HttpOutput');
}

sub test_get_pgsql : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_pgsql();
        },
        class_name => 'Eve::PgSql');
}

sub test_get_template : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_template();
        },
        class_name => 'Eve::Template');
}

sub test_get_session : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_session(id => undef);
        },
        class_name => 'Eve::Session');
}

sub test_get_json : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'registry'}->get_json();
        },
        class_name => 'Eve::Json');
}

sub test_get_template_var_hash : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'registry'}->get_template_var_hash();
        },
        class_name => 'HASH');
}

1;
