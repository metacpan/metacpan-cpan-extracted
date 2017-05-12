package Froody::Method;
use base qw(Froody::Structure);

use strict;
use warnings;

use XML::LibXML;
use Carp qw( croak );
use Scalar::Util qw(blessed);

our $VERSION = 0.01;

__PACKAGE__->mk_accessors(qw{ arguments errors needslogin description });

=head1 NAME

Froody::Method - object representing a method callable by Froody

=head1 SYNOPSIS

  # create
  use Froody::Method;
  my $method = Froody::Method->new()
                             ->full_name("wibble.fred.burt")
                             ->invoker($invoker);

  # run the method
  my $froody_response = $method->call( fred => "wilma", barney => "betty" );

  # inspect
  $invoker    = $method->invoker;
  $full_name  = $method->full_name;
  $name       = $method->name;
  $module     = $method->module;

=head1 DESCRIPTION

An accessor class for definition of method APIs.  Once a method is declared
here you can execute it by calling its C<call> function.

Froody::API modules must return from their C<load> method one of these objects
per method that can be called by the Froody server.  That said, it's not
normal to have to write code that creates these, but instead use the
Froody::API::XML to create the Froody::Module objects from
definitions in an XML file.

Method objects must know what they're called and what invoker defines them (and
likewise the invoker class must know what Perl code to run when they're handed
this method object via C<invoke>.)

=head1 METHODS

=over

=item new()

Create a new reflection object

=cut

=item call($params_hashref)

Calls this method.  This dispatches this method via the correct implementation
(as defined by C<implementation> below and returns a Froody::Response object.

=cut

sub call
{
   my ($self, $params_hash, $metadata) = @_;
   
   my $invoker = $self->invoker
    or Froody::Error->throw("froody.invoke.noinvoker", "No invoker defined for this method");
   
   return $invoker->invoke( $self, $params_hash, $metadata );
}

=item match_to_regex( "foo.bar.*" )

Class method that returns a regular expression that will determine if a string
matches the specification passed in

=cut

sub match_to_regex
{
  my $whatever = shift;
  my $query = shift || qr/.*/;
  return $query if ref $query eq 'Regexp';
  
  if ($query =~ /[^a-zA-Z.*]/)
   { Froody::Error->throw("perl.methodcall.param", "Bad method spec '$query'"); }
  
  $query =~ s{\.}{\.}g;    # dots are dots
  $query =~ s/\*{2}/\[\\w\\d.\]+/g;  # double stars match anything.
  $query =~ s/\*/[^.]+/g;  # stars are not dots
  return qr/^$query$/;
}


# right, previously these were all defined using Class::Accessor::Chained::Fast and
# just set in C<new>, which is really, really dumb, since then they could be
# set to inconsistent values later.  Let's not do that, let's compute them on an
# as-needed basis

sub name {
  my $self = shift;
  croak __PACKAGE__."->name is read-only" if @_;
  $self->full_name =~ /\.([^.]+)$/;
  return $1;
}

sub service {
  my $self = shift;
  croak __PACKAGE__."->service is read-only" if @_;
  $self->full_name =~ /^([^.]+)/;
  return $1;
}

sub object {
  my $self = shift;
  croak __PACKAGE__."->object is read-only" if @_;
  my @parts = split /\./, $self->full_name;
  shift @parts; pop @parts; # lose the service and name
  return join "::", map { ucfirst $_ } @parts
}

sub module {
  my $self = shift;
  croak __PACKAGE__."->module is read-only" if @_;
  return ucfirst($self->service) . "::" . $self->object;
}

# and this should be a more complicated accessor that checks that we've
# got all the parts we need

sub full_name
{
  my $self = shift;
  return $self->{full_name} unless @_;
  my $name = shift;
  
  # check the name has at least two dots and otherwise consists
  # of upper and lower case a-z. 
  # HACKERS: Note, if you change this, you'll need to change the
  # code in C<match_to_regex> above
  Froody::Error->throw("perl.methodcall.param", "Invalid Method name '$name'")
    unless $name !~ m/[^a-zA-Z.0-9_]/; 

  $self->{full_name} = $name;
  return $self;
}

=item source

Provide diagnostic information about this method.

=cut

sub source {
  my $self = shift;

  return ($self->invoker ? $self->invoker->source : "unbound").": ".$self->full_name;
}

=back

=head1 ACCESSORS

=over

=item full_name

The full dot-path name of the method.

=item name

The method name.  Read only (set as a side-effect of setting C<full_name>.)

=item module

The perl-style package name of the method. Read only (set as a side-effect of
setting C<full_name>.)

=item service

The service name of of the method. Read only (set as a side-effect of setting
C<full_name>.)

=item object

The class responsible for the overall handling of a method. Read only (set as a
side-effect of setting C<full_name>.)

=item arguments

A hash reference with the names of each argument, with the following structure:
    { 'name' => {
         multiple => 1, 
         optional => 1,
         doc => 'Argument documentation',
         type => 'text', #user defined type label.
       }
    }

If the argument encodes (somehow) multiple values, then multiple must be set. 
If it does not, the 'multiple' key may be omitted, or set to a false value.  An
argument is assumed to be required unless the 'optional' key is set to a true
value.

=item structure

A hash reference containing the specification of how the data that will be
returned by a call to this method will be aranged - essentially the blueprint
for constructing the response.

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

=item example_response

An example of the response we expect to see from the method.  This should
be a Froody::Response object.

=item errors  

A hashref containing a mapping of numeric error code (as the key) to a message
description (as the value.)

=item needslogin

A boolean field.  1 if the user must be 'logged in' in order to use the method.

=item description

A briefer documentation section for the method represented by the
current instance.

=item invoker

The invoker instance that knows about how to run the Perl code needed to
actually do whatever this method is meant to represent.  This must be
a subclass of Froody::Invoker.

=cut

sub invoker {
  my $self = shift;
  return $self->{invoker} unless @_;
  
  # check that that we've been passed an implementation
  unless (blessed($_[0]) && $_[0]->isa("Froody::Invoker"))
  {
    Froody::Error->throw("perl.methodcall.param",
     "You must pass invoker an instance".
     "of something that is a Froody::Invoker, and '$_[0]' isn't");
  }
  
  $self->{invoker} = shift;
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

L<Froody>, L<Froody::Repository>, L<Froody::Invoker>

=cut

1;
