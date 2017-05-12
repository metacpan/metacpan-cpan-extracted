package Froody::Invoker;
use base qw(Froody::Base);

use strict;
use warnings;

our $VERSION = "0.01";

=head1 NAME

Froody::Invoker - provide a way to run a Froody::Method

=head1 SYNOPSIS

  # create a new invoker (for local implementations)
  use Froody::Invoker::Implementation;
  my $inv = Froody::Invoker::Implementation->new()
                                           ->dispatch_class($class);

  # create a method, and assign it an invoker
  my $method = Froody::Method->new()
                             ->full_name("fred.bar.baz")
                             ->invoker($inv);

=head1 DESCRIPTION

If you just want to write a simple Froody server, you don't need to worry about
this class.  Go read the documentation for Froody::Implementation instead.

A Froody::Invoker is the counterpart to a Froody::Method.  It's essentially
responsible for doing whatever task the Froody::Method is describing and
generating the Froody::Response. It's called an 'Invoker' because in most cases
the classes don't actually contain the implementation code itself, they just
know enough to call out to the actual code, or to another server, or
I<somewhere> to get the job done.

For this reason, most users of Froody don't ever need to write their own
Invoker.  They just need to implement the code whatever Invoker they're relying
on calls.

=head2 Standard Invokers

Froody::Invoker itself is an abstract superclass.  There are four concrete
Invoker subclasses that ship in the Froody distribution:

=over

=item Froody::Invoker::Implementation

Allows you to write local implementations with simple Perl methods.

=item Froody::Invoker::Remote

Dispatches calls to a remote Froody server

=back

See the module documentation for each Invoker for more details on how to use
them.

=head2 invoke - Writing Your Own Invokers

The one and only method you need to write for a given Invoker is C<invoke>. 
This method takes two arguments, the Froody::Method that's being invoked and
the hashref containing the parameters that it's being called with.  It has to
return a Froody::Response.

An Invoker is responsible for doing everything from checking the parameters
that have been passed in are correctly formatted to throwing errors if
something goes wrong.  If you throw an error inside an Invoker that's been
called from a Froody::Server it'll be caught by the Dispatcher and turned into
a nice XML style error that'll be sent back to the user.

Here's an example module that simply returns an empty reponse for every
request:

  package Froody::Invoker::Null;
  use base qw(Froody::Invoker);

  use Froody::Response;
  
  sub invoke
  {
     my $self   = shift;
     my $method = shift;
     my $params = shift;
     
     return Froody::Response->new()
  }
  
  1;

=head2 SUPPORT METHODS

=over

=cut

sub invoke {
 Froody::Error->throw("perl.methodcall.unimplemented",
    "This is an abstract base class.  Please implement invoke");
}

=item source

Provides a human readable description
of where the invocation is going to actually occur.

=cut

sub source {
  __PACKAGE__;
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

=over

=item L<Froody::Method> 

=item L<Froody::Implementation>

=item L<Froody::Invoker::Remote>

=back

=cut

1;

