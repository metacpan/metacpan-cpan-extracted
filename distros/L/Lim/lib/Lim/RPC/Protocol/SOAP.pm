package Lim::RPC::Protocol::SOAP;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();

use SOAP::Lite ();
use SOAP::Transport::HTTP ();

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
    
    delete $self->{soap};
    delete $self->{wsdl};
}

=head2 name

=cut

sub name {
    'soap';
}

=head2 serve

=cut

sub serve {
    my ($self, $module, $module_shortname) = @_;
    my ($wsdl, $calls, $tns, $soap, $soap_name, $dispatch, $obj, $obj_class);
    
    $calls = $module->Calls;
    $tns = $module.'::Server';
    ($soap_name = $module) =~ s/:://go;

    $soap = SOAP::Transport::HTTP::Server->new;
    $soap->serializer->ns('urn:'.$tns, 'lim1');
    $soap->serializer->autotype(0);
    $obj = $self->server->module_obj_by_protocol($module_shortname, $self->name);
    $obj_class = ref($obj);
    # TODO: check if $obj_class alread is a SOAP::Server::Parameters
    eval "push(\@${obj_class}::ISA, 'SOAP::Server::Parameters');";
    if ($@) {
        die $@;
    }
    $dispatch = {};
    foreach my $call (keys %$calls) {
        $dispatch->{'urn:'.$tns.'#'.$call} = $obj;
    }
    $soap->dispatch_with($dispatch);
    $self->{soap}->{$module} = $soap;
                
    $wsdl =
'<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions
 xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
 xmlns:tns="urn:'.$tns.'"
 xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
 name="'.$soap_name.'"
 targetNamespace="urn:'.$tns.'">

';

    # Generate types
    $wsdl .= ' <wsdl:types>
  <xsd:schema targetNamespace="urn:'.$tns.'">
';
    foreach my $call (keys %$calls) {
        my $h = $calls->{$call};
        
        if (exists $h->{in}) {
            $wsdl .= '   <xsd:element name="'.$call.'">
<xsd:complexType>
<xsd:choice minOccurs="0" maxOccurs="unbounded">
';
            $wsdl .= __wsdl_gen_complex_types($h->{in});
            $wsdl .= '</xsd:choice>
</xsd:complexType>
   </xsd:element>
';
        }
        else {
            $wsdl .= '   <xsd:element name="'.$call.'" />
';
        }
        
        if (exists $h->{out}) {
            $wsdl .= '   <xsd:element name="'.$call.'Response">
<xsd:complexType>
<xsd:choice minOccurs="0" maxOccurs="unbounded">
';
            $wsdl .= __wsdl_gen_complex_types($h->{out});
            $wsdl .= '</xsd:choice>
</xsd:complexType>
   </xsd:element>
';
        }
        else {
            $wsdl .= '   <xsd:element name="'.$call.'Response" />
';
        }
    }
    $wsdl .= '  </xsd:schema>
 </wsdl:types>

';
    
    # Generate message
    foreach my $call (keys %$calls) {
        $wsdl .= ' <wsdl:message name="'.$call.'">
  <wsdl:part element="tns:'.$call.'" name="parameters" />
 </wsdl:message>
';
        $wsdl .= ' <wsdl:message name="'.$call.'Response">
  <wsdl:part element="tns:'.$call.'Response" name="parameters" />
 </wsdl:message>
';
    }
    $wsdl .= '
';
                
    # Generate portType
    $wsdl .= ' <wsdl:portType name="'.$soap_name.'">
';
    foreach my $call (keys %$calls) {
        $wsdl .= '  <wsdl:operation name="'.$call.'">
   <wsdl:input message="tns:'.$call.'" />
   <wsdl:output message="tns:'.$call.'Response" />
  </wsdl:operation>
';
    }
    $wsdl .= ' </wsdl:portType>

';
                
    # Generate binding
    $wsdl .= ' <wsdl:binding name="'.$soap_name.'SOAP" type="tns:'.$soap_name.'">
  <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />
';
    foreach my $call (keys %$calls) {
        $wsdl .= '  <wsdl:operation name="'.$call.'">
   <soap:operation soapAction="urn:'.$tns.'#'.$call.'" />
   <wsdl:input>
    <soap:body use="literal" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="literal" />
   </wsdl:output>
  </wsdl:operation>
';
    }
    $wsdl .= ' </wsdl:binding>

';

    # Generate service
    $wsdl .= ' <wsdl:service name="'.$soap_name.'">
  <wsdl:port binding="tns:'.$soap_name.'SOAP" name="'.$soap_name.'SOAP">
   <soap:address location="';

    $wsdl = [ $wsdl, '" />
  </wsdl:port>
 </wsdl:service>

</wsdl:definitions>
' ];

    $self->{wsdl}->{$module} = $wsdl;

    $self;
}

=head2 __wsdl_gen_complex_types

=cut

sub __wsdl_gen_complex_types {
    my @values = @_;
    my $wsdl = '';

    while (scalar @values) {
        my $values = pop(@values);
        
        if (ref($values) eq 'ARRAY' and scalar @$values == 2) {
            my $key = $values->[0];
            $values = $values->[1];
            
            if (blessed $values) {
                $wsdl .= '<xsd:element minOccurs="'.($values->required ? '1' : '0').'" maxOccurs="unbounded" name="'.$key.'"><xsd:complexType><xsd:choice minOccurs="0" maxOccurs="unbounded">
';
                if ($values->isa('Lim::RPC::Value::Collection')) {
                    $values = $values->children;
                }
            }
            else {
                $wsdl .= '<xsd:element minOccurs="0" maxOccurs="unbounded" name="'.$key.'"><xsd:complexType><xsd:choice minOccurs="0" maxOccurs="unbounded">
';
            }
        }
        
        if (ref($values) eq 'HASH') {
            my $nested = 0;
            
            foreach my $key (keys %$values) {
                if (blessed $values->{$key}) {
                    if ($values->{$key}->isa('Lim::RPC::Value::Collection')) {
                        unless ($nested) {
                            $nested = 1;
                            push(@values, 1);
                        }
                        push(@values, [$key, $values->{$key}->children]);
                    }
                    else {
                        $wsdl .= '<xsd:element minOccurs="'.($values->{$key}->required ? '1' : '0').'" maxOccurs="1" name="'.$key.'" type="'.$values->{$key}->xsd_type.'" />
    ';
                    }
                }
                elsif (ref($values->{$key}) eq 'HASH') {
                    unless ($nested) {
                        $nested = 1;
                        push(@values, 1);
                    }
                    push(@values, [$key, $values->{$key}]);
                }
            }
            
            if ($nested) {
                next;
            }
        }
        
        unless (scalar @values) {
            last;
        }
        
        $wsdl .= '</xsd:choice></xsd:complexType></xsd:element>
';
    }
    
    $wsdl;
}

=head2 handle

=cut

sub handle {
    my ($self, $cb, $request, $transport) = @_;
    
    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }

    if ($request->header('SOAPAction') and $request->uri =~ /^\/([a-zA-Z]+)\s*$/o) {
        my ($module) = ($1);
        my $response = HTTP::Response->new;
        my $http_request = $request;
        $response->request($request);
        $response->protocol($request->protocol);
        
        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module) and exists $self->{soap}->{$server->module_class($module)}) {
            my ($action, $method_uri, $method_name);
            my $real_self = $self;
            my $soap = $self->{soap}->{$server->module_class($module)};
            weaken($self);
            weaken($soap);

            Lim::RPC_DEBUG and $self->{logger}->debug('SOAP dispatch to module ', $server->module_class($module), ' obj ', $server->module_obj($module), ' proto obj ', $server->module_obj_by_protocol($module, $self->name));

            $soap->on_dispatch(sub {
                my ($request) = @_;
                
                unless (defined $self and defined $soap) {
                    return;
                }
                
                $request->{__lim_rpc_protocol_soap_cb} = Lim::RPC::Callback->new(
                    request => $http_request,
                    cb => sub {
                        my ($data) = @_;
                        
                        unless (defined $self and defined $soap) {
                            return;
                        }
                        
                        if (blessed $data and $data->isa('Lim::Error')) {
                            $soap->make_fault($data->code, $data->message);
                        }
                        else {
                            my $result;
                            
                            if (defined $data) {
                                $result = $soap->serializer
                                    ->prefix('s')
                                    ->uri($method_uri)
                                    ->envelope(response => $method_name . 'Response', SOAP::Data->value(__soap_result('base', $data)));
                            }
                            else {
                                $result = $soap->serializer
                                    ->prefix('s')
                                    ->uri($method_uri)
                                    ->envelope(response => $method_name . 'Response');
                                $result =~ s/ xsi:nil="true"//go;
                            }
                            
                            $soap->make_response($SOAP::Constants::HTTP_ON_SUCCESS_CODE, $result);
                        }
                        
                        $response = $soap->response;
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
                
                return;
            });
            
            $soap->on_action(sub {
                ($action, $method_uri, $method_name) = @_;
            });

            eval {
                $soap->request($request);
                $soap->handle;
            };
            if ($@) {
                Lim::WARN and $self->{logger}->warn('SOAP action failed: ', $@);
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
            }
            else {
                if ($soap->response) {
                    $cb->cb->($soap->response);
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
    elsif ($request->uri =~ /^\/([a-zA-Z]+)\.wsdl/o) {
        my ($module) = ($1);
        my $response = HTTP::Response->new;
        $response->request($request);
        $response->protocol($request->protocol);
        
        $module = lc($module);
        my $server = $self->server;
        if (defined $server and $server->have_module($module) and exists $self->{wsdl}->{$server->module_class($module)}) {
            my $wsdl = $self->{wsdl}->{$server->module_class($module)};
            my $uri = $transport->uri->clone;
            $uri->path($module);
            
            $response->content($wsdl->[0].
                $uri->as_string.
                $wsdl->[1]);
            $response->header(
                'Content-Type' => 'text/xml; charset=utf-8',
                'Cache-Control' => 'no-cache',
                'Pragma' => 'no-cache'
                );
            $response->code(HTTP_OK);
        }
        else {
            return;
        }

        $cb->cb->($response);
        return 1;
    }
    return;
}

=head2 __soap_result

=cut

sub __soap_result {
    my @a;
    
    foreach my $k (keys %{$_[1]}) {
        if (ref($_[1]->{$k}) eq 'ARRAY') {
            foreach my $v (@{$_[1]->{$k}}) {
                if (ref($v) eq 'HASH') {
                    push(@a,
                        SOAP::Data->new->name($k)
                        ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $v))
                        );
                }
                else {
                    push(@a,
                        SOAP::Data->new->name($k)
                        ->value($v)
                        );
                }
            }
        }
        elsif (ref($_[1]->{$k}) eq 'HASH') {
            push(@a,
                SOAP::Data->new->name($k)
                ->value(Lim::RPC::__soap_result($_[0].'.'.$k, $_[1]->{$k}))
                );
        }
        else {
            push(@a,
                SOAP::Data->new->name($k)
                ->value($_[1]->{$k})
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
    my ($self, $call, $object) = @_;
    my $som = pop(@_);
    
    unless (ref($call) eq '' and blessed($object) and blessed($som) and $som->isa('SOAP::SOM')) {
        confess __PACKAGE__, ': Invalid SOAP call';
    }

    unless (exists $som->{__lim_rpc_protocol_soap_cb} and blessed($som->{__lim_rpc_protocol_soap_cb}) and $som->{__lim_rpc_protocol_soap_cb}->isa('Lim::RPC::Callback')) {
        confess __PACKAGE__, ': SOAP::SOM does not contain lim rpc callback or invalid';
    }
    my $cb = delete $som->{__lim_rpc_protocol_soap_cb};
    my $valueof = $som->valueof('//'.$call.'/');
    
    if ($valueof) {
        unless (ref($valueof) eq 'HASH') {
            confess __PACKAGE__, ': Invalid data in SOAP call';
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

1; # End of Lim::RPC::Protocol::SOAP
