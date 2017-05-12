package Froody::Response;
use base qw(Froody::Base);

use warnings;
use strict;

use Params::Validate qw(SCALAR);
use CGI;

use Scalar::Util qw(blessed);
use Froody::Logger;
my $logger = get_logger('froody.response');

__PACKAGE__->mk_accessors(qw( cookie ));

=head1 NAME

Froody::Response - result of a Froody::Method executing

=head1 SYNOPSIS

  my $response = Froody::Response::String
                   ->new()
                   ->structure($froody_method)
                   ->set_string($string);
  print $response->render;

=head1 DESCRIPTION

This class encapsulates a response from the Froody server, and are what the
Invokers must return when Froody::Methods are called.  You normally don't have
to construct these yourself, as they're built by
Froody::Invoker::Implementation for you from the data structure your code
returned.

This class is an abstract class, with a couple of implementations on
the system.  Basically, responses are something that when you call C<render>
on them produce something that look like this:

  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="ok">
    <foo>bar</foo>
  </rsp>

Or this, if an error has occured:

  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="fail">
    <err code="947" message="Frobinator insufficiently Bamboozled" />
  </rsp>

=head1 METHODS

=over

=item render

Abstract instance method, this method should return a byte encoded XML string
in the standard response format.  By "byte encoded" string we mean that
the characters in the string should contain the bytes corrisponsing the the
encoding scheme mentioned in the returned xml declaration.  

=item cookie

Get/set an arrayref of CGI::cookie instances associated with the response.

=cut

=item add_cookie( name => 'name', value =>'value', expires => 'expires', domain => 'domain' )

Adds an associated a cookie to the response.  Takes the following arguments:

=over

=item name

The name of the cookie (required). This can be any string at all.
Although browsers limit their cookie names to non-whitespace
alphanumeric characters, CGI.pm removes this restriction by escaping and
unescaping cookies behind the scenes.

=item value

The value of the cookie. This can be any scalar value, array reference,
or even associative array reference. For example, you can store an
entire associative array into a cookie this way:

        $cookie=$query->cookie(-name=>'family information',
                               -value=>\%childrens_ages);
=item path

The optional partial path for which this cookie will be valid, as
described above.

=item domain

The optional partial domain for which this cookie will be valid, as
described above.

=item expires

The optional expiration date for this cookie. The format is as described
in the section on the header() method:

  "+1h"  one hour from now

=item secure

If set to true, this cookie will only be used within a secure SSL session.

=back

(these docs from the L<CGI> docs)

=cut

sub add_cookie {
  my $self = shift;
  my %args = $self->validate_object(@_, {
    name       => { type => SCALAR },
    value      => { type => SCALAR },
    expires    => { type => SCALAR, optional => 1 },
    domain     => { type => SCALAR, optional => 1 },
    path       => { type => SCALAR, optional => 1 },
    secure     => { type => SCALAR, optional => 1 },
  });

  my $cookie = CGI::cookie(
    map { "-".$_ => $args{$_} } keys %args
  );

  my $list = $self->cookie || [];
  push @$list, $cookie;
  $self->cookie($list);
  return $self;
}

=item structure

The Froody::Method or Froody::ErrorType associated with this response.
Something that has a 'structure' method, anyhows.

=cut

# method is documented
sub method
{ 
  my $self = shift; 
  print STDERR "Froody::Response->method deprecated (".caller().")\n";
  return $self->structure(@_)
}

sub structure
{
  my $self = shift;
  return $self->{structure} unless @_;
  my $struct = shift;
  
  unless (blessed($struct) && $struct->isa("Froody::Structure")) { 
    Froody::Error->throw("perl.methodcall.param", "structure only accepts Froody::Structure instances (e.g. Froody::Method or Froody::ErrorType") 
  }
   
  $self->{structure} = $struct;
  return $self;
}

=item render

abstract method. Returns a froody-formatted XML response as a byte-sequence,
used as a fall-back to convert between L<Froody::Response> types.

=cut

sub render { Froody::Error->throw("perl.methodcall.unimplemented") }

=item render_xml

Synonym for C<render>.

=cut

sub render_xml { shift->render }

=back

=head1 CONVERSION METHODS

=over

=item as_string

=item as_perlds

=item as_xml

=item as_terse

=item as_error

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

L<Froody>, L<Froody::Response>

=cut

1;

