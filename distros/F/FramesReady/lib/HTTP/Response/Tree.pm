################################################################################
# HTTP::Response::Tree -- set up an environment for tracking frames
# and framesets.  This is packaged with the FramesReady module.
#
# $Id: Tree.pm,v 1.17 2010/03/31 05:53:03 aederhaag Exp $
################################################################################

package   HTTP::Response::Tree;
use       HTTP::Response;
use       vars qw/$VERSION/;	# make it exportable
@ISA = qw(HTTP::Response);

use strict;

$VERSION = sprintf("%d.%03d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

sub new {
  my ($proto, $obj) = @_;
  my $self;
  my $class = ref($proto) || $proto;
  if (ref $obj && ref $obj eq 'HTTP::Response') {
    $self = bless $obj, $class;
  } else {
    $self = $class->SUPER::new();
    bless ($self, $class);
  }

  $self->max_depth(3);
  $self->{_hrt_children} = [];
  $self->{'quiet'} = 0;
  return $self;
}

=head1 NAME

HTTP::Response::Tree - Class for a tree of multiple HTTP::Response objects

=head1 SYNOPSIS

use HTTP::Response::Tree;

@responses = $tree->B<descendants>;

@responses = $tree->B<children>;

$tree->B<max_depth>([$depth]);

$response = $tree->B<member>($uri);

$tree->B<add_child>($response[,$uri]);

$ref = $tree->B<cat_all_content>([$mime_type]);

=head1 DESCRIPTION

This class organizes collections of HTTP::Response objects.  It is
meant to be convenient to robots that collect related Web pages together.
There is also a basic method, cat_all_content(), that may be
convenient to robots that need to analyze collected content in
aggregate form.

The "tree" structure is very simple.  The root object of the tree may be
accessed directly, and any descendant may be accessed by calling
the root's member() method with the descendant's URI.  Also, all descendants
within a tree can be enumerated, and so can the immediate children of the
tree's root.  The methods of each HTTP::Response object
within the tree can be accessed as usual.

=head1 METHODS

HTTP::Response::Tree is, as its name implies, a subclass of
HTTP::Response, and therefore inherits all of its methods.
Note that calling an HTTP::Response method directly on the tree (e.g.
$tree->content) returns the result for the HTTP::Response object at the
tree's root only.  If you need to access the method for a specific descendant
in the tree, but a reference to that descendant is not (yet) available, use
the member() method (e.g. $tree->member($uri)->content).

Here are the methods new to HTTP::Response::Tree:

=over 4

=item @responses = $tree->B<descendants>

Enumerates all of the HTTP::Response objects in the tree that are descendants
of the root, and returns them in an array.

=cut

sub descendants {
  my $self = shift;

  my @descendants;

  my $child;
  foreach $child ($self->children) {
    push @descendants,$child;
    foreach ($child->descendants) {
      push @descendants,$_;
    }
  }
  return @descendants;
}

=cut

=item @responses = $tree->B<children>

Enumerates all of the HTTP::Response objects that are the immediate children
of the root, and returns them in an array.  To return all descendants of
the root and not just the immediate children, use descendants().

=cut

sub children {
  my $self = shift;
  return @{$self->{_hrt_children}};
}

=item $tree->B<max_depth>([$depth])

Sets or returns the maximum depth of the tree.  New instances of
HTTP::Response::Tree are initialized with a max_depth of 3.
0 means the tree may not be any deeper than the root (essentially no more
useful than an HTTP::Response object), 1 means the root may have children
but no grandchildren, etc.

This is meant as a convenience to robots (such as crawlers) that use
HTTP::Response::Tree to collect multiple objects from a starting point,
but need to be kept from straying too far from the starting point.  Calls
to add_child() that exceed the max_depth limit will return undef.

=cut

sub max_depth {
  my $self = shift;
  my $depth = shift;

  if (defined($depth)) {
    $self->{_hrt_max_depth} = int($depth);
  }
  return $self->{_hrt_max_depth};
}

=item $response = $tree->B<member>($uri)

Provides access to the HTTP::Response object in the tree with the given URI,
or undef if there is no such object.  $uri may be a string or an object of
type URI; canonization/normalization of the URI is unnecessary.

=cut

sub member {
  my $self = shift;
  my $uri = shift;

  unless ($uri) {
    warn "member() called without a URI" unless $self->{'quiet'};
    return undef;
  }
  unless (eval{$uri->isa('URI')}) {
    $uri = new URI $uri;
  }
  if ($uri->canonical->as_string eq
      $self->request->uri->canonical->as_string) {
    return $self;
  }
  foreach ($self->children) {
    my $recursion = $_->member($uri);
    if ($recursion) {
      return $recursion;
    }
  }
  return undef;
}

=item $tree->B<add_child>($response[,$uri])

Add a new child to the tree.  It must be an instance of HTTP::Response (or
HTTP::Response::Tree, or anything that inherits from HTTP::Response).
If $uri is not given, a new child of the root is added.
Otherwise, a child of the descendant with the given URI is added.  $uri may be
a string or an object of type URI; canonization/normalization is
unnecessary.  This returns undef on failure (e.g. an object with that URI
already exists, or the tree's max_depth would be exceeded).

=cut

sub add_child {
  my $self = shift;
  my $child = shift;
  my $uri = shift;

  if ($self->max_depth == 0) {
    return undef;
  }

  unless (eval {$child->isa('HTTP::Response')}) {
    return undef;
  } else {
    # BUG:  We want this to bless $child into whatever class
    # $self is in, for the sake of enabling further
    # inheritance.  Instead, this blesses $child into
    # HTTP::Response::Tree.
    # The bless was replaced with new as bless does not initialize
    # pertinent fields in the class
    unless ($child->isa('HTTP::Response::Tree')) {
      $child = $self->new($child);
    }
  }

  if (!$child->request || $self->member($child->request->uri)) {
    return undef;
  }

  if ($uri) {
    # if ($uri->isa('URI')) {
    # 	$uri = $uri->as_string;
    # }
    my $adoptive_parent = $self->member($uri);
    if ($adoptive_parent) {
      return $adoptive_parent->add_child($child);
    } else {
      return undef;
    }
  } else {
    $child->max_depth($self->max_depth - 1);
    push @{$self->{_hrt_children}},$child;
    return $child;
  }
}

=item $ref = $tree->B<cat_all_content>([$mime_type])

Concatenates the content of a selection of objects in the tree, and returns a
reference to the resulting string.  $mime_type is a string to specify a
filter for the type of content to be extracted from the tree;
if not specified, it will default to "text/*".  (That value is the only
one likely to make sense anyway, as the results with any other content type
will probably be very messy.)

=cut

sub cat_all_content {
  my $self = shift;
  my $mime_type = shift || "text/*";

  unless ($mime_type eq "*"
	  or    $mime_type =~ /^[a-z._-]+\/(\*|[a-z._-]+)$/i)
    {
      warn "Possibly invalid MIME type ($mime_type)" unless $self->{'quiet'};
      return undef;
    }

  $mime_type =~ s/\*//;

  my $content = '';
  my $meta = '';
  foreach my $response ($self, ($self->descendants)) {
    next if ($mime_type and
	     (($response->content_type)[0] !~ /^$mime_type/));
    $content .= $response->content;
    $content =~ s/\s+$//;	# strip trailing white space
    if (defined($response->headers->{'x-meta-keywords'})) {
      $meta .= $response->headers->{'x-meta-keywords'};
      $meta =~ s/\s+$//;	# strip trailing white space
    }
  }
  $self->headers->{'x-meta-keywords'} = $meta if $meta;
  $self->content($content) if $content;
  delete $self->{'_hrt_children'}; # clear the array to avoid seeing too much
  return \$content;
}

=back

=head1 NOTES

Each HTTP::Response::Tree is constructed recursively as a collection of
other HTTP::Response::Tree objects.  Therefore, if you create a new class that
inherits from this one, be careful overriding or extending
add_child(), descendants(), and member(), in particular.  (See also
L<"BUGS">.)

=head1 BUGS

If you create a new class that inherits from HTTP::Response::Tree, the
children created with add_child() will still be HTTP::Response::Tree
objects.

=head1 AUTHOR

Larry Gilbert <larry@n2h2.com>

=head1 COPYRIGHT

Copyright 2002 N2H2, Inc.  All rights reserved.

=cut

1;

