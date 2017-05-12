package Froody::Structure;
use base qw(Froody::Base);

use strict;
use warnings;

use Scalar::Util qw(blessed);
use Storable;

our $VERSION = 0.01;

=head1 NAME

Froody::Structure - object representing the structure used by the response

=head1 SYNOPSIS

  # abstract class, see Froody::Method or Froody::ErrorType

=head1 DESCRIPTION


=head1 METHODS

=over

=item new()

Create a new reflection object

=cut

=item match_to_regex( "foo.bar.*" )

Class method that returns a regular expression that will determine if a string
matches the specification passed in

=cut

sub match_to_regex
{
  my $whatever = shift;
  my $query = shift;
  
  if ($query =~ /[^a-zA-Z.*]/)
   { Froody::Error->throw("perl.methodcall.param", "Bad method spec '$query'"); }
  
  $query =~ s{\.}{\.}g;    # dots are dots
  $query =~ s/\*/[^.]+/g;  # stars are not dots
  return qr/^$query$/;
}

=back

=head1 ACCESSORS

=over

=item structure

A hash reference containing the specification of how the data that will be
returned will be aranged - essentially the blueprint for constructing the
response.

You probably don't want to create these by hand;  The Froody::API::XML
module will create these given a suitable example.  See that module documentaion
for more info.

The structure is a simple hash with a 'xpath' style key pointing to a hash
containing C<elts> (elements) and C<attr> (attributes) arrayrefs.

 { 'people' =>
       { attr => ['group'],
         elts => [qw/person/],
       },
   'people/person' =>
       { elts => [qw/name/],
         attr => [qw/nick number/],
         text => 0,
         multi => 1,
       },
 };

C<elts> should contain a list of all elements under this node.  Each one of these
elements will require a further entry in the hash unless the element contains
only text and cannot be repeated (for example, the title and description
in the above data structure are like this.)

The hashrefs may also contain other flags.  The C<text> flag can be used to
indicate if it is valid for this node to contain text or not.  The C<multi>
flag is used to indicate if there can be repeate occurances of the elements.

This would mean that the above data structure would validate this XML structure:

 <people group="frameworks" />
   <person nick="clkao" number="243">
     <name>Chia-liang Kao</name>
   </person>
   <person nick="Trelane" number="234">
     <name>Mark Fowler</name>
   </person>
   <person nick="Nichloas" number="238">
     <name>Nicholas Clark</name>
   </person>
   <person nick="nnunley" number="243">
     <name>Norman Nunley</name>
   </person>
   <person nick="skugg" number="214">
     <name>Stig Brautaset</name>
   </person>
   <person nick="jerakeen" number="235">
     <name>Tom Insam</name>
   </person>
   Frameworks is a department of Fotango.  We work on lots of
   software, including writing tools like Froody.
 </people>

=cut

sub structure
{
  my $self = shift;
  return $self->{structure} unless @_;
  if (ref($_[0]))
    { $self->{structure} = Storable::dclone shift }
  else
    { $self->{structure} = shift }
  return $self;
}

=item example_response

An example of the response we expect to see when this is rendered.  This should
be a Froody::Response object.

=cut

sub example_response
{
  my $self = shift;
  return $self->{example_response} unless @_;
  my $rsp = shift;
  
  unless (blessed($rsp) && $rsp->isa("Froody::Response"))
   { Froody::Error->throw("perl.methodcall.param", "example_response only accepts Froody::Response objects not a '$rsp'"); }
  $self->{example_response} = $rsp;
  return $self;
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

L<Froody>, L<Froody::Repository>, L<Froody::Method>, L<Froody::ErrorType>

=cut

1;
