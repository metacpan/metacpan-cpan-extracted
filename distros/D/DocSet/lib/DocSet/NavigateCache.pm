package DocSet::NavigateCache;

use strict;
use warnings;

use DocSet::RunTime;
use DocSet::Util;
use Storable;
use Carp;

# cache the loaded cache files
use vars qw(%CACHE);
%CACHE = ();

#use vars qw(@ISA);
use DocSet::Cache ();
#@ISA = qw(DocSet::Cache);

use constant CACHE       => 0;
use constant ID          => 1;
use constant CUR_PATH    => 2;
use constant REL_PATH    => 3;

# $rel_path (to the parent) is optional (e.g. root doesn't have a parent)
sub new {
    my ($class, $cache_path, $id, $rel_path) = @_;

    croak "no cache path specified" unless defined $cache_path;

    my $cache = get_cache($cache_path);
    my $self = bless [], ref($class)||$class;
    $self->[CACHE]       = $cache;
    $self->[CUR_PATH]    = $cache_path;
    $self->[REL_PATH]    = $rel_path if $rel_path;

    # get the first (#0) node if id wasn't provided (if there are any
    # nodes at all)
    $self->[ID] = defined $id 
        ? $id 
        : $cache->total_ids ? $cache->seq2id(0) : undef;
    return undef unless defined $self->[ID]; # an empty docset

    return $self;
}

sub parent_rel_path {
    my ($self) = @_;
    return defined $self->[REL_PATH] ? $self->[REL_PATH] : undef;
}

# get next item's object or undef if there are no more
sub next {
    my ($self) = @_;
    my $cache    = $self->[CACHE];

    my $seq      = $cache->id2seq($self->[ID]);
    my $last_seq = $cache->total_ids - 1;

    # if the next object is hidden, it's like there is no next object,
    # because the hidden objects, if any, are always coming last
    if ($seq < $last_seq) {
        my $id = $cache->seq2id($seq + 1);
        if ($cache->is_hidden($id)) {
            return undef;
        }
        else {
            return $self->new($self->[CUR_PATH], $id);
        }
    } else {
        return undef;
    }

}

# get prev node's object or undef if there are no more
sub prev {
    my ($self) = @_;
    my $cache = $self->[CACHE];
    my $seq = $cache->id2seq($self->[ID]);

    # if the current node is hidden, it's like there is no prev
    # node, because we don't want hidden node to be linked to the
    # exposed or hidden sibling nodes if any
    if ($cache->is_hidden($self->[ID])) {
        return undef;
    }

    if ($seq) {
        my $id = $cache->seq2id($seq - 1);
        return $self->new($self->[CUR_PATH], $id);
    }
    else {
        return undef;
    }
}

# get the object by its id (string) within the current cache
sub by_id {
    my ($self, $id) = @_;
    return defined $id ? $self->new($self->[CUR_PATH], $id) : undef;
}


# get the object of the first item on the same level
sub first {
    my ($self) = @_;
    my $cache    = $self->[CACHE];

    # it's possible that the whole docset is made of hidden objects.
    # since the hidden objects, if any, are always coming last
    # we simply return undef in such a case
    if ($cache->total_ids) {
        my $id = $cache->seq2id(0);
        if ($cache->is_hidden($id)) {
            return undef;
        }
        else {
            return $self->new($self->[CUR_PATH], $id);
        }
    }
    else {
        return undef;
    }
}


# the index node of the current level
sub index_node {
    my ($self) = @_;
    return $self->[CACHE]->index_node;
}

# get the object of the parent
sub up {
    my ($self) = @_;
    my ($path, $id, $rel_path) = $self->[CACHE]->parent_node;

    $rel_path = "." unless defined $rel_path;
    if (defined $self->[REL_PATH] && length $self->[REL_PATH]) {
        # append the relative path of each child, so the overall
        # relative path is correct
        $rel_path .= "/$self->[REL_PATH]";
    }

    # it's ok to have a hidden parent, we don't mind to see it
    # as non-hidden, since the children of the hidden parent aren't
    # linked from other non-hidden pages. In fact we must ignore the
    # fact that it's hidden (if it is) because otherwise the navigation
    # won't work.
    if ($path) {
        return $self->new($path, $id, $rel_path);
    }
    else {
        return undef;
    }
}

