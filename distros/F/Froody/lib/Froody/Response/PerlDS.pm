package Froody::Response::PerlDS;
use base qw(Froody::Response::Content);
use warnings;
use strict;

use XML::LibXML;
use Encode qw(encode);
use Params::Validate qw(SCALAR ARRAYREF HASHREF);

=head1 NAME

Froody::Response::PerlDS - create a response from a Perl data structure

=head1 SYNOPSIS

  my $rsp = Froody::Response::PerlDS->new();
  $rsp->structure($froody_method);
  $rsp->content({
    name => "bob",
    attributes => { foo => "bar" },
    value => "harry",
  });
  print $rsp->render();
  
  # prints out
  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="ok">
    <bob foo="bar">harry</bob>
  </rsp>
  
=head1 DESCRIPTION

DEPRECATED!!!! Please use Froody::Response::Terse

This is a simple type of response that allows you to quickly create
responses from Perl data structures.

For example:

  $response->content({
    name => "bob",
    attributes => { foo => "bar" },
    value => "harry",
  });

will result in the XML:

  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="ok">
    <bob foo="bar">harry</bob>
  </rsp>

and

  $response->content({
    name => "bob",
    attributes => { foo => "bar" },
    children => [
      {
        name => "dave",
        attributes => { fuzz => "ball" },
        value => "ninepence",
      },
    ],
  });

will result in the XML

  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="ok">
    <bob foo="bar">
      <dave fuzz="ball">ninepence</dave>
    </bob>
  </rsp>

Adding content implicitly sets the status to 'ok', unless it is already
set, because this is probably what you mean, and therefore you don't
have to think about it.

=cut

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

  my $data = { name => "fred", attr => { fred => "wilma" } };
  $response_wives->content($data);
  $data->{attr}{fred} = "barney";
  $response_buddies->content($data);
  
Note however, this is not true for the returned value from content.  Altering
that data structure really does alter the data in the response (this is
considered a feature)

  # in the future, fred is buddies with george
  $response_buddies->content->{attr}{fred} = "george";
  
=item root_name

the name of the root node. If unset, this will default to 'rsp'. See
L<default_root_name>.

=back

=cut

__PACKAGE__->mk_accessors(qw(
  root_name
));

=head1 Methods

=over

=item new()

Creates a new, empty message object. Inherited from L<Froody::Base>.

=item find_by_path($xpath)

Finds the correct node in the Froody::Response structure given an
xpath (like) path.

=cut

sub find_by_path {
  my ($self, $target) = @_;
  _find_by_path ({children => $self->{content}}, $target);
}

sub _find_by_path {
    my ($node, $name) = @_;
    return $node unless defined $name;
    my ($lookup, $next) = split '/', $name, 2;
    my ($child) = grep {$_->{name} eq $lookup} @{$node->{children}};
    _find_by_path ($child, $next)
}

=item default_root_name

Returns the default name of the root node. Is "rsp" for this class - you
can override this by subclassing, or by setting the 'root_name' property
on an instance.

=cut

sub default_root_name { "rsp" }

=item raw_render

Internal method, designed for subclassing.  Does the actual rendering.

=cut

sub _to_xml
{
  my $self = shift;
  my $content = shift;
   
  my $doc = XML::LibXML::Document->new("1.0","utf-8");
  my $root = $doc->createElement($self->root_name || $self->default_root_name);
  $root->setAttribute("stat", $self->status);

  # let's recurse again....like we did last summer.
  foreach ($self->_xml_nodes(
    doc  => $doc,
    list => [$content],
  )) { $root->addChild($_) }

  # finally add the root node.
  $doc->addChild($root);

  return $doc;
}

# _xml_nodes( doc => xml docuement, list => listref )
# given a listref of content nodes, return XML::LibXML node objects
# for them. Called recursively for deep structures.
sub _xml_nodes {
  my $self = shift;

  my %args = $self->validate_object(@_, {
    doc  => { isa => "XML::LibXML::Document" },
    list => { type => ARRAYREF },
  });

  my $enc = $args{doc}->getEncoding();

  my @xml_nodes;
  for my $value (@{ $args{list} }) {

    # create the node
    my $name = encode($enc, $value->{name}, 1);
    my $node = $args{doc}->createElement( $name );

    # populate attributes, if any
    
    # we're not doing encoding here because it doesn't work.
    # Yes, I know it should, but it's got one of those hard to track
    # down bugs.
    
    for my $att (sort keys %{ $value->{attributes} || {} }) {
      if (defined $value->{attributes}{$att}) {
        my $key = $att;
        #  Encode::encode($enc, $att, 1);
        my $val = $value->{attributes}{$att};
        #  Encode::encode($enc, $value->{attributes}{$att}, 1);
        $node->setAttribute( $key, $val )
      }
    }

    # set value, if any
    if (defined($value->{value})) {
      # there is a bigger rant here than I really want to think about,
      # so I'm not going to bother. Come to my talk.
      # essentially: you've got to add bytes here in whatever encoding
      # the document is in.  Dontcha just love that?
      use utf8;
      utf8::upgrade( $value->{value} );
      my $text = $args{doc}->createTextNode( $value->{value} );
      $node->addChild( $text );
    }

    # add children, if any
    if (defined($value->{children})) {
      for ($self->_xml_nodes(
        doc => $args{doc},
        list => $value->{children},
      )) {
        $node->addChild($_);
      }
    }

    # add to list of returned nodes
    push @xml_nodes, $node;
  }
  return @xml_nodes;
}

=back

=head2 Converting other Responses to Froody::Response::PerlDS objects

Once you've loaded this class you can automatically convert other
Froody::Response class instances to Froody::Response::PerlDS objects with
the C<as_perlds> method.

  use Froody::Response::String;
  use Froody::Response::PerlDS;
  my $perlds = Froody::Response::String
      ->new()
      ->structure($froody_method)
      ->set_string('<rsp stat="ok"><foo>bar</foo></rsp>');
      ->as_perlds;

  print ref($perlds);  # prints "Froody::Response::PerlDS"

=cut

# as_perlds is documented
sub as_perlds { return $_[0] }
sub Froody::Response::as_perlds
{
  my $self = shift;
  $self = $self->as_xml;  # get as far as XML

  my $perlds = Froody::Response::PerlDS->new()
                                       ->structure($self->structure);
                                       
  # find the top node
  my ($top) = $self->xml->findnodes("/rsp")
    or Froody::Error->throw("froody.convert", "no rsp!");

  my $stat = $top->getAttribute("stat");
  unless (defined($stat) && ($stat eq "ok" || $stat eq "fail"))
   { Froody::Error->throw("froody.convert", "invalid stat!") }
  
  # right, recurse down our XML and turn it into this data structure
  $perlds->content(_recurse_to_ds($top->findnodes("./*")));
  $perlds->status( $stat );
  
  return $perlds;
}

sub _recurse_to_ds
{
  my $node = shift;
  return {} unless $node;
  
  # work out the text content of this node
  my $text = $node->findvalue("./text()");
  $text =~ s/^\s+//;  # lose leading  white space
  $text =~ s/\s+$//;  # lose trailing white space
  
  # what were the attributes?
  my %attr = map { $_->nodeName => $_->getValue } $node->findnodes("./@*");
  
  # what were the children?
  my @children = map { _recurse_to_ds($_) } $node->findnodes("./*");
  
  return {
    name => $node->nodeName,
    
    # text, if there was any text
    ((length $text) ? (value => $text) : ()),
    
    # attributes, if there were any attributes
    ((%attr) ? (attributes => \%attr) : ()),
    
    # children, if there were any children
    ((@children) ? (children => \@children) : ()),
  }
}

=head1 BUGS

Attribute names are not encoded (so people using non ASCII attribute names do
so at their own risk.)  This doesn't work for me, and the whole attributes
vanish unexpectedly.  This is either a XML::LibXML bug or a perl bug, but I
can't produce a small enough test case to make it work.  Patches welcome.

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
