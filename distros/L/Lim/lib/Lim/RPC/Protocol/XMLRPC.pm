package Lim::RPC::Protocol::XMLRPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();

use XMLRPC::Lite ();
use XMLRPC::Transport::HTTP::Server ();

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

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
}

=head2 Destroy

=cut

sub Destroy {
    my ($self) = @_;
    
    delete $self->{xmlrpc};
}

=head2 name

=cut

sub name {
    'xmlrpc';
}

=head2 serve

=cut

sub serve {
    my ($self, $module, $module_shortname) = @_;
    my ($calls, $tns, $xmlrpc, $obj, $obj_class);
    
    $calls = $module->Calls;
    $tns = $module.'::Server';

    $xmlrpc = XMLRPC::Transport::HTTP::Server->new;
    $obj = $self->server->module_obj_by_protocol($module_shortname, $self->name);
    $obj_class = ref($obj);
    # TODO: check if $obj_class alread is a XMLRPC::Server::Parameters
    eval "push(\@${obj_class}::ISA, 'XMLRPC::Server::Parameters');";
    if ($@) {
        die $@;
    }
    $self->{xmlrpc}->{$module} = $xmlrpc;
}

=head2 handle

=cut

sub handle {
    my ($self, $cb, $request, $transport) = @_;
    
    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }

    if ($request->header('Content-Type') =~ /(?:^|\s)text\/xml(?:$|\s|;)/o and $request->uri =~ /^\/([a-zA-Z]+)\s*$/o) {
        my ($module) = ($1);
        my $response = HTTP::Response->new;
        my $http_request = $request;
        $response->request($request);
        $response->protocol($request->protocol);
        
        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module) and exists $self->{xmlrpc}->{$server->module_class($module)}) {
            my ($action, $method_uri, $method_name);
            my $real_self = $self;
            my $xmlrpc = $self->{xmlrpc}->{$server->module_class($module)};
            my $protocol_obj = $server->module_obj_by_protocol($module, $self->name);
            weaken($self);
            weaken($xmlrpc);

            $method_uri = 'urn:'.ref($protocol_obj);

            Lim::RPC_DEBUG and $self->{logger}->debug('XMLRPC dispatch to module ', $server->module_class($module), ' obj ', $server->module_obj($module), ' proto obj ', $protocol_obj);

            $xmlrpc->on_dispatch(sub {
                my ($request) = @_;
                
                unless (defined $self and defined $xmlrpc) {
                    return;
                }
                
                $request->{__lim_rpc_protocol_xmlrpc_cb} = Lim::RPC::Callback->new(
                    request => $http_request,
                    cb => sub {
                        my ($data) = @_;
                        
                        unless (defined $self and defined $xmlrpc) {
                            return;
                        }
                        
                        if (blessed $data and $data->isa('Lim::Error')) {
                            $xmlrpc->make_fault($data->code, $data->message);
                        }
                        else {
                            my $result;
                            
                            if (defined $data) {
                                $result = $xmlrpc->serializer
                                    ->prefix('s')
                                    ->uri($method_uri)
                                    ->envelope(response => $method_name . 'Response', __xmlrpc_result('base', $data));
                            }
                            else {
                                $result = $xmlrpc->serializer
                                    ->prefix('s')
                                    ->uri($method_uri)
                                    ->envelope(response => $method_name . 'Response');
                            }
                            
                            $xmlrpc->make_response($XMLRPC::Constants::HTTP_ON_SUCCESS_CODE, $result);
                        }
                        
                        $response = $xmlrpc->response;
                        $response->header(
                            'Cache-Control' => 'no-cache',
                            'Pragma' => 'no-cache'
                            );
    
                        $cb->cb->($response);
                        return;
                    },
                    reset_timeout => sub {
                        $cb->reset_timeout;
                    });

                unless ($request->method =~ /^\w+$/o) {
                    $request->{__lim_rpc_protocol_xmlrpc_cb}->(Lim::Error->new(500, 'Invalid characters in method name'));
                    return;
                }

                return ($method_uri, ($method_name = $request->method));
            });

            $xmlrpc->dispatch_to($protocol_obj);

            eval {
                $xmlrpc->request($request);
                $xmlrpc->handle;
            };
            if ($@) {
                Lim::WARN and $self->{logger}->warn('XMLRPC action failed: ', $@);
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
            }
            else {
                if ($xmlrpc->response) {
                    $cb->cb->($xmlrpc->response);
                }
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

=head2 __xmlrpc_result

=cut

sub __xmlrpc_result {
    my @a;
    
    foreach my $k (keys %{$_[1]}) {
        if (ref($_[1]->{$k}) eq 'ARRAY') {
            foreach my $v (@{$_[1]->{$k}}) {
                if (ref($v) eq 'HASH') {
                    push(@a,
                        XMLRPC::Data->new->value({ $k => Lim::RPC::__xmlrpc_result($_[0].'.'.$k, $v) })
                        );
                }
                else {
                    push(@a,
                        XMLRPC::Data->new->value({ $k => $v })
                        );
                }
            }
        }
        elsif (ref($_[1]->{$k}) eq 'HASH') {
            push(@a,
                XMLRPC::Data->new->value({ $k => Lim::RPC::__xmlrpc_result($_[0].'.'.$k, $_[1]->{$k}) })
                );
        }
        else {
            push(@a,
                XMLRPC::Data->new->value({ $k => $_[1]->{$k} })
                );
        }
    }

    if ($_[0] eq 'base') {
        return @a;
    }
    else {
        return \@a;
    }
}

=head2 precall

=cut

sub precall {
    my ($self, $call, $object, $som) = @_;
    
    unless (ref($call) eq '' and blessed($object) and blessed($som) and $som->isa('XMLRPC::SOM')) {
        confess __PACKAGE__, ': Invalid XMLRPC call';
    }

    unless (exists $som->{__lim_rpc_protocol_xmlrpc_cb} and blessed($som->{__lim_rpc_protocol_xmlrpc_cb}) and $som->{__lim_rpc_protocol_xmlrpc_cb}->isa('Lim::RPC::Callback')) {
        confess __PACKAGE__, ': XMLRPC::SOM does not contain lim rpc callback or invalid';
    }
    my $cb = delete $som->{__lim_rpc_protocol_xmlrpc_cb};
    my $valueof = $som->valueof('//'.$call.'/');
    
    if ($valueof) {
        unless (ref($valueof) eq 'HASH') {
            confess __PACKAGE__, ': Invalid data in XMLRPC call';
        }
    }
    else {
        undef($valueof);
    }

    return ($object, $cb, $valueof);
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

1; # End of Lim::RPC::Protocol::XMLRPC
