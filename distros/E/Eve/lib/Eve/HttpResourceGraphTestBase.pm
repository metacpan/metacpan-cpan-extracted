# -*- mode: Perl; -*-
package Eve::HttpResourceGraphTestBase;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use Eve::RegistryStub;

use Eve::Registry;

Eve::HttpResourceGraphTestBase->SKIP_CLASS(1);

=head1 NAME

B<Eve::HttpResourceGraphTestBase> - a base class for all Graph API
HTTP resource classes.

=head1 SYNOPSIS

    package BogusHttpResourceTest;

    use parent qw(Eve::HttpResourceGraphTestBase);

    # put your HTTP resource tests here

Get a ready HTTP dispatcher object for your test case:

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            'method' => $method_string,
            'uri' => $uri_string,
            'host' => $domain_strin,
            'query' => $query_string,
            'cookie' => $cookie_string));

=head1 DESCRIPTION

B<Eve::HttpResourceGraphTestBase> is the class that provides all
required test cases for every Graph API HTTP resource class.

=head1 METHODS

=head2 B<setup()>

=cut

sub setup {
    my $self = shift;

    $self->{'registry'} = Eve::Registry->new();
    $self->{'session'} = $self->{'registry'}->get_session(id => undef);
}

=head2 B<set_dispatcher()>

Returns an C<Eve::HttpDispatcher> object ready for HTTP resource
testing. To get a ready request object to be used as an argument a
L<Eve::PsgiStub> stub class can be used.

=head3 Arguments

=over 4

=item

Any C<Eve::HttpRequest> object.

=back

=cut

sub set_dispatcher {
    my ($self, $request) = @_;

    $self->{'dispatcher'} = Eve::HttpDispatcher->new(
        request_constructor => sub {
            return $request;
        },
        response => $self->{'registry'}->get_http_response(),
        event_map => $self->{'registry'}->get_event_map(),
        base_uri => $self->{'registry'}->get_base_uri());

    $self->{'resource'} = $self->{'resource_constructor'}->(
        dispatcher => $self->{'dispatcher'});

    for my $binding_hash (@{$self->{'dispatcher_binding_list'}}) {
        $self->{'dispatcher'}->bind(%{$binding_hash});
    }

    return;
}

=head2 B<do_test_read()>

Performs all tests for the GET functionality of a Graph API resource.

=cut

sub do_test_read {
    my ($self, $data_hash_list) = @_;

    $self->do_test($data_hash_list, 'GET');
}

=head2 B<do_test_publish()>

Performs all tests for the POST functionality of a Graph API resource.

=cut

sub do_test_publish {
    my ($self, $data_hash_list) = @_;

    $self->do_test($data_hash_list, 'POST');
}

=head2 B<do_test_remove()>

Performs all tests for the DELETE functionality of a Graph API resource.

=cut

sub do_test_remove {
    my ($self, $data_hash_list) = @_;

    $self->do_test($data_hash_list, 'DELETE');
}

=head2 B<do_test()>

Performs all tests for specified data and request method.

=cut

sub do_test {
    my ($self, $data_hash_list, $method) = @_;

    for my $data_hash (@{$data_hash_list}) {

        my $request = Eve::PsgiStub->get_request(
            method => $method,
            uri => $data_hash->{'uri_hash'}->{'uri_string'},
            query => $data_hash->{'uri_hash'}->{'query_string'},
            host => 'example.com',
            body => $data_hash->{'request_body'},
            cookie => 'session_id=' . $self->{'session'}->get_id());

        if (defined $data_hash->{'upload_hash'}) {
            $request->cgi->{'env'}->{'plack.request.upload'} =
                $data_hash->{'upload_hash'};
        }

        $self->set_dispatcher($request);

        $self->set_session_parameters($data_hash->{'session_hash'});
        $self->mock_gateway_methods($data_hash->{'gateway_list'});

        my $event = Eve::Event::PsgiRequestReceived->new(
            event_map => $self->{'registry'}->get_event_map(),
            env_hash => {});

        $self->{'dispatcher'}->handle(event => $event);

        $self->assert_response(
            $event->response, 200, $data_hash->{'resource_result'});
    }
}

=head2 B<set_session_parameters()>

Sets session parameters for the current test.

=cut

sub set_session_parameters {
    my ($self, $session_hash) = @_;

    for my $parameter_name (keys %{$session_hash}) {
        $self->{'session'}->set_parameter(
            name => $parameter_name,
            value => $session_hash->{$parameter_name});
    }
}

=head2 B<mock_gateway_methods()>

Adds gateway method mocking with provided data.

=cut

sub mock_gateway_methods {
    my ($self, $gateway_list) = @_;

    for my $gateway_data_hash (@{$gateway_list}) {
        $gateway_data_hash->{'object'}->mock(
            $gateway_data_hash->{'method'},
            sub {
                shift;
                if (not defined $gateway_data_hash->{'no_argument_check'}) {
                    is_deeply(
                        {@_},
                        $gateway_data_hash->{'arguments'},
                        'Gateway method arguments for '
                        . $gateway_data_hash->{'method'}
                        . ' method.');
                }

                return $gateway_data_hash->{'result'};
            });
    }
}

=head2 B<assert_response()>

Checks the response of a resource and compares it to the one specified
in the arguments.

=cut

sub assert_response {
    my ($self, $response, $code, $body) = @_;

    if (ref $body eq 'Regexp') {
        like($response->get_text, $body);

    } else {

        my $expected_response = $self->{'registry'}->get_http_response()->new();
        $expected_response->set_header(
            name => 'Content-Type', value => 'text/javascript');
        $expected_response->set_status(code => $code);
        $expected_response->set_body(
            text => $self->{'registry'}->get_json()->encode(
                reference => $body));

        is(
            $response->get_text(),
            $expected_response->get_text(),
            'Response text');
    }
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