# get the first child node
# note that in order not to break the navigation links, it always
# returns a value if there is a child node, no matter if it's hidden
# or not. so the check for hidden must be done in the caller's code,
# e.g.: $o->down->first - first() will return undef if the first is
# hidden.
sub down {
    my ($self) = @_;

    if (my $path = $self->[CACHE]->child_cache_path($self->[ID])) {
        return $self->new($path);
    }
    else {
        return undef;
    }
}

# retrieve the meta data of the current node
sub meta {
    my ($self) = @_;
    return $self->[CACHE]->get($self->[ID], 'meta');
}

# retrieve the node groups
sub node_groups {
    my ($self) = @_;
#print "OK: "; 
#dumper $self->[CACHE]->node_groups;
    return $self->[CACHE]->node_groups;
}

sub id {
    shift->[ID];
}


sub get_cache {
    my ($path) = @_;

    unless ($CACHE{$path}) {
        $CACHE{$path} = DocSet::Cache->new($path);
        die "Failed to read cache from $path: " . $CACHE{$path}->read_error
            if $CACHE{$path}->read_error;
    }

    return $CACHE{$path};
}


1;
__END__

=head1 NAME

C<DocSet::NavigateCache> - Navigate the DocSet's caches in a readonly mode

=head1 SYNOPSIS

  my $nav = DocSet::NavigateCache->new($cache_path, $id, $rel_path);

  # go through all nodes from left to right, and remember the sequence
  # number of the $nav node (from which we have started)
  my $iterator = $nav->first;
  my $seq = 0;
  my $counter = 0;
  my @meta = ();
  while ($iterator) {
     $seq = $counter if $iterator->id eq $nav->id;
     push @meta, $iterator->meta;
     $iterator = $iterator->next;
     $counter++;
  }
  # add index node's meta data
  push @meta, $nav->index_node;

  # prev object
  $prev  = $nav->prev;

  # get all the ancestry
  my @parents = ();
  $p = $nav->up;
  while ($p) {
      push @parents, $p;
      $p = $p->up;
  }

  # access the docsets of the child nodes
  $child_docset = $nav->down()


=head1 DESCRIPTION

C<DocSet::NavigateCache> navigates the cache created by docset objects
during their scan stage. Once the navigator handle is obtained, it's
possible to move between the nodes of the same level, using the next()
and prev() methods or going up one level using the up() method. the
first() method returns the object of the first node on the same
level. Each of these methods returns a new C<DocSet::NavigateCache>
object or undef if the object cannot be created.

This object can be used to retrieve node's meta data, its id and its
index node's meta data.

Currently it is used in the templates for the internal navigation
widgets creation. That's where you will find the examples of its use
(e.g. I<tmpl/custom/html/menu_top_level> and
I<tmpl/custom/html/navbar_global>).

As C<DocSet::NavigateCache> reads cache files in, it caches them, since
usually the same file is required many times in a few subsequent
calls.

Note that C<DocSet::NavigateCache> doesn't see any hidden objects
stored in the cache.

=head2 METHODS

META: to be completed (see SYNOPSIS meanwhile)

=over

=item * new

  DocSet::NavigateCache->new($cache_path, $id, $rel_path);

C<$cache_path> is the path of the cache file to read.

C<$id> is the id of the current node. if not specified the id for the
first item (0) is retrieved.

If the docset is empty (no items) new returns undef.

C<$rel_path> is optional and passed if an object has a parent node. It
contains a relative path from the current node to its parent.

=item * parent_rel_path

=item * next

=item * prev

=item * first

=item * up

=item * down

=item * index_node

=item * meta

=item * id

=item *

=item *

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>


=cut
