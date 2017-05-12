use strict;
use warnings;

package Email::MIME::XPath;

our $VERSION = '0.005';
use Tree::XPathEngine;
use Scalar::Util ();
use Carp ();

my (@EXTERNAL_AUTO, @EXTERNAL, @INTERNAL, @SPECIAL);
BEGIN {
  @EXTERNAL_AUTO = qw(findnodes findnodes_as_string findvalue exists find);
  @EXTERNAL      = qw(findnode matches);
  @INTERNAL = qw(get_name get_next_sibling get_previous_sibling get_root_node
    get_parent_node get_child_nodes
    is_element_node
    is_document_node
    is_attribute_node
    is_text_node
    cmp address
    get_attributes
    to_literal);
  @SPECIAL = qw(__xpath_engine __xpath_engine_options __build_parents
    __xpath_parent);
}

use Sub::Exporter -setup => {
  into    => 'Email::MIME',
  exports => [ @EXTERNAL, @SPECIAL, @INTERNAL ],
  groups => {
    external_auto => \&_build_external,
    external => [ @EXTERNAL ],
    internal => [ @INTERNAL ], 
    special  => [ @SPECIAL ],
    default => [
      -external_auto => { -prefix => 'xpath_' },
      -external      => { -prefix => 'xpath_' },
      -internal      => { -prefix => 'xpath_' },
      -internal      => { -prefix => '__xpath_' },
      -special,
    ],
  },
};
 
sub _build_external {
  my ($class, $group, $arg) = @_;
  return {
    map {
      my $method = $_;
      $method => sub {
        my $self = shift;
        $self->__build_parents;
        return $self->__xpath_engine->$method(@_, $self);
      }
    } @EXTERNAL_AUTO
  };
}

sub matches {
  my $self = shift;
  $self->__build_parents;
  my ($path, $context) = @_;
  $context ||= $self;
  return $self->__xpath_engine->matches($self, $path, $context);
};

sub findnode {
  my $self = shift;
  $self->__build_parents;
  my (@nodes) = $self->__xpath_engine->findnodes(@_, $self);
  Carp::croak "findnode found more than one node" if @nodes > 1;
  return $nodes[0];
}

sub __xpath_engine_options { () }

sub __xpath_engine {
  return $_[0]->{__xpath_engine} ||= Tree::XPathEngine->new(
    $_[0]->__xpath_engine_options
  );
}

# this is a terrible, terrible hack.  something like this should be in
# Email::MIME instead.  try to future-proof it somewhat.  -- hdp, 2007-04-20
sub __is_multipart {
  return grep { $_ != $_[0] } $_[0]->parts;
}

# XXX a lot of trickery here is necessary because Email::MIME objects can be
# shared among multiple trees at once.  We keep track of parent/address
# information inside the XPathEngine object, which is (originally) only inside
# the top-level part.
sub __build_parents {
  my $self = shift;
  return if $self->__xpath_engine->{__parent};
  my $parent  = $self->__xpath_engine->{__parent}  = {};
  my $address = $self->__xpath_engine->{__address} = {};
  $self->__xpath_engine->{__root} = $self;
  Scalar::Util::weaken($self->__xpath_engine->{__root});
  my $id = 0;
  $address->{$self} = sprintf("%03d", $id++);
  if (__is_multipart($self)) {
    my @q = $self;
    while (@q) { 
      my $part = shift @q;
      my @subparts = $part->parts;
      for (@subparts) {
        $parent->{$_} = $part;
        Scalar::Util::weaken $parent->{$_};
        $address->{$_} = sprintf("%03d", $id++);
        # XXX this will cause collisions if more than one Email::MIME::XPath
        # shares parts
        $_->{__xpath_engine} = $self->__xpath_engine;
        Scalar::Util::weaken $_->{__xpath_engine};
      }
      push @q, grep { __is_multipart($_) } @subparts;
    }
  }
}

sub __xpath_parent {
  $_[0]->__xpath_engine->{__parent}->{$_[0]}
}

sub address {
  $_[0]->__xpath_engine->{__address}->{$_[0]}
}

sub get_name {
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  my $name =  (split /;/, $_[0]->content_type || 'text/plain')[0];
  $name =~ tr{/+}{._};
  $name = (split /\./, $name)[1];
  #my $name = __is_multipart($_[0]) ? 'multi' : 'part';
  #warn "name = $name";
  return $name;
}
sub get_next_sibling {
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  return;
}
sub get_previous_sibling {
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  return;
}
sub get_root_node {
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  $_[0]->__xpath_engine->{__root}->__xpath_get_parent_node;
}
sub get_parent_node { 
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  my $node = shift;
  return $node->__xpath_parent || bless { root => $node }, 'Email::MIME::XPath::Root';
}
sub get_child_nodes {
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  my @kids = grep { $_ != $_[0] } $_[0]->parts;
  return @kids;
}
sub is_element_node { 1 }
sub is_document_node { 0 }
sub is_attribute_node { 0 }
sub is_text_node { }

sub get_attributes { 
  #my $subname = (caller(0))[3]; warn "$subname from " . $_[0]->__xpath_address;
  my $node = shift;
  my %attr = (
    content_type => (split /;/, $node->content_type || 'text/plain')[0],
    address      => $node->__xpath_address,
    $node->header('Content-Disposition') ? (filename => $node->filename) : (),
    map {
      my $val = $node->header($_);
      defined $val ? (lc($_) => $val) : ()
    } qw(from to cc subject),
  );
  #use Data::Dumper; warn Dumper(\%attr);
  return map {
    bless {
      name  => $_,
      value => $attr{$_},
      node  => $node,
    } => 'Email::MIME::XPath::Attribute'
  } keys %attr;
}
sub cmp { 
  return $_[0]->__xpath_address <=> $_[1]->__xpath_address
}
sub to_literal { }

