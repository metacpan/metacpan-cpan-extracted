package Lim::RPC::Protocol::JSONRPC1;

use common::sense;

use Carp;
use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use JSON::XS ();

use Lim ();
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
our $ID = 1;
our $ID_OVERFLOW = 2^32;

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
    'jsonrpc1';
}

=head2 serve

=cut

sub serve {
}

=head2 handle

=cut

sub handle {
    my ($self, $cb, $request, $transport) = @_;
    
    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }

    if ($request->header('Content-Type') =~ /(?:^|\s)application\/json(?:$|\s|;)/o and $request->uri =~ /^\/([a-zA-Z]+)\s*$/o) {
        my ($module) = ($1);
        my $response = HTTP::Response->new;
        $response->request($request);
        $response->protocol($request->protocol);
        
        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module)) {
            my ($jsonreq, $jsonresp);
            
            eval {
                $jsonreq = $JSON->decode($request->content);
            };
            unless ($@) {
                if (ref($jsonreq) eq 'HASH' and exists $jsonreq->{id} and exists $jsonreq->{method}) {
                    my $id = $jsonreq->{id};
                    my $call = $jsonreq->{method};
                    
                    if ($server->have_module_call($module, $call)) {
                        my $obj = $server->module_obj_by_protocol($module, $self->name);
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
                                        $response->content($JSON->encode({
                                            result => undef,
                                            error => {
                                                code => $result->code,
                                                message => $result->message
                                            },
                                            id => $id
                                        }));
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
                                    }
                                }
                                elsif (ref($result) eq 'HASH') {
                                    eval {
                                        $response->content($JSON->encode({
                                            result => $result,
                                            error => undef,
                                            id => $id
                                        }));
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
                                    }
                                }
                                else {
                                    $response->code(HTTP_INTERNAL_SERVER_ERROR);
                                    $self->{logger}->debug('Invalid result from JSONRPC call ', $call);
                                }
                                
                                $cb->cb->($response);
                                return;
                            },
                            reset_timeout => sub {
                                $cb->reset_timeout;
                            }), $jsonreq->{params});
                        return 1;
                    }
                    else {
                        $response->code(HTTP_NOT_FOUND);
                        $jsonresp = {
                            result => undef,
                            error => {
                                code => -32601,
                                message => 'Method not found'
                            },
                            id => $id
                        };
                    }
                }
                else {
                    $response->code(HTTP_BAD_REQUEST);
                    $jsonresp = {
                        result => undef,
                        error => {
                            code => -32600,
                            message => 'Invalid Request'
                        },
                        id => undef
                    };
                }
            }
            if ($@ and !defined $jsonresp) {
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                $jsonresp = {
                    result => undef,
                    error => {
                        code => -32700,
                        message => 'Parse error'
                    },
                    id => undef
                };
            }
            if (defined $jsonresp) {
                eval {
                    $response->content($JSON->encode($jsonresp));
                };
                if ($@) {
                    $response->code(HTTP_INTERNAL_SERVER_ERROR);
                    Lim::WARN and $self->{logger}->warn('JSON encode error: ', $@);
                }
            }
            elsif (!$response->code) {
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                $self->{logger}->debug('Unknown response, setting HTTP_INTERNAL_SERVER_ERROR');
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
    $uri = (defined $args{path} ? $args{path} : '' ).'/'.lc($args{plugin});
    my $request = HTTP::Request->new($method, $uri);

    if (defined $args{data}) {
        eval {
            $request->content($JSON->encode({
                id => $ID++,
                method => $args{call},
                params => $args{data}
            }));
        };
        if ($@) {
            confess 'JSON encoding of data failed: '.$@;
        }
    }
    else {
        $request->content($JSON->encode({
            id => $ID++,
            method => $args{call}
        }));
    }
    $request->header('Content-Type' => 'application/json; charset=utf-8');
    $request->header('Content-Length' => length($request->content));

    if ($ID == $ID_OVERFLOW) {
        $ID = 1;
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
            if (ref($data->{error}) eq 'HASH') {
                return Lim::Error->new->set({ 'Lim::Error' => $data->{error} });
            }
            return Lim::Error->new(
                code => $response->code,
                module => $self
            );
        }
    }
    else {
        return Lim::Error->new(
            message => 'Unknown content type ['.$response->header('Content-Type').'] returned',
            module => $self
        );
    }

    # TODO: How can we check id?

    return defined $data->{result} ? $data->{result} : {};
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

1; # End of Lim::RPC::Protocol::JSONRPC1
