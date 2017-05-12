package Froody::Repository;
use base qw(Froody::Base);

use Froody::Reflection;

use Froody::Dispatch;
use Froody::Method;
use Froody::ErrorType;
use Froody::Logger;
use List::MoreUtils qw(any);


my $logger = get_logger('froody.repository');

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = 0.01;

=head1 NAME

Froody::Repository - a repository of Froody::Method objects.

=head1 SYNOPSIS

  use Froody::Repository;
  my $repository = Froody::Repository->new();
  
  # methods for putting stuff in the repository
  
  $repository->register_implementation('Implementation::Package');
  
  $repository->register_method($froody_method);
  $repository->register_errortype($froody_errortype);
  
  # methods for getting froody methods out
  my $method   = $repository->get_method('name.of.method');
  my @methods  = $repository->get_methods;
  my @methods2 = $repository->get_methods('namespace.of.interest');
  my @methods3 = $repository->get_methods(qr/delete/);
  
  # methods for getting froody errortype out
  my $errortype  = $repository->get_errortype('name.of.errortype');
  my @errortype  = $repository->get_errortypes;
  my @errortype2 = $repository->get_errortypes('errortypes.of.interest');
  my @errortype3 = $repository->get_errortypes(qr/delete/);
  my $errortype2 = $repository->get_closest_errortype('fragment.of.type');

=head1 DESCRIPTION

L<Froody::Repository> provides a central location to register and
discover L<Froody::Method> instances.

=head1 METHODS

=cut

sub init {
  my $self = shift; 

  ### default error ###
  
  my $default = Froody::ErrorType->new()->name("");
  $self->register_errortype($default);

  ### reflection methods and errortypes ###

  $self->register_implementation('Froody::Reflection');
  

  return $self;
}

=head2 Methods for dealing with Froody::Method instances

=over

=item register_method( Froody::Method )

Register a method with the repository.  You don't ever normally have
to call this method yourself, things like your Froody::Implementation
subclasses do it themselves from C<register_in_repository>.

=cut

sub register_method {
  my $self = shift;
  my $method = shift;

  Froody::Error->throw("perl.methodcall.param", "you didn't pass a Froody::Method object")
    unless UNIVERSAL::isa($method, 'Froody::Method');
 
  my $old_method = $self->{method_cache}{$method->full_name};
  unless ($old_method)  {
    $self->{method_cache}{$method->full_name} = $method;
  } elsif ($old_method->full_name !~ m/^froody\.reflection\./) {
    my $inv = $old_method->invoker;
    
    Froody::Error->throw("perl.method.alreadyregistered", 
                         $method->source." was already registered through ".ref $inv);
  }

  return $self;
}

=item get_methods() || get_methods( $regex ) || get_methods( "foo.bar.*" )

Return all methods (as Froody::Method objects) if invoked with no arguments, or
only the methods matching the query if invoked with an argument.

=cut

sub get_methods {
  my $self = shift;
  
  # return everything if no arguments
  unless (@_) { return values %{ $self->{method_cache} } }

  # what methods are we looking for?  Make it a regex if it's not already
  my $query = Froody::Method->match_to_regex( shift );
  return grep { $_->full_name =~ $query }
         values %{ $self->{method_cache} };
}

=item get_method($name)

Return a single method (as a Froody::Method object) matching $name exactly.
Throws a Froody::Error of type "froody.invoke.nosuchmethod" if no method
matching the $name is registered with this repository.

=cut

sub get_method {
  my $self = shift;
  my $name = shift;

  my $method = $self->{method_cache}{ $name }
    or Froody::Error->throw("froody.invoke.nosuchmethod", "Method '$name' not found.");
  return $method;
}

=back

=head2 Methods for dealing with Froody::ErrorType instances

=over

=item register_errortype( Froody::ErrorType )

Register an errortype with the repository.  You don't ever normally have
to call this method yourself, things like your Froody::Implementation
subclasses do it themselves from C<register_in_repository>.

=cut