package Email::MIME::XPath::Root;

sub __xpath_address { -1 } # root is always first
sub xpath_get_child_nodes   { $_[0]->{root} }
sub xpath_get_attributes    { () }
sub xpath_is_document_node  { 1 }
sub xpath_is_element_node   { 0 }
sub xpath_is_attribute_node { 0 }

# my testing doesn't seem to use this, but I've gotten test failures saying
# that it's necessary.  I'm tempted to simply @ISA = Email::MIME::XPath, but
# that might have other undesirable ramifications.

sub xpath_cmp { $_[0]->__xpath_address <=> $_[1]->__xpath_address }

package Email::MIME::XPath::Attribute;

sub xpath_get_value    { return $_[0]->{value} }
sub xpath_get_name     { return $_[0]->{name} }
sub xpath_string_value { return $_[0]->{value} }
sub xpath_is_document_node  { 0 }
sub xpath_is_element_node   { 0 }
sub xpath_is_attribute_node { 1 }
sub to_string { return sprintf('%s="%s"', $_[0]->{name}, $_[0]->{value}) }
sub address { return join(":", $_[0]->{node}, $_[0]->{rank} || 0) }
sub xpath_cmp { $_[0]->address cmp $_[1]->address }

1;

__END__
=head1 NAME

Email::MIME::XPath - access MIME documents via XPath queries

=head1 VERSION

Version 0.005

=head1 SYNOPSIS

  use Email::MIME;
  use Email::MIME::XPath;

  my $email = Email::MIME->new($data);

  # find just the first text/plain node, no matter how many there are
  my ($part) = $email->xpath_findnodes('//plain');

  # find the only text/html node, and die if there is more than one
  $part = $email->xpath_findnode('//html');

  # look for a png by filename
  $part = $email->xpath_findnode('//png[@filename="image.png"]');

  # retrieve a part by previously-stored address
  my $address = $part->xpath_address;
  # ... later ...
  $part = $email->xpath_findnode(qq{//*[@address="$address"]});

=head1 DESCRIPTION

Dealing with MIME messages can be complicated.  Frequently you want to display
certain parts of a message, while alluding to (linking, summarizing, whatever)
other parts in a way that makes them easy to get to later.  Sometimes this can
go several levels deep, if you're dealing with forwarded messages, bounces, or
reports of some kind.

It is especially referring back to sub-parts of an arbitrarily deep MIME
message that is tedious and that this module attempts to make easier.

Most of this module's functionality is provided by
L<Tree::XPathEngine|Tree::XPathEngine>.  Refer to its documentation for
details.  In particular, each of these methods is just a wrapper around the
method of the same name with C<xpath_> removed:

=head3 xpath_findnodes

=head3 xpath_findnodes_as_string

=head3 xpath_findvalue

=head3 xpath_exists

=head3 xpath_matches

=head3 xpath_find

Two other useful methods are made available by Email::MIME::XPath:

=head3 xpath_findnode

This is a wrapper around C<xpath_findnodes> that dies if more than one node is
matched.

TODO: should this also die if no nodes are found?

=head3 xpath_address

This method returns a per-message unique address for a particular part.  This
address is also available as the 'address' attribute in XPath queries; see
L</Attributes>.

=head1 DOM

XPath expects to work on a tree that is DOM-like.  MIME documents are trees,
and this module fakes up enough structure to make XPath useful.

Elements (MIME parts) are given a C<name> that corresponds to the second part
of their Content-Type, e.g.

  multipart/mixed = 'mixed'
  text/plain      = 'plain'

I am open to changing this.  In particular, I would have just used the entire
Content-Type, but using '/' in names would have been problematic and I didn't
want to replace it with something else.  Most of names should be unique,
anyway; I've never seen 'multipart/png' or 'image/html'.  Feel free to
enlighten me.

=head2 Attributes

=head3 subject

=head3 from

=head3 to

=head3 cc

=head3 content_type

All of these attributes are pulled directly from the headers.

=head3 filename

For parts with a Content-Disposition header, the filename is pulled from it.

=head3 address

This attribute is assigned by Email::MIME::XPath as it crawls through the MIME
structure (see L</GUTS>).  For any given top-level MIME document, the address
attribute for each subpart will be stable over time.  If you do your XPath
queries from somewhere other than the top-level MIME part, the addresses will
be different and probably not very useful.

Do not depend on any particular value for any particular address; it should
only be used for temporary reference, not permanent storage.  In particular, it
may change between versions of Email::MIME::XPath, though such changes will be
announced ahead of time.  In the future, it may be possible to specify how
addresses should be assigned on a per-application basis; presumably then they
could be depended on.

=head1 GUTS

This module does a few odd things to work around unfriendly behavior in
Email::MIME.  For example, Email::MIME lets MIME parts be used in several
larger MIME documents at once.  Not only do individual parts not know what
their parent is, they *can't* know, because a single part could be in multiple
trees at once.  Email::MIME::XPath tries to impose a tree structure on relevant
MIME objects without getting in the way, but there are undoubtedly bugs and
unexpected behavior that will arise.

=head1 TODO

Some of the XPath supported by Tree::XPathEngine doesn't work yet, in
particular doing anything with siblings.  Other syntax may work, but in general
it is not yet thoroughly tested.

=head1 SEE ALSO

L<Tree::XPathEngine>, L<Email::MIME>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-mime-xpath at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-MIME-XPath>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::MIME::XPath

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-MIME-XPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-MIME-XPath>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-MIME-XPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-MIME-XPath>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Listbox.com, who sponsored the development of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut





