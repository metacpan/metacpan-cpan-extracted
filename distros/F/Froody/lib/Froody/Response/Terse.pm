package Froody::Response::Terse;
use base qw(Froody::Response::Content);
use warnings;
use strict;

use XML::LibXML;
use Encode;
use Params::Validate qw(SCALAR ARRAYREF HASHREF);

use Froody::Logger;
use Froody::Walker;

my $logger = get_logger("froody.response.terse");

use Froody::Response::Error;

=head1 NAME

Froody::Response::Terse - create a response from a Terse data structure

=head1 SYNOPSIS

  my $rsp = Froody::Response::Terse->new();
  $rsp->structure($froody_method);
  $rsp->content({
   group => "imperialframeworks"
   person => [
    { nick => "Trelane",  number => "243", name => "Mark Fowler"    }
    { nick => "jerakeen", number => "235", name => "Tom Insam"      }
   ],
   -text => "Some of Frameworks went to Imperial Collage"
  }
  print $rsp->render();
  
  # prints out (more or less)
  <?xml version="1.0" encoding="utf-8" ?>
  <people group="imperialframeworks">
    <person nick="Trelane" number="234"><name>Mark Fowler</name></person>
    <person nick="jerakeen" number="235"><name>Tom Insam</name></person>
    Some of Frameworks went to Imperial Collage
  </people>

=head1 DESCRIPTION

The Terse response class allows you to construct Responses from a very small
data structure that is the most logical form for the data to take.  It is able
to convert the data to XML by virtue of the specification stored in the
Froody::Method alone.

The data structure is exactly the same that's returned from a method
implementation that's defined in a Froody::Implementation subclass (If you
don't know what that is, I'd go read that module's documentation now if I were
you.)

=head2 Methods

=over 4

=item create_envelope( XML::Document, XML::Node (content) )

You're given one last shot to change the overall format of the response.

The default behavior injects an <rsp stat='status'> wrapper around the C<content>
node.

=back

=head2 Attributes

In addition to the attributes inherited from Froody::Response, this class has
the following get/set methods:

=over 4

=item status

The status of the response, should be 'ok' or 'fail' only.

=item content

The contents of the data structure.  Setting this accessor causes a deep
clone of the data structure to happen, meaning that you can add similar
content to multiple Response objects by setting on one object, altering, then
setting another object.

  my $data = { keywords => [qw( fotango office daytime )] };
  $picture_of_office->content($data);
  push @{ $data->{keywords} } = "Trelane";
  $picture_of_me_in_office->content($data);
  
Note however, this is not true for the returned value from content.  Altering
that data structure really does alter the data in the response (this is
considered a feature)

  # add my name as a keyword as well
  push @{ $picture_of_me_in_office->content->{keywords} }, "Mark";

=back

=cut

# yep, this is all we need to do, everything else is defined in the
# superclass
sub _to_xml
{
    my $self = shift;
    my $content = shift;
    
    # okay, we have an error.  This means we should have a data
    # structure that looks like this:
    # { code => 123, message => "" }
    # and we need to construct XML from it
   
    # okay, we've got a sucessful response.  Create the XML
    my $document = XML::LibXML::Document->new("1.0", "utf-8");
    my $child = $self->_transform('Terse','XML',$self->content, $document);
    my $rsp = $self->create_envelope($document, $child);
    $document->setDocumentElement($rsp);

    return $document;
}

sub create_envelope {
    my ($self, $document, $content) = @_;
    my $rsp = $document->createElement("rsp");
    $rsp->setAttribute("stat" => $self->status );
    $rsp->addChild( $content ) if $content;
    return $rsp;
}

sub _transform {
    my $self = shift;
    my $from = shift;  # the walker class defines what we're transforming to what
    my $to = shift;
    
    my @args = @_;

    my $method = $self->structure
      or Froody::Error->throw("froody.convert.nomethod", "Response has no associated Froody Structure!");

    # FIXME: Shouldn't a lack of structure indicate that we should be using the default
    # structure???
    my $spec = $method->structure
      or Froody::Error->throw("froody.convert.nostructure",
        "Associated method '".$method->full_name."' doesn't have a specification structure!");
    
    my $walker = Froody::Walker->new({
      'spec' => $spec,
      'method' => $method->full_name
    });
    
    # create a new instance of the walker that processes our data
    $from = "Froody::Walker::".$from;
    
    $from->require or Froody::Error->throw("perl.use",
      "couldn't load class $from");
      
    $walker->from($from->new);
   
   # create a new instance of the walker that processes our data
    $to = "Froody::Walker::".$to;
    
    $to->require or Froody::Error->throw("perl.use",
      "couldn't load class $from");
   
    $walker->to($to->new);


    # and walk with it
    return $walker->walk(@args);
}

=head2 Converting other Responses to Froody::Response::Terse objects

Once you've loaded this class you can automatically convert other
Froody::Response class instances to Froody::Response::Terse objects with
the C<as_terse> method.

  use Froody::Response::Terse;
  my $terse = Froody::Response::XML
      ->new()
      ->structure($froody_method)
      ->content({ name => "foo", text => "bar" })
      ->as_terse;
  print ref($terse);  # prints "Froody::Response::Terse"

=cut

# as_terse is documented
sub as_terse { $_[0] } 

sub Froody::Response::as_terse
{
  my $self = shift;
  
  # Er...I have no idea how to do this.  quick, let's turn
  # whatever we are into xml first!
  unless ($self->can('as_xml')) {
    use Carp;
    Carp::confess;
  }
  my $xml = $self->as_xml;

  # create a new terse
  my $terse = Froody::Response::Terse->new();
  $terse->structure($xml->structure);

  # walk the xml and set it as the content
  my ($node) = $xml->xml->findnodes("/rsp/*");
  $terse->content($terse->_transform("XML","Terse", $node));  
  return $terse;
}

sub content
{
  my $self = shift;
  my $ret = $self->SUPER::content(@_);
  if (@_) {
    $ret = $self->_validate_content || $ret;
  }
  return $ret;
}

# Use this only when you're really sure that you have
# valid terse structure and data (ie, don't.)
sub _valid_content {
  my $self = shift;
  $self->SUPER::structure(shift);
  $self->SUPER::content(shift);
}

sub _validate_content
{
  my $self = shift;
  if ($self->structure && $self->content) {
    return $self->SUPER::content($self->_transform("Terse","Terse",$self->content));
  }
}

sub structure
{
  my $self = shift;
  my $ret = $self->SUPER::structure(@_);
  if (@_) {
    $self->_validate_content;
  }
  return $ret;
}

sub as_error
{
  my $self = shift;
  my $data = $self->content;
  my $code = delete $data->{code};
  my $msg  = delete $data->{msg};
  
  my $error = Froody::Error->new(
    $code,
    $msg,
    $data
  );
  
  return Froody::Response::Error->new()
                                ->structure($self->structure)
                                ->set_error($error);
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
