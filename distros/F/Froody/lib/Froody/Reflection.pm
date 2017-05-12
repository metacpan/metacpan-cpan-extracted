package Froody::Reflection;
use base qw(Froody::Implementation);

use strict;
use warnings;

use Froody::Response::XML;
use Froody::Response::Terse;


use Params::Validate qw( :all );

our $IMPLEMENTATION_SUPERCLASS = 1;

sub implements { "Froody::API::Reflection" => 'froody.reflection.*' }

use Froody::Logger;
our $logger = get_logger("froody.reflection");

=head1 NAME

Froody::Reflection

=head1 DESCRIPTION

=head2 Functions

=over


=item getMethodInfo

Returns information for a given froody API method.

=cut

sub getMethodInfo
{
  my ($self, $args, $metadata) = @_;
  
  my $method_name = $args->{method_name};
  my $method = $metadata->{dispatcher}->get_method($method_name);

  return $self->_methodInfo($metadata, $method);
}

sub _methodInfo {
  my ($self, $metadata, $method) = @_;
  my $calling_method = $metadata->{dispatcher}->get_method('froody.reflection.getMethodInfo');

  my $response = {
    name => $method->full_name,
  };

  $response->{description} = $method->description
    if $method->description;
  $response->{needslogin} = $method->needslogin || 0;

  my $arg_info;
  {
    my $arguments = $method->arguments;
    for my $k (keys %$arguments) {
      my $v = $arguments->{$k};
      my $argdata = {
        name => $k,
        -text => $v->{doc},
        optional => $v->{optional},
        type => join(',',@{$v->{type}}),
      };
      push @$arg_info, $argdata;
    }
  }
  $response->{arguments} = { argument => $arg_info } if $arg_info && @$arg_info;

  my $method_errors = $method->errors;
  my $errors = [ map { 
    +{ 
        code => $_,
        message => $method_errors->{$_}{message}, 
        -text => $method_errors->{$_}{description} 
    } } keys %$method_errors ];

  $response->{errors} = { error => $errors } if @$errors;
  $response->{response} = {} if $method->example_response;

  my $rsp = Froody::Response::Terse->new();
  $rsp->content($response);
  $rsp->structure( $calling_method );
  $rsp = $rsp->as_xml;
 
  # find the empty <response>...</response> and shove in our
  # child nodes.  This *must* be encoded in what we are (which is utf-8)
  if ($method->example_response) {
    my ($example_element) = $rsp->xml->findnodes("//response");
    $example_element->appendText( _response_to_xml($method)->toString );
  }
  return $rsp->as_terse; 
}

sub _response_to_xml {
  my $structure = shift;

  # convert whatever we have to XML -- example
  # responses are always stored in terse form (for now)
  my $example = $structure->example_response->as_xml;

  # grab the thingy inside the rsp and return it
  my ($response) = $example->xml->findnodes("/rsp/*");
  return $response->cloneNode(1);
}


=item getMethods

Returns a list of methods.

=cut

sub getMethods
{
  my ($self, $args, $metadata) = @_;

  my $client = $metadata->{dispatcher};
  my $repo = $metadata->{dispatcher}->repository;
  my %methods = map { $_ => 1 } 
                map { $_->full_name } 
                $repo->get_methods;
  
  return {
    method => [ sort map { $_ } keys %methods],
  };
}

=item getErrorTypes

Returns a list of error types.

=cut

sub getErrorTypes
{
  my ($self, $args, $metadata) = @_;

  return {
    errortype => [ sort
                   grep { $_ }
                   map { $_->full_name } 
                   $metadata->{dispatcher}->repository->get_errortypes ],
  };
}

=item getErrorTypeInfo

Returns the error type information

=cut

sub getErrorTypeInfo
{
  my ($self, $args, $metadata) = @_;

  my $repo = $metadata->{dispatcher}->repository;
  my $et = $repo->get_errortype($args->{code});
  return _errortype_hash($et->example_response); 
}

=item getSpecification($args, $metadata)

Returns a terse representation of all public registered methods and error types
within the repository indicated in $metadata

=cut

sub getSpecification {
  my ($self, $args, $metadata) = @_;

  my $repo = $metadata->{dispatcher}->repository;
  my $methods = [ map { $self->_methodInfo($metadata, $_->[0])->as_terse->content }
                  sort { $a->[1] cmp $b->[1] } 
                  map { [$_, $_->full_name ] } 
                  $repo->get_methods ];
                  
  my $errortypes = [ 
                   map { _errortype_hash($_->[0]->example_response) }
                   sort { $a->[1] cmp $b->[1] }
                   grep { $_->[1] } # Skip the default structure
                   map { [ $_, $_->full_name ] } 
                   $repo->get_errortypes 
                   ];
  my $ret = {
    methods => { method => $methods },
    errortypes => { errortype => $errortypes },
  };
  return $ret;
}

sub _errortype_hash {
  my $example = shift;
  my $xml = $example->as_xml->xml; 
  my $ret = {
    code => $xml->findvalue('/rsp/err/@code'),
    -text => join('', map { $_->toString } ($xml->findnodes('/rsp/err/*')))
  };
  return $ret;
}

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>

=cut

1;
