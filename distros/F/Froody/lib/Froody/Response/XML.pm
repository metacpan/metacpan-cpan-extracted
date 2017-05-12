package Froody::Response::XML;
use base qw(Froody::Response);

use warnings;
use strict;

use Encode;
use Scalar::Util qw(blessed);
use XML::LibXML;

=head1 NAME

Froody::Response::XML - create a response from a XML::LibXML document

=head1 SYNOPSIS

  my $response = Froody::Response::XML->new()
                                      ->structure($froody_method)
                                      ->xml($xml_doc);
  print $response->render;

=head1 DESCRIPTION

This is a concrete implementation of Froody::Response.  It takes its input
from an XML::LibXML::Document.

  use XML::LibXML;
  my $xml_doc = XML::LibXML::Document->new( "1.0", "utf-8" );
  
  # create the rsp
  my $rsp = $xml_doc->createElement("rsp");
  $rsp->setAttribute("stat", "ok");
  $xml_doc->setDocumentElement($rsp);
  
  # add the child node foo
  my $foo = $xml_doc->createElement("foo");
  $foo->appendText("bar");  # note, must pass bytes in the above encoding
  $rsp->appendChild($foo);
  
  my $rsp = Froody::Response::XML->new()
                                 ->structure($froody_method)
                                 ->xml($xml_doc);

You can get and set the current XML document by usinc C<xml>.  We only hold
a reference to the data so you can modify the XML after you've assigned it
to the response and it'll still effect that response.  This means the
above could be re-ordered as:

  use XML::LibXML;
  my $xml_doc = XML::LibXML::Document->new( "1.0", "utf-8" );
  
  my $rsp = Froody::Response::XML->new()
                                 ->structure($froody_method)
                                 ->xml($xml_doc);
  
  # create the rsp
  my $rsp = $xml_doc->createElement("rsp");
  $rsp->setAttribute("stat", "ok");
  $xml_doc->setDocumentElement($rsp);
  
  # add the child node foo
  my $foo = $xml_doc->createElement("foo");
  $foo->appendText("bar");  # note, must pass bytes in the above encoding
  $rsp->appendChild($foo);

And it'll work just as fine.  This does however mean you should be careful
about re-using XML::LibXML objects between responses.

=cut

# simple get/set accessor, returns self on set and checks what you're setting
# xml is documented
sub xml
{
   my $self = shift;
   return $self->{xml} unless @_;
   unless (blessed($_[0]) && $_[0]->isa("XML::LibXML::Document"))
    { Froody::Error->throw("perl.methodcall.param", 
                           "xml only accepts XML::LibXML::Document instances") }
   $self->{xml} = shift;
   return $self;
}

sub render
{
  my $self = shift;
  my $string = $self->xml->toString(@_);
  my $encoded = Encode::encode("utf-8", $string);
  return $encoded;
}

# status is documented
sub status
{
  my $self = shift;
  $self->xml->findvalue('/rsp/@stat');
}
=head2 Converting other Responses to Froody::Response::XML objects

Once you've loaded this class you can automatically convert other
Froody::Response class instances to Froody::Response::XML objects with
the C<as_xml> method.

  use Froody::Response::String;
  use Froody::Response::XML;
  my $string = Froody::Response::String
      ->new()
      ->structure($froody_method)
      ->set_bytes($bytes);
      ->as_xml;
  print ref($string);  # prints "Froody::Response::XML"

=cut

# rendering this class
# as_xml is documented
sub as_xml { return $_[0] }
sub Froody::Response::as_xml
{
  my $self = shift;
  
  my $parser = XML::LibXML->new();
  my $rendered = $self->render
    or Froody::Error->throw('froody.invoke.badresponse', "No XML returned from call");
  my $doc = eval { $parser->parse_string($rendered) } or die "$rendered";
  
  my $xml = Froody::Response::XML->new();
  $xml->xml($doc);
  $xml->structure($self->structure) if $self->structure;

  return $xml;
}


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
