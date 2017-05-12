package Froody::Response::Content;
use base qw(Froody::Response);

use strict;
use warnings;

our $VERSION = "0.01";

use Storable;
use Froody::Error;

=head1 NAME

Froody::Response::Content - common subclass for perl data structure classes

=head1 SYNOPSIS

  package Froody::Response::Subclass;
  use base qw(Froody::Response::Content);

=head1 DESCRIPTION

This is a common subclass used by PerlDS and Terse.  Unless you're
considering patching this file, I wouldn't look at it if I were you.
All these methods are documented again properly in those classes documentation.

Note, there's a C<_to_xml> method that isn't implemented here and has
to be implemented by our subclasses

=head2 Methods

=over

=item status

Get/set the status.  you can only set this to be "ok" or "fail" or it'll
throw a Froody::Error of "perl.methodcall.param"

=cut

sub status {
  my $self = shift;
  return $self->{status} unless @_;
  unless ($_[0] && ($_[0] eq "ok" || $_[0] eq "fail"))
   { Froody::Error->throw("perl.methodcall.param", "status can only be set to 'ok' or 'fail'") }
  $self->{status} = shift;
  return $self;
}

=item content

Get/set the content.  When you set the content it is cloned, but the
actual data structure is returned when you get - so you can alter it directly.
This is considered a feature.

=cut

sub content {
  my $self = shift;
  return $self->{content} unless @_;
 
  # did we get a hash?
#  unless(ref $_[0] && ref $_[0] eq "HASH")
#    { Froody::Error/::Params->throw("content may only be set to a hashref"); }
 
  # default values
  $self->status('ok') unless $self->status;
 
  $self->{content} = ref ($_[0]) ? Storable::dclone shift : shift;
  return $self;
};

sub render {
  my $self = shift;
  my %args = $self->validate_object(@_, {});

  ## check for errors

  # no content?
  unless ($self->content) {
    # we can allow empty responses.
    $self->content({});
  }

  # bad status?
  unless ($self->status) {
    Froody::Error->throw("froody.response",
     "Status must be set to 'ok' or 'fail', not undefined"
    );
  }

  # call the actual render method
  $self->raw_render();
}

=item raw_render

A routine used by the renderer.  No user servicable parts

=cut

sub raw_render()
{
  my $self = shift;

  # get a XML::LibXML::Document representing this document
  
  my $doc = $self->_to_xml($self->content);
  
  # get the XML string, and encode to UTF8 octets
  # pass in 1 here to get nice whitespace
  my $content = $doc->toString(1);
  return Encode::encode("utf-8", $content);
}

=item as_xml

We proxy to the _to_xml method rather than replying on bytification and
back again.

=cut

# shortcut.  We don't have to go all the way to a string
# and back up again to turn this into XML, we can go directly
sub as_xml
{
  my $self = shift;
  my $xml = Froody::Response::XML->new();
  $xml->structure($self->structure);
  $xml->xml($self->_to_xml($self->content));
  return $xml;
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

L<Froody>, L<Froody::Response>, L<Froody::Response::Terse>,
L<Froody::Response::PerlDS>

=cut


1;
