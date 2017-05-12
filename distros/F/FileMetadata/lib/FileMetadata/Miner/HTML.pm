package FileMetadata::Miner::HTML;

require HTML::Parser;
@ISA = qw(HTML::Parser);
use HTML::Entities ();
use strict;
use utf8;
our $VERSION = '1.0';

sub new {

  my $class = shift;
  my $self = $class->SUPER::new(); # Inheriting

  # Set handlers

  $self->handler (text => 'text', "self, text");
  $self->handler (start => 'start', 'self, tagname, attr');
  $self->handler (end => 'end', 'self, tagname');

  return $self;

}

sub mine {

  my ($self, $path, $meta) = @_;
  $self->{data} = $meta;
  return 0 unless defined $self->parse_file ($path);
  return 1;

}

#
# This method handles text by appending it to the title key of 
# $self->{'data'} when the tag is title. We are not interested in
# any other text
#

sub text {

  my ($self, $text) = @_;
  $self->{'data'}->{ref ($self)."::".'title'} .= $text
    if defined $self->{'tag-title'};

}

#
# This method handles start tags. It ignores all but meta and title tags
#

sub start {

  my($self, $tag, $attr) = @_;

  if ($tag eq 'meta' && defined $attr->{'name'}) {
    $self->{'data'}->{ref ($self)."::".$attr->{'name'}} = $attr->{'content'};
  } elsif ($tag eq 'title') {
    # Flag this
    $self->{'tag-title'} = '';
  }

}

sub end {

  my($self, $tag) = @_;

  # Stop processing
  $self->eof() if ($tag eq 'head');

  # Unflag
  delete $self->{'tag-title'};

}

1;

__END__

=head1 NAME

FileMetadata::Miner::HTML

=head1 SYNOPSIS

  use FileMetadata::Miner::HTML;

  my $miner = FileMetadata::Miner::HTML->new ({});

  my $meta = {};

  print "TITLE: $meta->{'title'}" if $miner->mine ('ex.html', $meta);

=head1 DESCRIPTION

This module extracts metadata from HTML files. The only tags of interest are
the <TITLE> and the <META> tags withing the <HEAD> tag within the
<HTML> tag. The HTTP-EQUIV attribute describes metadata with operational
significance to the HTTP protocol and is hence ignored by this module.

This method implements interfaces for the FileMetadata framework but can
be used independently.

=head1 METHODS

=head2 new

See L<FileMetadata::Miner/"new">

This module does not accept any config options.

=head2 mine

See L<FileMetadata::Miner/"mine">

The mine method extracts the 'title' and 'meta' information from a HTML
document. The following keys are inserted in the meta hash.

1. FileMetadata::Miner::HTML::title - Test enclosed by the <title> tags

2. FileMetadata::Miner::HTML::* - where * is the value of the 'name'
   attribute to a meta tag and the value of this key is the value of the
   content attribute.

If a meta tag is present with the value of name set to 'title', the value
of the FileMetadata::Miner::HTML key is the determined from the latter
occureence.

=head1 VERSION

1.0 - This is the first release

=head1 REQUIRES

HTML::Parser

=head1 AUTHOR

Midh Mulpuri midh@enjine.com

=head1 LICENSE

This software can be used under the terms of any Open Source Initiative
approved license. A list of these licenses are available at the OSI site -
http://www.opensource.org/licenses/

=cut
