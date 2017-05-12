package Froody::Response::Error;
use base qw(Froody::Response);

use warnings;
use strict;

use Froody::Response::Terse;
use Scalar::Util qw(blessed);

use Froody::Logger;
my $logger = get_logger("froody.response.error");

=head1 NAME

Froody::Response::Error - create a response from an error

=head1 SYNOPSIS

  # from known problems
  my $response = Froody::Response::Error->from_exception($@, $repository)

  print $response->render;

  # or
  
  $response->throw;
  
=head1 DESCRIPTION

This class is designed to allow you to create error responses quickly
and easily.

=cut

# from_exception is documented
sub from_exception {
  my ($class, $error, $repository) = @_;

  unless (blessed($error) && $error->isa("Froody::Error")) {
    $logger->error("unknown error of type ".ref($error)." thrown: $error");
    $logger->error( $error );
    $error = Froody::Error->new('froody.error.unknown');
  }

  my $structure = $repository->get_closest_errortype($error->code);
  return $class->new->set_error( $error )->structure( $structure );
}

# set_error is documented
sub set_error
{
  my $self = shift;
  my $err = shift;

  # make sure it's a Froody Error
  if (blessed($err) && $err->isa("Froody::Error"))
  {
    $self->{error} = $err
  }
  else
  {
    $self->{error} = Froody::Error->new("unknown", "$err");
  }

  return $self;
}

=head1 ACCESSORS

=over

=item code (read only)

=item message (read only)

=item data (read_only)

=item status (read only)

=back

=cut

sub code
{
   my $self = shift;
   if (@_) { Froody::Error->throw("perl.methodcall.param", "code takes no arguments") }
   $self->{error}->code;
}

sub message
{
   my $self = shift;
   if (@_) { Froody::Error->throw("perl.methodcall.param", "message takes no arguments") }
   $self->{error}->message;
}

sub data
{
   my $self = shift;
   if (@_) { Froody::Error->throw("perl.methodcall.param", "data takes no arguments") }
   $self->{error}->data;
}

#####

sub Froody::Response::as_error {
  my $self = shift->as_terse;
   
  # TODO: Error checking
  
  # okay, now from the terse, build an error
  my $content = $self->content;
  my $code = delete $content->{code};
  my $msg  = delete $content->{msg};
  my $error = Froody::Error->new($code, $msg, $content);

  return Froody::Response::Error->new()
                                ->set_error($error)
                                ->structure($self->structure);
}

sub as_error { $_[0] }

sub as_terse
{
  my $self = shift;
  
  my $error = $self->{error};
  
  # make this into the right data structure
  my $data = $error->data;
  $data = {} unless defined $data;
  $data = { -text => $data } unless ref $data;
  
  # add the extra keys
  $data->{msg}  = $error->message;
  $data->{code} = $error->code;
  
  my $terse = Froody::Response::Terse->new
     ->status("fail")
     ->content($data)
     ->structure($self->structure);

  return $terse;
}

sub render {
 my $self = shift;
  $self->as_terse->render();
}

# we always fail

sub status { "fail" }

=head2 throw

Throw the response as an L<Froody::Error> if possible.  It may throw C<undef> if no
error is associated with the current response.

=cut

sub throw
{
  my $self = shift;
  die $self->{error};  # might die with undef.  So be it
}

=head1 BUGS

This is missing the C<argument> functionality from the original
implementation of Froody::Response.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Response>

=cut

1;
