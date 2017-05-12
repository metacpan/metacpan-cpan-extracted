# -*- mode: Perl; -*-
package HttpResourceTemplateTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::MockObject::Extends;

use File::Spec;
use Data::Dumper;

use Eve::PsgiStub;
use Eve::RegistryStub;
use Eve::TemplateStub;

use Eve::HttpResource::Template;
use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'registry'} = Eve::Registry->new();
    $self->{'response'} = $self->{'registry'}->get_http_response();
    $self->{'session'} = $self->{'registry'}->get_session(
        id => undef,
        storage_path => File::Spec->catdir(
            File::Spec->tmpdir(), 'test_session_storage'),
        expiration_interval => 3600);
    $self->{'request'} = Eve::PsgiStub->get_request(
        cookie => 'session_id=' . $self->{'session'}->get_id());
    $self->{'template'} = $self->{'registry'}->get_template(
            path => File::Spec->catdir(
                File::Spec->tmpdir(), 'test_template_dir'),
            compile_path => File::Spec->catdir(
                File::Spec->tmpdir(), 'test_compiled_storage'),
        expiration_interval => 60);
    $self->{'dispatcher'} = $self->{'registry'}->get_http_dispatcher();

    $self->{'json'} = Test::MockObject::Extends->new(
        $self->{'registry'}->get_json());

    $self->{'resource_parameter_hash'} = {
        'response' => $self->{'response'},
        'session_constructor' => sub { return $self->{'session'}; },
        'dispatcher' => $self->{'dispatcher'},
        'template' => $self->{'template'},
        'template_file' => 'empty.html'};
}

sub test_get : Test(2) {
    my $self = shift;

    $self->{'resource_parameter_hash'}->{'template_file'} = 'some.html';

    for my $var_hash ({'some' => 'var'}, {'another' => 'var'}) {
        my $resource = Eve::HttpResource::Template->new(
            %{$self->{'resource_parameter_hash'}},
            response => $self->{'registry'}->get_http_response(),
            template_var_hash => $var_hash,
            content_type => undef,
            charset => undef);

        my $response = $resource->process(
            matches_hash => {}, request => $self->{'request'});

        my $expected_response = $self->{'registry'}->get_http_response();
        $expected_response->set_status(code => 200);
        $expected_response->set_body(
            text => Digest::MD5::md5_hex(Dumper(
                $self->{'resource_parameter_hash'}->{'template_file'},
                {
                    %{$var_hash},
                    'session' => $self->{'session'},
                    'dispatcher' => $self->{'dispatcher'},
                    'request' => $self->{'request'}})));
        is(
            $response->get_text(),
            $expected_response->get_text());
    }
}

sub test_content_type : Test(3) {
    my $self = shift;

    for my $type ('text/html', 'text/plain', 'image/lolcat') {
        my $resource = Eve::HttpResource::Template->new(
            %{$self->{'resource_parameter_hash'}},
            template_var_hash => {},
            content_type => $type,
            charset => undef);

        my $response = $resource->process(
            matches_hash => {}, request => $self->{'request'});

        my $expected_response = $self->{'registry'}->get_http_response();
        $expected_response->set_header(name => 'Content-type', value => $type);
        $expected_response->set_header(name => 'Content-Length', value => 0);

        is($response->get_text(), $expected_response->get_text());
    }
}

sub test_charset : Test(2) {
    my $self = shift;

    for my $charset ('UTF-8', 'windows-1251') {
        my $resource = Eve::HttpResource::Template->new(
            %{$self->{'resource_parameter_hash'}},
            template_var_hash => {},
            content_type => undef,
            charset => $charset);

        my $response = $resource->process(
            matches_hash => {}, request => $self->{'request'});

        my $expected_response = $self->{'registry'}->get_http_response();
        $expected_response->set_header(name => 'charset', value => $charset);
        $expected_response->set_header(name => 'Content-Length', value => 0);

        is($response->get_text(), $expected_response->get_text());
    }
}

sub test_get_exception : Test(2) {
    my $self = shift;

    my $resource = Eve::HttpResource::Template->new(
        %{$self->{'resource_parameter_hash'}},
        template_var_hash => {},
        require_auth => 1);

    $self->{'session'}->clear_parameter(name => 'account_id');

    throws_ok(
        sub { $resource->process(
                  matches_hash => {}, request => $self->{'request'}) },
        'Eve::Exception::Http::401Unauthorized');

    $self->{'session'}->set_parameter(name => 'account_id', value => 1);

    lives_ok(
        sub {
            $resource->process(
                matches_hash => {}, request => $self->{'request'});
        });
}

1;
