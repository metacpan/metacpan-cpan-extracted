package Froody::Invoker::Implementation;
use base qw(Froody::Invoker);

use strict;
use warnings;

use File::Spec;
use Froody::Response::Terse;
use Carp qw( croak );
use Froody::Error;
use Froody::Logger;
use Params::Validate qw(:all);
use Scalar::Util qw(blessed);
use List::MoreUtils qw(any);
use Froody::Upload;
my $logger = Froody::Logger->get_logger('froody.invoker.implementation');

use constant response_class => 'Froody::Response::Terse';


sub get_invoke_function {
    my ($self, $module, $method) = @_;
    return $module->can($method->name);
}

sub invoke {
  my ($self, $method, $params, $metadata) = @_;
 
  # load the module if we need to
  my $module = $self->module($method);
  
  # get the perl code we're actually going to call
  my $func = $self->get_invoke_function($module, $method) or
      $logger->logdie("no such method: ".$method->name." in $module");

  # create the context object, and return the instance that you
  # can call the other methods on.  By default, this simply returns
  # the current object (i.e. $invocation is the same as $self)
  my $invocation = $self->create_context($method->full_name, $params);

  my $response;
  
  eval {
    # run the gauntlet
    # munge the arguments
    $invocation->pre_process($method, $params);
    
    # call the perl code
    my $data = $invocation->$func($params, $metadata);

    # convert return shape into the reponse
    $response = $invocation->post_process($method, $data, $metadata);
  };

  if ($@) {
    $response = $invocation->error_handler($method, $@, $metadata);
  }

  # store extra stuff in the response (e.g. cookies)
  $invocation->store_context($response);

  return $response;
}

############
# these are all helper methods for this particular implmentation
# that are either called directly or indirectly from invoke

sub error_handler {
  my ($self, $method, $error, $metadata) = @_;
  # TODO - error_class should be an implementation / invoker method, not
  # on the dispatcher!!
  my $error_class = $metadata->{dispatcher}->error_class;
  return $error_class->from_exception( $error, $metadata->{repository} );
}

sub create_context {
  my ($self, $params) = @_;
  return $self;
}

sub store_context {
  return
}

sub pre_process {
  my ($self, $method, $params) = @_;
  my $spec = $method->arguments;

  # you can't send 'undef' across HTTP, so all the param validators assume
  # that undef isn't a valid value for a param. This seems reasonable. For
  # maximum DWIM, remove undef vaules, so that the implementation thinks that
  # they weren't passed.
  for (keys %$params) {
    delete $params->{$_} unless defined($params->{$_});
  }

  # special case for remainder;
  my ($remainder) = grep { $spec->{$_}{type}[0] eq 'remaining' } keys %$spec;

  my @errors;
  our $argname;
  my $check = sub {
    my ($test, $message) = @_;
    return 1 if $test;
    push @errors, { name => $argname, -text => $message};
    return;
  };

  # it'll always be a hashref.
  $params->{$remainder} = {} if $remainder;
  for $argname (grep { !exists $spec->{$_} } keys %$params) {
    if ($remainder) {
      $params->{$remainder}{$argname} = delete $params->{$argname};
    } else {
      $check->(!$remainder, "Unexpected argument.");
      delete $params->{$argname};
    }
  }

  require Froody::Argument;
  for $argname (keys %$spec) {
    my $param = $params->{$argname};
    if (!defined($param)) {
      $check->( $spec->{$argname}{optional}, "Missing argument." );
      next;
    }
    for my $type (@{$spec->{$argname}{type}}) {
      next if $type eq 'remaining';
      # XXX: make the type plugin declare this
      if (ref($param) eq 'ARRAY' && any { $type eq $_ } qw(text number)) {
        for (0..$#{$param}) {
          $param->[$_] = Froody::Argument->process($type, $param->[$_], $check);
        }
      }
      else {
        $param = Froody::Argument->process($type, $param, $check);
      }
    }
    $params->{$argname} = $param;
  }

  if (@errors) {
    my $errdata = { error => [ @errors ] };
    Froody::Error->throw("perl.methodcall.param", 
                         "Error validating incoming parameters",
                         $errdata);
  }

  return;
}

sub post_process {
  my ($self, $method, $data) = @_;

  $logger->logconfess("called with old style post_process")
      unless UNIVERSAL::isa($method,'Froody::Method');

  # have a response already?  Don't bother doing anything
  return $data if blessed($data) && $data->isa("Froody::Response");

  # build a response
  my $response = $self->response_class->new;
  $response->content($data);
  $response->structure($method);
  return $response;
}


sub module {
  my ($self, $method) = @_;

  unless ( $self->can($method->name) ) {
    my $module = ref $self || $self;
    Froody::Error->throw("perl.use", "module $module cannot '" . $method->name . "'");
  }

  return $self;
}

1;

__DATA__

=head1 NAME

Froody::Implementation - define what should be run for a Froody::Method

=head1 SYNOPSIS

  # run the code from the froody method
  my $implementation_obj = $froody_method->implementation();
  my $response = $implementation_obj->invoke($froody_method, \%params);
  $response->render;
  
=head1 DESCRIPTION

You probably don't care about this class unless you want to change the way that
your Perl code is called for a given method (e.g. you want to dynamically
create methods or do something clever with sessions.)

Froody::Implementation and its subclasses are responsible for implementing the
Perl code that is run when a Froody::Method is called.  Essentially a
Froody::Method only really knows what it's called and that the instance of
another class - its implementation - knows how to run the code.

In reality, all a Froody::Implementation really has to do is implement an
C<invoke> method, that when passed a Froody::Method and a hashref containing
named parameters can 'execute' that method and return a Froody::Response:

  my $response = $implementation_obj->invoke($froody_method, $hash_params);

This module provides a default implementation that calculates a Perl method
name by transforming the Froody::Method name.  Before it runs that method it
pokes around with the arguments passed in based on the Froody::Method's
arguments.  When that Perl method returns, it transforms the hashref that code
returned into a proper Froody::Response based on the response defined for the
Froody::Method that is being processed.  Essentially, it wraps the Perl code
that you have to write in such a way you don't even have to think about what's
going on from Froody's point of view.

=head1 METHODS

=over

=item $self->repository

A get/set accessor that gets/sets what repository this invoker is
associated with.  This is a weak reference.

=item $self->get_invoke_function( name )

returns the function to be called to invoke a method. Simply returns
the result of 'can' in the default implementation.

=item $self->module($method)

Given a L<Froody::Method> object, require and return the module
that the method will be dispatched to.

=item $self->create_context($params)

Returns the context of the current invocation.  By default this return the
class, so it's not instantiating.  Override this to provide session
management in C<store_context>.

=item $self->store_context($response)

Serialize the current context into C<$response>.  By default this does
nothing, you can override this and add a cookie to the response object.

=item $context->pre_process($method, $params)

Called by C<invoke> before the actual method call.

=item $context->post_process($method, $data)

Builds a L<Froody::Response::Terse> object according to the method's response
specification and the data returned from the method.

=item $context->error_handler($method_name, $error)

=back

=head1 SEE ALSO

L<Froody::Repository>, L<Froody::API> and for other implementations
L<Froody::Implementation::OneClass> and L<Froody::Implementation::Remote>

=head1 AUTHORS

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
