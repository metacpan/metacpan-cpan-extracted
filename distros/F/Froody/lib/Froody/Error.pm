package Froody::Error;
use base qw(Exporter Error);
our @EXPORT_OK = qw(err);

use strict;
use warnings;

use Scalar::Util qw(blessed);
use Storable;
use YAML::Syck;

=head1 NAME

Froody::Error - Froody error class

=head1 SYNOPSIS

  use Froody::Error qw(err);
  
  # throw an error
  eval { 
    Froody::Error->throw("user.problem", "user '$userid' not known", $data);
  };

  # "user.problem, user '9BC6DD8C-1E25-11DA-98F1-DDB51046DF9C' not known, "
  print $@->code .", ". $@->msg

  # and a stacktrace
  print $@->stacktrace

  # print the data section
  print Dumper $@->data;
  
  # check if the error is the right class
  if (err("user"))
  {
    ...
  }

=head1 DESCRIPTION

Froody::Error is the Froody error class.  It's designed to be powerful, yet
simple to use.  It's a subclass of Error.pm.

Often, the easiest way to create an error response from within Froody is
to throw a Froody::Error.  This will be caught by the server, and it'll
be turned into an error response before dispatching it to the client.

Standard Froody::Error errors that are thrown by Froody itself indicating
that something is wrong with Froody (e.g. you've asked for a method that
doesn't exist, or you've ommited a required parameter) are listed in
L<Froody::Error::Standard>.

=head2 throw

To throw an error with Froody::Error you just have to call the throw method
with up to three arguments:

  # throw an error with its code, reporting the default message
  Froody::Error->throw("what");

  # throw an error with its code, reporting a custom message
  Froody::Error->throw("what", "bang");
  
  # throw an error with code, custome message, and some data
  Froody::Error->throw("what", bang", { thingy => "broken" });

In each case this creates a new Froody::Error object and then C<die>s with it.

The first argument is the C<code> that defines the I<type> of error that we're
throwing.  The second argument is a C<message>, a string which describes the
error. If this error is translated to a Froody error response then these will
be mapped to the C<code> and C<message> attributes of the C<< <err> >>
repectivly.  The third argument is the data, a set of parameters that decribe
in a computer understandable format what causes the error.  This data
potentially will be transformed into the children of the C<< <err> >> tag based
on what specification is in the C<errortypes> of the repository.

=head2 Hierarchal Error Messages

Error messages use 'dot' notation to indicate what error messages are
sub-types of other error messages.

For example:

  Froody::Error->throw("io", "Bad IO");

And, a more particular error:

  Froody::Error->throw("io.file", "There was a problem with the file");

And an even more particular error

  Froody::Error->throw("io.file.notfound", "File not found");

But all these methods can be detected with isa_err

  if ($@->isa_err("io")) { ... }

Or even better with the err functions (as this won't go "bang" if $@ is a
hashref)

  use Froody::Error qw(err);
  if (err("io")) { ... }

=cut

# err is documented
sub err
{ 
  no warnings 'uninitialized';
  
  my $code = shift;

  return unless length $@;       # no err? Not an error
  return 1 unless length $code;  # empty spec? Always true
  
  # Froody::Error?  Of the right code?
  if (blessed($@) && $@->isa("Froody::Error"))
    { return $@->isa_err($code) }
  
  # It's an unknown error, were we looking for that?
  # There's no easy way I can see to make this functionality overridable
  # after all, we're in a *function* here, not a method.
  return $code eq "unknown" || $code eq "999";
}

# isa_err is documented
sub isa_err 
{
  no warnings 'uninitialized';

  my $self = shift;
  my $err = shift;

  # empty string === root node === always match
  return 1 unless length $err;

  # if we've no code then we must fail, as we can't possibly match it
  return 0 unless length $self->code;
  
  # do we match? 
  $err = quotemeta($err);
  return $self->code =~ /^$err(?:\.|$)/
}

=head1 METHODS

=over

=item new( message )

define

=cut

sub new {
  my $self  = shift;
  local $Error::Debug = 1;
  local $Error::Depth = $Error::Depth + 1;
  my $code    = shift;
  my $text    = shift;
  my $data    = shift;
  $self->SUPER::new(
    -text => $text,
    -code => $code,
    -data => $data,
  );
}

=item code

Return the error code.  Read only.

=cut

sub code {
  no warnings 'uninitialized';
  length($_[0]->{-code}) ? $_[0]->{-code} : "unknown";
}

=item message / msg / text

Returns the error message.  Read only.

=cut

sub text    { shift->{-text} }
sub msg     { shift->{-text} }
sub message { shift->{-text} }

=item data

Return (a copy of) the error data.  Read only.

=cut

sub _dclone {
 return $_[0] unless ref $_[0];
 return Storable::dclone $_[0];
}

sub data { _dclone(shift->{-data}) }

=item stringify

Returns a string containing both the error code and the error text, and
a stacktrace.  This is what is returned if you try and use a Froody::Error
in string context.

=cut

sub stringify {
  no warnings 'uninitialized';
  my $self    = shift;
  
  my $strace = $self->stacktrace;
  $strace =~ s/^/  /mg;
  
  my $return = $self->code;
  $return .= " - " . $self->message if length($self->message);
  # don't call the ->data method here, as we don't really need to clone the data
  $return .= "\nData:\n".Dump($self->{-data}) if defined $self->{-data};
  return $return . "\nStack trace:\n$strace"
}

=back

=head1 BACKWARDS COMPATIBILITY

We used to have a different sort of error.  Rather than having hierarchal
error codes that looked like this:

  <err code="file.rwerr" message="unable to write to disk" />

We used to use simple numbers and have errors that looked like this:

  <err code="12" message="unable to write to disk" />

This is fine.  The key here to remember is that numbered error codes are a
subset of the hierarchal error codes.  The numbers are all just top level
errors that are made up of alphanumerics that are just digits.  It's just
a not very hierarchal hierarchal error code.

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

L<Froody::Error::Standard>, L<Froody::Response::Error>

=cut

1;