sub register_errortype {
  my $self = shift;
  my $errortype = shift;
  
  Froody::Error->throw("perl.methodcall.param", "you didn't pass a Froody::ErrorType object")
    unless UNIVERSAL::isa($errortype, 'Froody::ErrorType');
  
  my $code = $errortype->name;
  use Carp; Carp::confess unless defined $code;
  $self->{errortypes_cache}{ $code } = $errortype;

  return $self;
}

=item get_errortype($name)

Return a single errortype (as a Froody::ErrorType object) matching $name exactly.
Throws a Froody::Error of type "froody.invoke.nosucherrortype" if no method
matching the $name is registered with this repository.

=cut

sub get_errortype {
  my $self = shift;
  my $name = shift;

  my $errortype = $self->{errortypes_cache}{ $name }
    or Froody::Error->throw("froody.invoke.nosucherrortype", "ErrorType '$name' not found");
  return $errortype;
}

=item get_errortypes() || get_errortypes( $regex ) || get_errortypes( "foo.bar.*" )

Return all errortypes (as Froody::ErrorTypes objects) if invoked with no
arguments, or only the methods matching the query if invoked with an argument.

=cut

sub get_errortypes {
  my $self = shift;
  my $err_hash = $self->{errortypes_cache};
  
  # return everything if no arguments
  unless (@_) { return values %{ $err_hash } };

  # what methods are we looking for?  Make it a regex if it's not already
  my $query = ref($_[0]) ? shift : Froody::Method->match_to_regex( shift );
  return grep { $_->name =~ $query }
         values %{ $err_hash };
}

=item get_closest_errortype

=cut

sub get_closest_errortype {
  my $self = shift;
  my $code = shift;
  my @bits = split /\./, $code;
  
  my $err_hash = $self->{errortypes_cache};
  
  foreach (reverse 0..$#bits)
  { 
    my $string = join '.', @bits[0..$_];
    if ($err_hash->{ $string }) {   
      return $err_hash->{ $string };
    }
  }
  
  # return the default errortype hash which is always there, as it was
  # created during init.
  return $err_hash->{""};
}

=item register_implementation(PACKAGE NAME)

Registers all the methods associated with a given implementation
and API in this repository.

=cut

sub register_implementation
{
  my $self       = shift;
  my $class      = shift;

  # load the api, if we can.
  $class->require;

  # what of this API do we implement?
  my ($api_class, @method_matches) = $class->implements;
  return unless $api_class; # Allow for superclasses doing crazy things.
  my $invoker = $class->new();

  return $self->register_api($api_class, $invoker, @method_matches);
}

=item register_api($api, $invoker, @method_matches)

Registers all the methods associated with a given API.

=cut
sub register_api {
  my ($self, $api_class, $invoker, @method_matches) = @_;

  @method_matches = map { Froody::Method->match_to_regex( $_ ) } @method_matches;
  # load the api
  $api_class->require
    or Froody::Error->throw("perl.use", "unknown or broken API class: $api_class");

  # process each thing based on it's type
  my @structures;
  foreach my $thingy ($api_class->load())
  {
    if (!blessed($thingy) || !$thingy->isa("Froody::Structure")) {
      $logger->info("$api_class: load() returned the string '$thingy'," 
                    ."which is not a Froody::Structure");
      next;
    }
    push @structures, $thingy;
  }
  $self->load($invoker, \@structures, @method_matches);
}


=item load($invoker, [structures], [method filters])

Loads a set of method and errortype structures into the repository

=cut

sub load {
  my ($self, $invoker, $structures, @method_matches) = @_;

  # process each thing based on its type
  foreach my $thingy (@$structures)
  {
    # froody method?  Set the invoker and register it
    if ($thingy->isa("Froody::Method")) {
      my $full_name = $thingy->full_name;
      # Only bind methods marked as being 'implemented' by the implementation.
      if (@method_matches) {
        next unless any { $full_name =~ $_ } @method_matches;
      } 
      $thingy->invoker($invoker);
      $self->register_method($thingy);
    } elsif ($thingy->isa("Froody::ErrorType")) {
      $self->register_errortype($thingy);
    }
  }

  return $self;
} 


=back

=head1 BUGS

None known

We're using C<match_to_regex> from Froody::Method, maybe that should
be refactored elsewhere

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Method>

=cut

1;
