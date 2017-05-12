package Froody::API;
use base qw(Froody::Base);

use strict;
use warnings;

=head1 NAME

Froody::API - Base class for API definition

=head1 SYNOPSIS

  package Project::API;
  use base 'Froody::API';

  # return all things that this API should register with a repository
  sub load { @stuff }

=head1 DESCRIPTION

This is the base class for classes that define Froody::Method objects,
Froody::ErrorType objects and all other objects that you register in a
repository.

You really shouldn't have to deal with this unless you're creating your
Froody::Methods by hand.  In most cases you'll use the Froody::API::XML
subclass of this.

=head1 METHODS

=over

=item load()

Called by C<define>.  Subclass must override this method to return a list of
objects that we should register with the API some how.  Currently we expect
this list to contain Froody::Method or Froody::ErrorType subclasses, and then
everything else is ignored.

NOTE: C<load()> should return a new instance of the objects each time the method
is called rather than the same one.  This is to prevent bad things happening
if you have more than one repository and they're using different implementations
etc.

=cut

sub load {
  Froody::Error->throw("perl.methodcall.unimplemented", "load must be implemented.");
}

=back

=head1 BUGS

The current implementation of C<get_methods> and C<get_errortypes> doesn't
do anything clever, and therefore calls C<load> twice.  We should refactor
so this isn't the case.

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
