package Kubernetes::REST;
  use Moo;
  use Types::Standard qw/HasMethods Str InstanceOf/;
  use Kubernetes::REST::CallContext;
  use Kubernetes::REST::Server;
  use Kubernetes::REST::AuthToken;
  use Module::Runtime qw/require_module/;

  our $VERSION = '0.02';

  has param_converter => (is => 'ro', isa => HasMethods['params2request'], default => sub {
    require Kubernetes::REST::ListToRequest;
    Kubernetes::REST::ListToRequest->new;  
  });
  has io => (is => 'ro', isa => HasMethods['call'], lazy => 1, default => sub {
    my $self = shift;
    require Kubernetes::REST::HTTPTinyIO;
    Kubernetes::REST::HTTPTinyIO->new(
      ssl_verify_server => $self->server->ssl_verify_server,
      ssl_cert_file => $self->server->ssl_cert_file,
      ssl_key_file => $self->server->ssl_key_file,
      ssl_ca_file => $self->server->ssl_ca_file,
    );
  });
  has result_parser => (is => 'ro', isa => HasMethods['result2return'], default => sub {
    require Kubernetes::REST::Result2Hash;
    Kubernetes::REST::Result2Hash->new
  });

  has server => (
    is => 'ro',
    isa => InstanceOf['Kubernetes::REST::Server'], 
    required => 1,
    coerce => sub {
      Kubernetes::REST::Server->new(@_);
    },
  );
  #TODO: decide the interface for the credentials object. For now, it if has a token method,
  #      it will use it
  has credentials => (
    is => 'ro',
    required => 1,
    coerce => sub {
      return Kubernetes::REST::AuthToken->new($_[0]) if (ref($_[0]) eq 'HASH');
      return $_[0];
    }
  );

  has api_version => (is => 'ro', isa => Str, default => sub { 'v1' });

  sub _get_group {
    my ($self, $g) = @_;
    my $group = "Kubernetes::REST::$g";
    require_module $group;
    return $group->new(
      param_converter => $self->param_converter,
      io => $self->io,
      result_parser => $self->result_parser,
      server => $self->server,
      credentials => $self->credentials,
      api_version => $self->api_version,
    );
  }

  
  sub Admissionregistration { shift->_get_group('Admissionregistration') }
  
  sub Apiextensions { shift->_get_group('Apiextensions') }
  
  sub Apiregistration { shift->_get_group('Apiregistration') }
  
  sub Apis { shift->_get_group('Apis') }
  
  sub Apps { shift->_get_group('Apps') }
  
  sub Auditregistration { shift->_get_group('Auditregistration') }
  
  sub Authentication { shift->_get_group('Authentication') }
  
  sub Authorization { shift->_get_group('Authorization') }
  
  sub Autoscaling { shift->_get_group('Autoscaling') }
  
  sub Batch { shift->_get_group('Batch') }
  
  sub Certificates { shift->_get_group('Certificates') }
  
  sub Coordination { shift->_get_group('Coordination') }
  
  sub Core { shift->_get_group('Core') }
  
  sub Events { shift->_get_group('Events') }
  
  sub Extensions { shift->_get_group('Extensions') }
  
  sub Logs { shift->_get_group('Logs') }
  
  sub Networking { shift->_get_group('Networking') }
  
  sub Policy { shift->_get_group('Policy') }
  
  sub RbacAuthorization { shift->_get_group('RbacAuthorization') }
  
  sub Scheduling { shift->_get_group('Scheduling') }
  
  sub Settings { shift->_get_group('Settings') }
  
  sub Storage { shift->_get_group('Storage') }
  
  sub Version { shift->_get_group('Version') }
  

  sub _invoke {
    my ($self, $method, $params) = @_;

    my $call = Kubernetes::REST::CallContext->new(
      method => $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  sub invoke_raw {
    my ($self, $req) = @_;
    if (not $req->isa('Kubernetes::REST::HTTPRequest')) {
      die "invoke_raw expects a Kubernetes::REST::HTTPRequest object";
    }

    my $call = Kubernetes::REST::CallContext->new(
      method => "",
      params => [],
      server => $self->server,
      credentials => $self->credentials,
    );
    return $self->io->call($call, $req);
  }

  sub GetAllAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke('GetAllAPIVersions', \@params);
  }

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Kubernetes::REST - A Perl REST Client for the Kubernetes API

=head1 SYNOPSIS

  use Kubernetes::REST;
  my $api = Kubernetes::REST->new(
    credentials => { },
    server => {
      endpoint => 'https://..../',
      ssl_cert_file => '',
      ssl_key_file => '',
      ssl_ca_file => ''
    },
  );

  my $result = $api->Core->ListPodForAllNamespaces;
  use Data::Dumper;
  print Dumper($result); # hashref with the result for

=head1 DESCRIPTION

This module implements the Kubernetes REST API

=head1 STATUS

These are very first versions, so please take into account that this
module is subject to change. Review the Changes file in the dists
to see what has changed or has been explicitly broken

=head1 ORGANIZATION

The root C<Kubernetes::REST> module sets up the data needed to connect
to the Kubernetes server

=head1 ATTRIBUTES

Attributes can be set in the constructor

=head2 server

Is a L<Kubernetes::REST::Server> object. If you pass a HashRef with it's
attributes it will be coerced into the object for you.

  server => { endpoint => '...', ... }

=head3 endpoint

A string containing the URL to the Kubernetes API

=head3 ssl_verify_server

Configures the client to verify SSL properties. Defaults to 1.

=head3 ssl_cert_file

If ssl_verify_server is true, path to the client certificate to use

=head3 ssl_key_file

If ssl_verify_server is true, path to the client certificate key

=head3 ssl_ca_file

If ssl_verify_server is true, path to the CA file

=head2 credentials

  credentials => { token => '' }

This can be any object with a C<token> method. The token will be used
as the Bearer token to the Kubernetes API. You can also pass a hashref
with a C<token> key.

=head2 api_version

This controls the API version of Kuberntes that the client is using. By
default it is C<v1>, but you can set it to C<v1alpha1>, for example to
access v1 methods in alpha stage.

=head1 METHODS

The C<Kubernetes::REST> object give you access to grouped method calls, 
following the API groups of Kubernetes.

  my $api = Kubernetes::REST->new(...);
  $api->Core->ListNamespacedPod(...);


=head2 Admissionregistration

Access to the Admissionregistration group of API calls. See L<Kubernetes::REST::Admissionregistration>
for more info.

=head2 Apiextensions

Access to the Apiextensions group of API calls. See L<Kubernetes::REST::Apiextensions>
for more info.

=head2 Apiregistration

Access to the Apiregistration group of API calls. See L<Kubernetes::REST::Apiregistration>
for more info.

=head2 Apis

Access to the Apis group of API calls. See L<Kubernetes::REST::Apis>
for more info.

=head2 Apps

Access to the Apps group of API calls. See L<Kubernetes::REST::Apps>
for more info.

=head2 Auditregistration

Access to the Auditregistration group of API calls. See L<Kubernetes::REST::Auditregistration>
for more info.

=head2 Authentication

Access to the Authentication group of API calls. See L<Kubernetes::REST::Authentication>
for more info.

=head2 Authorization

Access to the Authorization group of API calls. See L<Kubernetes::REST::Authorization>
for more info.

=head2 Autoscaling

Access to the Autoscaling group of API calls. See L<Kubernetes::REST::Autoscaling>
for more info.

=head2 Batch

Access to the Batch group of API calls. See L<Kubernetes::REST::Batch>
for more info.

=head2 Certificates

Access to the Certificates group of API calls. See L<Kubernetes::REST::Certificates>
for more info.

=head2 Coordination

Access to the Coordination group of API calls. See L<Kubernetes::REST::Coordination>
for more info.

=head2 Core

Access to the Core group of API calls. See L<Kubernetes::REST::Core>
for more info.

=head2 Events

Access to the Events group of API calls. See L<Kubernetes::REST::Events>
for more info.

=head2 Extensions

Access to the Extensions group of API calls. See L<Kubernetes::REST::Extensions>
for more info.

=head2 Logs

Access to the Logs group of API calls. See L<Kubernetes::REST::Logs>
for more info.

=head2 Networking

Access to the Networking group of API calls. See L<Kubernetes::REST::Networking>
for more info.

=head2 Policy

Access to the Policy group of API calls. See L<Kubernetes::REST::Policy>
for more info.

=head2 RbacAuthorization

Access to the RbacAuthorization group of API calls. See L<Kubernetes::REST::RbacAuthorization>
for more info.

=head2 Scheduling

Access to the Scheduling group of API calls. See L<Kubernetes::REST::Scheduling>
for more info.

=head2 Settings

Access to the Settings group of API calls. See L<Kubernetes::REST::Settings>
for more info.

=head2 Storage

Access to the Storage group of API calls. See L<Kubernetes::REST::Storage>
for more info.

=head2 Version

Access to the Version group of API calls. See L<Kubernetes::REST::Version>
for more info.


=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/kubernetes-rest>

Please report bugs to: L<https://github.com/pplu/kubernetes-rest/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
