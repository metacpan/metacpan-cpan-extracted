package DocSet::Cache;

use strict;
use warnings;

use DocSet::RunTime;
use DocSet::Util;
use Storable;
use Carp;

my %attrs = map {$_ => 1} qw(toc meta order child_cache_path);

# $update == 1 marks the cache as dirty, so it'll be always written to the disk
# $purge == 1 deletes the existing cache file if such exists
sub new {
    my ($class, $path, $update, $purge) = @_;

    die "no cache path specified" unless defined $path;

    my $self = bless {
        path       => $path,
        dirty      => 0,
        cache      => {},
        read_error => '',
    }, ref($class)||$class;

    if ($purge) {
        $self->purge();
    }
    else {
        $self->read();
    }

    if ($purge || $update) {
        # we will reconstruct the ids order to make sure to reflect the
        # changes in added and removed items (and those who have changed
        # their order)
        $self->{cache}{_ordered_ids} = [];

        # XXX: because we rewrite _order_ids on each invocation, we have to sync
        # the cache to the disk, even if it didn't really change. In the
        # future we may do somechecksum check and write the file only if
        # the checksum has changed, so at this moment the dirty mechanism
        # does nothing
        $self->{dirty} = 1;
    }

    return $self;
}

sub path {
    my ($self) = @_;
    $self->{path};
}

# returns the read error if any
sub read_error {
    shift->{read_error};
}

# check whether the cache file exists and readable
sub can_read {
    -e shift->{path} && -r _;
}

sub purge {
    my $self = shift;
    if (-e $self->{path}) {
        note "!!! Removing cache file $self->{path}";
        unlink $self->{path};
    }
}

sub read {
    my ($self) = @_;

    if (-w $self->{path} && DocSet::RunTime::has_storable_module()) {
        note "+++ Reading cache from $self->{path}";
        eval {
            $self->{cache} = Storable::retrieve($self->{path});
        };
        if ($@) {
            # nuke the cache file
            note "failed to retrieve $self->{path}: $@";
            $self->{read_error} = "$@";
            $self->purge();
        }
    } else {
        note "+++ Initializing a new cache for $self->{path}";
    }
}

sub write {
    my ($self) = @_;

    if (DocSet::RunTime::has_storable_module()) {
        note "+++ Storing the docset's cache to $self->{path}";
        Storable::store($self->{cache}, $self->{path});
        $self->{dirty} = 0; # mark as synced (clean)
    }
}

sub add {
    my ($self, $id) = @_;
    push @{ $self->{cache}{_ordered_ids} }, $id;
    $self->{cache}{$id}{seq} = $#{ $self->{cache}{_ordered_ids} };
}

# set a cache entry (overrides a prev entry if any exists)
sub set {
    my ($self, $id, $attr, $data, $hidden) = @_;

    croak "must specify a unique id"  unless defined $id;
    croak "must specify an attribute" unless defined $attr;
    croak "unknown attribute $attr"   unless exists $attrs{$attr};

#    # remember the addition order (unless it's an update)
#    unless (exists $self->{cache}{$id}) {
#        push @{ $self->{cache}{_ordered_ids} }, $id;
#        $self->{cache}{$id}{seq} = $#{ $self->{cache}{_ordered_ids} };
#    }

    $self->{cache}{$id}{$attr} = $data;
    $self->{cache}{$id}{_hidden} = $hidden;
    $self->{dirty} = 1;
}

# get a cache entry
sub get {
    my ($self, $id, $attr) = @_;

    croak "must specify a unique id"  unless defined $id;
    croak "must specify an attribute" unless defined $attr;
    croak "unknown attribute $attr"   unless exists $attrs{$attr};

    if (exists $self->{cache}{$id} && exists $self->{cache}{$id}{$attr}) {
        return $self->{cache}{$id}{$attr};
    }
}

# check whether a cached entry exists
sub is_cached {
    my ($self, $id, $attr) = @_;

    croak "must specify a unique id"  unless defined $id;
    croak "must specify an attribute" unless defined $attr;
    croak "unknown attribute $attr"   unless exists $attrs{$attr};

    exists $self->{cache}{$id}{$attr};
}

# invalidate cache (i.e. when a complete rebuild is forced)
sub invalidate {
    my ($self) = @_;

    $self->{cache} = {};
}

# delete an entry in the cache
sub unset {
    my ($self, $id, $attr) = @_;

    croak "must specify a unique id"  unless defined $id;
    croak "must specify an attribute" unless defined $attr;
    croak "unknown attribute $attr"   unless exists $attrs{$attr};

    if (exists $self->{cache}{$id}{$attr}) {
        delete $self->{cache}{$id}{$attr};
        $self->{dirty} = 1;
    }

}

sub is_hidden {
    my ($self, $id) = @_;
    #print "$id is hidden\n" if $self->{cache}{$id}{_hidden};
    return $self->{cache}{$id}{_hidden};
}

