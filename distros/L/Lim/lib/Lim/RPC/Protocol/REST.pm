package Lim::RPC::Protocol::REST;

use common::sense;

use Carp;
use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use JSON::XS ();

use Lim ();
use Lim::Util ();
use Lim::RPC::Callback ();

use base qw(Lim::RPC::Protocol);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $JSON = JSON::XS->new->utf8->convert_blessed;
our %REST_CRUD = (
    GET => 'READ',
    PUT => 'UPDATE',
    POST => 'CREATE',
    DELETE => 'DELETE'
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
    if (Lim::Config->{rpc}->{json}->{pretty}) {
        $JSON->pretty(1);
    }
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 name

=cut

sub name {
    'rest';
}

=head2 serve

=cut

sub serve {
}

=head2 handle

=cut

sub handle {
    my ($self, $cb, $request) = @_;

    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }

    if ($request->uri =~ /^\/([a-zA-Z]+)\/(\w+)(?:\/([^\?]*)){0,1}/o) {
        my ($module, $function, $parameters) = ($1, $2, $3);
        my $response = HTTP::Response->new;
        $response->request($request);
        $response->protocol($request->protocol);

        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module)) {
            my ($method, $call);

            if (exists $REST_CRUD{$request->method}) {
                $method = lc($REST_CRUD{$request->method});
            }
            else {
                $method = lc($request->method);
            }
            $function = lc($function);
            $call = ucfirst($method).Lim::Util::Camelize($function);

            my $obj;
            if ($server->have_module_call($module, $call)) {
                $obj = $server->module_obj_by_protocol($module, $self->name);
            }

            my ($query, $jsonp);
            if (defined $obj) {
                Lim::DEBUG and $self->{logger}->debug('API call ', $module, '->', $call, '()');

                if ($request->header('Content-Type') =~ /(?:^|\s)application\/x-www-form-urlencoded(?:$|\s|;)/o) {
                    my $query_str = $request->content;
                    $query_str =~ s/[\015\012]+$//o;

                    $query = Lim::Util::QueryDecode($query_str);
                }
                elsif ($request->header('Content-Type') =~ /(?:^|\s)application\/json(?:$|\s|;)/o) {
                    eval {
                        $query = $JSON->decode($request->content);
                    };
                    if ($@) {
                        $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        undef($query);
                        undef($obj);
                    }
                }
                else {
                    $query = Lim::Util::QueryDecode($request->uri->query);
                }

                $jsonp = delete $query->{jsonpCallback};

                if (defined $parameters) {
                    my $redirect_call = $server->process_module_call_uri_map($module, $call, $parameters, $query);

                    if (defined $redirect_call and $redirect_call) {
                        Lim::DEBUG and $self->{logger}->debug('API call redirected ', $call, ' => ', $redirect_call);
                        $call = $redirect_call;
                    }
                }
            }

            if (defined $obj) {
                my $real_self = $self;
                weaken($self);
                $obj->$call(Lim::RPC::Callback->new(
                    request => $request,
                    cb => sub {
                        my ($result) = @_;

                        unless (defined $self) {
                            return;
                        }

                        if (blessed $result and $result->isa('Lim::Error')) {
                            $response->code($result->code);
                            eval {
                                $response->content($JSON->encode($result));
                            };
                            if ($@) {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                                Lim::WARN and $self->{logger}->warn('JSON encode error: ', $@);
                            }
                            else {
                                $response->header(
                                    'Content-Type' => 'application/json; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );

                                if (defined $jsonp) {
                                    $response->content($jsonp.'('.$response->content().');');
                                    $response->header('Content-Type' => 'application/javascript; charset=utf-8');
                                }
                            }
                        }
                        elsif (ref($result) eq 'HASH') {
                            eval {
                                $response->content($JSON->encode($result));
                            };
                            if ($@) {
                                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                                Lim::WARN and $self->{logger}->warn('JSON encode error: ', $@);
                            }
                            else {
                                $response->header(
                                    'Content-Type' => 'application/json; charset=utf-8',
                                    'Cache-Control' => 'no-cache',
                                    'Pragma' => 'no-cache'
                                    );
                                $response->code(HTTP_OK);

                                if (defined $jsonp) {
                                    $response->content($jsonp.'('.$response->content().');');
                                    $response->header('Content-Type' => 'application/javascript; charset=utf-8');
                                }
                            }
                        }
                        else {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }

                        $cb->cb->($response);
                        return;
                    },
                    reset_timeout => sub {
                        $cb->reset_timeout;
                    }), $query);
                return 1;
            }
        }
        else {
            return;
        }

        $cb->cb->($response);
        return 1;
    }
    return;
}

=head2 request

=cut

sub request {
    my $self = shift;
    my %args = ( @_ );

    my ($method, $uri) = Lim::Util::URIize($args{call});
    $uri = (defined $args{path} ? $args{path} : '' ).'/'.lc($args{plugin}).$uri;
    my $request = HTTP::Request->new($method, $uri);

    if (defined $args{data}) {
        eval {
            $request->content($JSON->encode($args{data}));
        };
        if ($@) {
            confess 'JSON encoding of data failed: '.$@;
        }
        $request->header('Content-Type' => 'application/json; charset=utf-8');
        $request->header('Content-Length' => length($request->content));
    }
    else {
        $request->header('Content-Length' => 0);
    }

    return $request;
}

=head2 response

=cut

sub response {
    my ($self, $response) = @_;
    my $data = {};

    unless (blessed $response and $response->isa('HTTP::Response')) {
        return;
    }

    if ($response->header('Content-Length')) {
        if ($response->header('Content-Type') =~ /application\/json/io) {
            eval {
                $data = $JSON->decode($response->decoded_content);
            };
            if ($@) {
                return Lim::Error->new(
                    message => 'JSON decode error: '.$@,
                    module => $self
                );
            }

            if (ref($data) ne 'HASH') {
                return Lim::Error->new(
                    message => 'Invalid data returned, not a hash',
                    module => $self
                );
            }

            unless ($response->code == 200) {
                return Lim::Error->new->set($data);
            }
        }
        else {
            return Lim::Error->new(
                message => 'Unknown content type ['.$response->header('Content-Type').'] returned',
                module => $self
            );
        }
    }
    else {
        unless ($response->code == 200) {
            return Lim::Error->new(
                code => $response->code,
                module => $self
            );
        }
    }

    return $data;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Protocol::REST