# return the sequence number of $id in the list of linked objects (0..N)
sub id2seq {
    my ($self, $id) = @_;
    croak "must specify a unique id"  unless defined $id;
    if (exists $self->{cache}{$id}) {
        return $self->{cache}{$id}{seq};
    } 
    else {
        # this shouldn't happen!
        Carp::croak("Cannot find '$id' in $self->{path} cache");
    }

}

# return the $id at the place $seq in the list of linked objects (0..N)
sub seq2id {
    my ($self, $seq) = @_;

    croak "must specify a seq number"  unless defined $seq;
    if ($self->{cache}{_ordered_ids} && defined $self->{cache}{_ordered_ids}->[$seq]) {
        return $self->{cache}{_ordered_ids}->[$seq];
    }
    else {
        Carp::croak("Cannot find '$seq' in $self->{path} cache");
    }
}


sub ordered_ids {
    my ($self) = @_;
    return @{ $self->{cache}{_ordered_ids}||[] };
}

sub total_ids {
    my ($self) = @_;
    return scalar @{ $self->{cache}{_ordered_ids}||[] };
}

# remember the meta data of the index node
sub index_node {
    my ($self) = shift;

    if (@_) {
        my %args = @_;
        my %required = map { $_ => 1} qw(id title stitle);

        for (keys %required) {
            croak "must specify the index_node's $_" unless exists $args{$_};
        }
        # set
        $self->{cache}{_index} = \%args;
    }
    else {
        # get
        return exists $self->{cache}{_index}
            ? $self->{cache}{_index}
            : undef;
    }

}

# set/get the path to the parent cache
sub parent_node {
    my ($self) = shift;

    if (@_) {
        # set
        my ($cache_path, $id, $rel_path) = @_;
        croak "must specify a path to the parent cache"
            unless defined $cache_path;
        croak "must specify a path relative to parent docset"
            unless defined $rel_path;
        croak "must specify a parent id"  unless defined $id;
        $self->{cache}{_parent}{cache_path} = $cache_path;
        $self->{cache}{_parent}{id}         = $id;
        $self->{cache}{_parent}{rel_path}   = $rel_path;
    }
    else {
        # get
        return exists $self->{cache}{_parent}
            ? ($self->{cache}{_parent}{cache_path},
               $self->{cache}{_parent}{id},
               $self->{cache}{_parent}{rel_path})
            : (undef, undef, undef);
    }
}

# get the child node's cache if any
sub child_cache_path {
    my ($self, $id) = @_;
    croak "must specify a id"  unless defined $id;

    return exists $self->{cache}{$id}{child_cache_path}
            ? $self->{cache}{$id}{child_cache_path}
            : undef;
}


# set/get the path to the node_groups cache
sub node_groups {
    my ($self) = shift;

    if (@_) { # set
        $self->{cache}{_node_groups} = shift;
    }
    else { # get
        return $self->{cache}{_node_groups};
    }
}

sub is_dirty { shift->{dirty};}

sub DESTROY {
    my ($self) = @_;

    # flush the cache if destroyed before having a chance to sync to the disk
    $self->write if $self->is_dirty;
}

1;
__END__

=head1 NAME

C<DocSet::Cache> - Maintain a Non-Volatile Cache of DocSet's Data

=head1 SYNOPSIS

  use DocSet::Cache ();

  my $cache = DocSet::Cache->new($cache_path, 1);

  # $cache->read; # read by new() already
  $cache->write;

  # add a cache item to the ordered list
  $cache->add($id);

  # set/unset cached item's attributes
  $cache->set($id, $attr, $data);
  $cache->unset($id, $attr)

  # get cached item's attributes
  my $data = $cache->get($id, $attr);
  print "$id is cached" if $cache->is_cached($id);

  # invalidate cache (deletes all items)
  $cache->invalidate();

  my $seq = $cache->id2seq($id);
  my $id = $cache->seq2id($seq);
  my @ids = $cache->ordered_ids;
  my $total_ids = $cache->total_ids;

  $cache->index_node(
      id       => $id,
      stitle   => $stitle,
      title    => $title,
      abstract => $abstract,
      #...
  );
  my %index_node = $cache->index_node();

  $cache->parent_node($cache_path, $id, $rel_path);
  my ($cache_path, $id, $rel_path) = $cache->parent_node();


=head1 DESCRIPTION

C<DocSet::Cache> maintains a non-volatile cache of docset's data. 

The cache is initialized either from the freezed file at the provided
path. When the file is empty or doesn't exists, a new cache is
initialized. When the cache is modified it should be saved, but if for
some reason it doesn't get saved, the C<DESTROY> method will check
whether the cache wasn't synced to the disk yet and will perform the
sync itself.

Each docset's node can create an entry in the cache, and store its
data in it. The creator has to ensure that it supplies a unique id for
each node that is added.  Cache's internal representation is a hash,
with internal data keys starting with _ (underscore), therefore the
only restriction on node's id value is that it shouldn't not start
with underscore.

=head2 METHODS

META: to be written (see SYNOPSIS meanwhile)

=over

=item * 

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>


=cut
