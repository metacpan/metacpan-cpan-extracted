package File::KDBX::Object;
# ABSTRACT: A KDBX database object

use warnings;
use strict;

use Devel::GlobalDestruction;
use File::KDBX::Constants qw(:bool);
use File::KDBX::Error;
use File::KDBX::Util qw(:uuid);
use Hash::Util::FieldHash qw(fieldhashes);
use List::Util qw(any first);
use Ref::Util qw(is_arrayref is_plain_arrayref is_plain_hashref is_ref);
use Scalar::Util qw(blessed weaken);
use namespace::clean;

our $VERSION = '0.902'; # VERSION

fieldhashes \my (%KDBX, %PARENT, %TXNS, %REFS, %SIGNALS);


sub new {
    my $class = shift;

    # copy constructor
    return $_[0]->clone if @_ == 1 && blessed $_[0] && $_[0]->isa($class);

    my $data;
    $data = shift if is_plain_hashref($_[0]);

    my $kdbx;
    $kdbx = shift if @_ % 2 == 1;

    my %args = @_;
    $args{kdbx} //= $kdbx if defined $kdbx;

    my $self = bless $data // {}, $class;
    $self->init(%args);
    $self->_set_nonlazy_attributes if !$data;
    return $self;
}

sub _set_nonlazy_attributes { die 'Not implemented' }


sub init {
    my $self = shift;
    my %args = @_;

    while (my ($key, $val) = each %args) {
        if (my $method = $self->can($key)) {
            $self->$method($val);
        }
    }

    return $self;
}


sub wrap {
    my $class   = shift;
    my $object  = shift;
    return $object if blessed $object && $object->isa($class);
    return $class->new(@_, @$object) if is_arrayref($object);
    return $class->new($object, @_);
}


sub label { die 'Not implemented' }


my %CLONE = (entries => 1, groups => 1, history => 1);
sub clone {
    my $self = shift;
    my %args = @_;

    local $CLONE{new_uuid}              = $args{new_uuid} // $args{parent} // 0;
    local $CLONE{entries}               = $args{entries}  // 1;
    local $CLONE{groups}                = $args{groups}   // 1;
    local $CLONE{history}               = $args{history}  // 1;
    local $CLONE{reference_password}    = $args{reference_password} // 0;
    local $CLONE{reference_username}    = $args{reference_username} // 0;

    require Storable;
    my $copy = Storable::dclone($self);

    if ($args{relabel} and my $label = $self->label) {
        $copy->label("$label - Copy");
    }
    if ($args{parent} and my $parent = $self->group) {
        $parent->add_object($copy);
    }

    return $copy;
}

sub STORABLE_freeze {
    my $self    = shift;
    my $cloning = shift;

    my $copy = {%$self};
    delete $copy->{entries} if !$CLONE{entries};
    delete $copy->{groups}  if !$CLONE{groups};
    delete $copy->{history} if !$CLONE{history};

    return ($cloning ? Hash::Util::FieldHash::id($self) : ''), $copy;
}

sub STORABLE_thaw {
    my $self    = shift;
    my $cloning = shift;
    my $addr    = shift;
    my $copy    = shift;

    @$self{keys %$copy} = values %$copy;

    if ($cloning) {
        my $kdbx = $KDBX{$addr};
        $self->kdbx($kdbx) if $kdbx;
    }

    if (defined $self->{uuid}) {
        if (($CLONE{reference_password} || $CLONE{reference_username}) && $self->can('strings')) {
            my $uuid = format_uuid($self->{uuid});
            my $clone_obj = do {
                local $CLONE{new_uuid}              = 0;
                local $CLONE{entries}               = 1;
                local $CLONE{groups}                = 1;
                local $CLONE{history}               = 1;
                local $CLONE{reference_password}    = 0;
                local $CLONE{reference_username}    = 0;
                # Clone only the entry's data and manually bless to avoid infinite recursion.
                bless Storable::dclone({%$copy}), 'File::KDBX::Entry';
            };
            my $txn = $self->begin_work(snapshot => $clone_obj);
            if ($CLONE{reference_password}) {
                $self->password("{REF:P\@I:$uuid}");
            }
            if ($CLONE{reference_username}) {
                $self->username("{REF:U\@I:$uuid}");
            }
            $txn->commit;
        }
        $self->uuid(generate_uuid) if $CLONE{new_uuid};
    }

    # Dualvars aren't cloned as dualvars, so dualify the icon.
    $self->icon_id($self->{icon_id}) if defined $self->{icon_id};
}


sub kdbx {
    my $self = shift;
    $self = $self->new if !ref $self;
    if (@_) {
        if (my $kdbx = shift) {
            $KDBX{$self} = $kdbx;
            weaken $KDBX{$self};
        }
        else {
            delete $KDBX{$self};
        }
    }
    $KDBX{$self} or throw 'Object is disconnected', object => $self;
}


sub is_connected {
    my $self = shift;
    return !!eval { $self->kdbx };
}


sub id { format_uuid(shift->uuid, @_) }


sub group {
    my $self = shift;

    if (my $new_group = shift) {
        my $old_group = $self->group;
        return $new_group if Hash::Util::FieldHash::id($old_group) == Hash::Util::FieldHash::id($new_group);
        # move to a new parent
        $self->remove(signal => 0) if $old_group;
        $self->location_changed('now');
        $new_group->add_object($self);
    }

    my $id   = Hash::Util::FieldHash::id($self);
    if (my $group = $PARENT{$self}) {
        my $method = $self->_parent_container;
        return $group if first { $id == Hash::Util::FieldHash::id($_) } @{$group->$method};
        delete $PARENT{$self};
    }
    # always get lineage from root to leaf because the other way requires parent, so it would be recursive
    my $lineage = $self->kdbx->_trace_lineage($self) or return;
    my $group = pop @$lineage or return;
    $PARENT{$self} = $group; weaken $PARENT{$self};
    return $group;
}

sub _set_group {
    my $self = shift;
    if (my $parent = shift) {
        $PARENT{$self} = $parent;
        weaken $PARENT{$self};
    }
    else {
        delete $PARENT{$self};
    }
    return $self;
}

### Name of the parent attribute expected to contain the object
sub _parent_container { die 'Not implemented' }


sub lineage {
    my $self = shift;
    my $base = shift;

    my $base_addr = $base ? Hash::Util::FieldHash::id($base) : 0;

    # try leaf to root
    my @path;
    my $object = $self;
    while ($object = $object->group) {
        unshift @path, $object;
        last if $base_addr == Hash::Util::FieldHash::id($object);
    }
    return \@path if @path && ($base_addr == Hash::Util::FieldHash::id($path[0]) || $path[0]->is_root);

    # try root to leaf
    return $self->kdbx->_trace_lineage($self, $base);
}


sub remove {
    my $self = shift;
    my $parent = $self->group;
    $parent->remove_object($self, @_) if $parent;
    $self->_set_group(undef);
    return $self;
}


sub recycle {
    my $self = shift;
    return $self->group($self->kdbx->recycle_bin);
}


sub recycle_or_remove {
    my $self = shift;
    my $kdbx = eval { $self->kdbx };
    if ($kdbx && $kdbx->recycle_bin_enabled && !$self->is_recycled) {
        $self->recycle;
    }
    else {
        $self->remove;
    }
}


sub is_recycled {
    my $self = shift;
    eval { $self->kdbx } or return FALSE;
    return !!($self->group && any { $_->is_recycle_bin } @{$self->lineage});
}

##############################################################################


sub tag_list {
    my $self = shift;
    return grep { $_ ne '' } split(/[,\.:;]|\s+/, trim($self->tags) // '');
}


sub custom_icon {
    my $self = shift;
    my $kdbx = $self->kdbx;
    if (@_) {
        my $img = shift;
        my $uuid = defined $img ? $kdbx->add_custom_icon($img, @_) : undef;
        $self->icon_id(0) if $uuid;
        $self->custom_icon_uuid($uuid);
        return $img;
    }
    return $kdbx->custom_icon_data($self->custom_icon_uuid);
}


sub custom_data {
    my $self = shift;
    $self->{custom_data} = shift if @_ == 1 && is_plain_hashref($_[0]);
    return $self->{custom_data} //= {} if !@_;

    my %args = @_     == 2 ? (key => shift, value => shift)
             : @_ % 2 == 1 ? (key => shift, @_) : @_;

    if (!$args{key} && !$args{value}) {
        my %standard = (key => 1, value => 1, last_modification_time => 1);
        my @other_keys = grep { !$standard{$_} } keys %args;
        if (@other_keys == 1) {
            my $key = $args{key} = $other_keys[0];
            $args{value} = delete $args{$key};
        }
    }

    my $key = $args{key} or throw 'Must provide a custom_data key to access';

    return $self->{custom_data}{$key} = $args{value} if is_plain_hashref($args{value});

    while (my ($field, $value) = each %args) {
        $self->{custom_data}{$key}{$field} = $value;
    }
    return $self->{custom_data}{$key};
}


sub custom_data_value {
    my $self = shift;
    my $data = $self->custom_data(@_) // return undef;
    return $data->{value};
}

##############################################################################


sub begin_work {
    my $self = shift;

    if (defined wantarray) {
        require File::KDBX::Transaction;
        return File::KDBX::Transaction->new($self, @_);
    }

    my %args = @_;
    my $orig = $args{snapshot} // do {
        my $c = $self->clone(
            entries => $args{entries} // 0,
            groups  => $args{groups}  // 0,
            history => $args{history} // 0,
        );
        $c->{entries} = $self->{entries} if !$args{entries};
        $c->{groups}  = $self->{groups}  if !$args{groups};
        $c->{history} = $self->{history} if !$args{history};
        $c;
    };

    my $id = Hash::Util::FieldHash::id($orig);
    _save_references($id, $self, $orig);

    $self->_signal_begin_work;

    push @{$self->_txns}, $orig;
}


sub commit {
    my $self = shift;
    my $orig = pop @{$self->_txns} or return $self;
    $self->_commit($orig);
    my $signals = $self->_signal_commit;
    $self->_signal_send($signals) if !$self->_in_txn;
    return $self;
}


sub rollback {
    my $self = shift;

    my $orig = pop @{$self->_txns} or return $self;

    my $id = Hash::Util::FieldHash::id($orig);
    _restore_references($id, $orig);

    $self->_signal_rollback;

    return $self;
}

# Get whether or not there is at least one pending transaction.
sub _in_txn { scalar @{$_[0]->_txns} }

# Get an array ref of pending transactions.
sub _txns   { $TXNS{$_[0]} //= [] }

# The _commit hook notifies subclasses that a commit has occurred.
sub _commit { die 'Not implemented' }

# Get a reference to an object that represents an object's committed state. If there is no pending
# transaction, this is just $self. If there is a transaction, this is the snapshot take before the transaction
# began. This method is private because it provides direct access to the actual snapshot. It is important that
# the snapshot not be changed or a rollback would roll back to an altered state.
# This is used by File::KDBX::Dumper::XML so as to not dump uncommitted changes.
sub _committed {
    my $self = shift;
    my ($orig) = @{$self->_txns};
    return $orig // $self;
}

# In addition to cloning an object when beginning work, we also keep track its hashrefs and arrayrefs
# internally so that we can restore to the very same structures in the case of a rollback.
sub _save_references {
    my $id   = shift;
    my $self = shift;
    my $orig = shift;

    if (is_plain_arrayref($orig)) {
        for (my $i = 0; $i < @$orig; ++$i) {
            _save_references($id, $self->[$i], $orig->[$i]);
        }
        $REFS{$id}{Hash::Util::FieldHash::id($orig)} = $self;
    }
    elsif (is_plain_hashref($orig) || (blessed $orig && $orig->isa(__PACKAGE__))) {
        for my $key (keys %$orig) {
            _save_references($id, $self->{$key}, $orig->{$key});
        }
        $REFS{$id}{Hash::Util::FieldHash::id($orig)} = $self;
    }
}

# During a rollback, copy data from the snapshot back into the original internal structures.
sub _restore_references {
    my $id   = shift;
    my $orig = shift // return;
    my $self = delete $REFS{$id}{Hash::Util::FieldHash::id($orig) // ''} // return $orig;

    if (is_plain_arrayref($orig)) {
        @$self = map { _restore_references($id, $_) } @$orig;
    }
    elsif (is_plain_hashref($orig) || (blessed $orig && $orig->isa(__PACKAGE__))) {
        for my $key (keys %$orig) {
            # next if is_ref($orig->{$key}) &&
            #     (Hash::Util::FieldHash::id($self->{$key}) // 0) == Hash::Util::FieldHash::id($orig->{$key});
            $self->{$key} = _restore_references($id, $orig->{$key});
        }
    }

    return $self;
}

##############################################################################

sub _signal {
    my $self = shift;
    my $type = shift;

    if ($self->_in_txn) {
        my $stack = $self->_signal_stack;
        my $queue = $stack->[-1];
        push @$queue, [$type, @_];
    }

    $self->_signal_send([[$type, @_]]);

    return $self;
}

sub _signal_stack { $SIGNALS{$_[0]} //= [] }

sub _signal_begin_work {
    my $self = shift;
    push @{$self->_signal_stack}, [];
}

sub _signal_commit {
    my $self = shift;
    my $signals = pop @{$self->_signal_stack};
    my $previous = $self->_signal_stack->[-1] // [];
    push @$previous, @$signals;
    return $previous;
}

sub _signal_rollback {
    my $self = shift;
    pop @{$self->_signal_stack};
}

sub _signal_send {
    my $self    = shift;
    my $signals = shift // [];

    my $kdbx = $KDBX{$self} or return;

    # de-duplicate, keeping the most recent signal for each type
    my %seen;
    my @signals = grep { !$seen{$_->[0]}++ } reverse @$signals;

    for my $sig (reverse @signals) {
        $kdbx->_handle_signal($self, @$sig);
    }
}

##############################################################################

sub _wrap_group {
    my $self  = shift;
    my $group = shift;
    require File::KDBX::Group;
    return File::KDBX::Group->wrap($group, $KDBX{$self});
}

sub _wrap_entry {
    my $self  = shift;
    my $entry = shift;
    require File::KDBX::Entry;
    return File::KDBX::Entry->wrap($entry, $KDBX{$self});
}

sub TO_JSON { +{%{$_[0]}} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Object - A KDBX database object

=head1 VERSION

version 0.902

=head1 DESCRIPTION

KDBX is an object database. This abstract class represents an object. You should not use this class directly
but instead use its subclasses:

=over 4

=item *

L<File::KDBX::Entry>

=item *

L<File::KDBX::Group>

=back

There is some functionality shared by both types of objects, and that's what this class provides.

Each object can be connected with a L<File::KDBX> database or be disconnected. A disconnected object exists in
memory but will not be persisted when dumping a database. It is also possible for an object to be connected
with a database but not be part of the object tree (i.e. is not the root group or any subroup or entry).
A disconnected object or an object not part of the object tree of a database can be added to a database using
one of:

=over 4

=item *

L<File::KDBX/add_entry>

=item *

L<File::KDBX/add_group>

=item *

L<File::KDBX::Group/add_entry>

=item *

L<File::KDBX::Group/add_group>

=item *

L<File::KDBX::Entry/add_historical_entry>

=back

It is possible to copy or move objects between databases, but B<DO NOT> include the same object in more
than one database at once or there could be some strange aliasing effects (i.e. changes in one database might
effect another in unexpected ways). This could lead to difficult-to-debug problems. It is similarly not safe
or valid to add the same object multiple times to the same database. For example:

    my $entry = File::KDBX::Entry->(title => 'Whatever');

    # DO NOT DO THIS:
    $kdbx->add_entry($entry);
    $another_kdbx->add_entry($entry);

    # DO NOT DO THIS:
    $kdbx->add_entry($entry);
    $kdbx->add_entry($entry); # again

Instead, do this:

    # Copy an entry to multiple databases:
    $kdbx->add_entry($entry);
    $another_kdbx->add_entry($entry->clone);

    # OR move an existing entry from one database to another:
    $another_kdbx->add_entry($entry->remove);

=head1 ATTRIBUTES

=head2 kdbx

    $kdbx = $object->kdbx;
    $object->kdbx($kdbx);

Get or set the L<File::KDBX> instance connected with this object. Throws if the object is disconnected. Other
object methods might only work if the object is connected to a database and so they might also throw if the
object is disconnected. If you're not sure if an object is connected, try L</is_connected>.

=head2 uuid

128-bit UUID identifying the object within the connected database.

=head2 icon_id

Integer representing a default icon. See L<File::KDBX::Constants/":icon"> for valid values.

=head2 custom_icon_uuid

128-bit UUID identifying a custom icon within the connected database.

=head2 tags

Text string with arbitrary tags which can be used to build a taxonomy.

=head2 previous_parent_group

128-bit UUID identifying a group within the connected database the previously contained the object.

=head2 last_modification_time

Date and time when the entry was last modified.

=head2 creation_time

Date and time when the entry was created.

=head2 last_access_time

Date and time when the entry was last accessed.

=head2 expiry_time

Date and time when the entry expired or will expire.

=head2 expires

Boolean value indicating whether or not an entry is expired.

=head2 usage_count

The number of times an entry has been used, which typically means how many times the B<Password> string has
been accessed.

=head2 location_changed

Date and time when the entry was last moved to a different parent group.

=head1 METHODS

=head2 new

    $object = File::KDBX::Object->new;
    $object = File::KDBX::Object->new(%attributes);
    $object = File::KDBX::Object->new(\%data);
    $object = File::KDBX::Object->new(\%data, $kdbx);

Construct a new KDBX object.

There is a subtlety to take note of. There is a significant difference between:

    File::KDBX::Entry->new(username => 'iambatman');

and:

    File::KDBX::Entry->new({username => 'iambatman'}); # WRONG

In the first, an empty object is first created and then initialized with whatever I<attributes> are given. In
the second, a hashref is blessed and essentially becomes the object. The significance is that the hashref
key-value pairs will remain as-is so the structure is expected to adhere to the shape of a raw B<Object>
(which varies based on the type of object), whereas with the first the attributes will set the structure in
the correct way (just like using the object accessors / getters / setters).

The second example isn't I<generally> wrong -- this type of construction is supported for a reason, to allow
for working with KDBX objects at a low level -- but it is wrong in this specific case only because
C<< {username => $str} >> isn't a valid raw KDBX entry object. The L</username> attribute is really a proxy
for the C<UserName> string, so the equivalent raw entry object should be
C<< {strings => {UserName => {value => $str}}} >>. These are roughly equivalent:

    File::KDBX::Entry->new(username => 'iambatman');
    File::KDBX::Entry->new({strings => {UserName => {value => 'iambatman'}}});

If this explanation went over your head, that's fine. Just stick with the attributes since they are typically
easier to use correctly and provide the most convenience. If in the future you think of some kind of KDBX
object manipulation you want to do that isn't supported by the accessors and methods, just know you I<can>
access an object's data directly.

=head2 init

    $object = $object->init(%attributes);

Called by the constructor to set attributes. You normally should not call this.

=head2 wrap

    $object = File::KDBX::Object->wrap($object);

Ensure that a KDBX object is blessed.

=head2 label

    $label = $object->label;
    $object->label($label);

Get or set the object's label, a text string that can act as a non-unique identifier. For an entry, the label
is its title string. For a group, the label is its name.

=head2 clone

    $object_copy = $object->clone(%options);
    $object_copy = File::KDBX::Object->new($object);

Make a clone of an object. By default the clone is indeed an exact copy that is connected to the same database
but not actually included in the object tree (i.e. it has no parent group). Some options are allowed to get
different effects:

=over 4

=item *

C<new_uuid> - If set, generate a new UUID for the copy (default: false)

=item *

C<parent> - If set, add the copy to the same parent group, if any (default: false)

=item *

C<relabel> - If set, append " - Copy" to the object's title or name (default: false)

=item *

C<entries> - If set, copy child entries, if any (default: true)

=item *

C<groups> - If set, copy child groups, if any (default: true)

=item *

C<history> - If set, copy entry history, if any (default: true)

=item *

C<reference_password> - Toggle whether or not cloned entry's Password string should be set as a field reference to the original entry's Password string (default: false)

=item *

C<reference_username> - Toggle whether or not cloned entry's UserName string should be set as a field reference to the original entry's UserName string (default: false)

=back

=head2 is_connected

    $bool = $object->is_connected;

Determine whether or not an object is connected to a database.

=head2 id

    $string_uuid = $object->id;
    $string_uuid = $object->id($delimiter);

Get the unique identifier for this object as a B<formatted> UUID string, typically for display purposes. You
could use this to compare with other identifiers formatted with the same delimiter, but it is more efficient
to use the raw UUID for that purpose (see L</uuid>).

A delimiter can optionally be provided to break up the UUID string visually. See
L<File::KDBX::Util/format_uuid>.

=head2 group

    $parent_group = $object->group;
    $object->group($parent_group);

Get or set the parent group to which an object belongs or C<undef> if it belongs to no group.

=head2 lineage

    \@lineage = $object->lineage;
    \@lineage = $object->lineage($base_group);

Get the direct line of ancestors from C<$base_group> (default: the root group) to an object. The lineage
includes the base group but I<not> the target object. Returns C<undef> if the target is not in the database
structure. Returns an empty arrayref is the object itself is a root group.

=head2 remove

    $object = $object->remove(%options);

Remove an object from its parent. If the object is a group, all contained objects stay with the object and so
are removed as well, just like cutting off a branch takes the leafs as well. Options:

=over 4

=item *

C<signal> Whether or not to signal the removal to the connected database (default: true)

=back

=head2 recycle

    $object = $object->recycle;

Remove an object from its parent and add it to the connected database's recycle bin group.

=head2 recycle_or_remove

    $object = $object->recycle_or_remove;

Recycle or remove an object, depending on the connected database's L<File::KDBX/recycle_bin_enabled>. If the
object is not connected to a database or is already in the recycle bin, remove it.

=head2 is_recycled

    $bool = $object->is_recycled;

Get whether or not an object is in a recycle bin.

=head2 tag_list

    @tags = $entry->tag_list;

Get a list of tags, split from L</tag> using delimiters C<,>, C<.>, C<:>, C<;> and whitespace.

=head2 custom_icon

    $image_data = $object->custom_icon;
    $image_data = $object->custom_icon($image_data, %attributes);

Get or set an icon image. Returns C<undef> if there is no custom icon set. Setting a custom icon will change
the L</custom_icon_uuid> attribute.

Custom icon attributes (supported in KDBX4.1 and greater):

=over 4

=item *

C<name> - Name of the icon (text)

=item *

C<last_modification_time> - Just what it says (datetime)

=back

=head2 custom_data

    \%all_data = $object->custom_data;
    $object->custom_data(\%all_data);

    \%data = $object->custom_data($key);
    $object->custom_data($key => \%data);
    $object->custom_data(%data);
    $object->custom_data(key => $value, %data);

Get and set custom data. Custom data is metadata associated with an object. It is a set of key-value pairs
used to store arbitrary data, usually used by software like plug-ins to keep track of state rather than by end
users.

Each data item can have a few attributes associated with it.

=over 4

=item *

C<key> - A unique text string identifier used to look up the data item (required)

=item *

C<value> - A text string value (required)

=item *

C<last_modification_time> (optional, KDBX4.1+)

=back

=head2 custom_data_value

    $value = $object->custom_data_value($key);

Exactly the same as L</custom_data> except returns just the custom data's value rather than a structure of
attributes. This is a shortcut for:

    my $data = $object->custom_data($key);
    my $value = defined $data ? $data->{value} : undef;

=head2 begin_work

    $txn = $object->begin_work(%options);
    $object->begin_work(%options);

Begin a new transaction. Returns a L<File::KDBX::Transaction> object that can be scoped to ensure a rollback
occurs if exceptions are thrown. Alternatively, if called in void context, there will be no
B<File::KDBX::Transaction> and it is instead your responsibility to call L</commit> or L</rollback> as
appropriate. It is undefined behavior to call these if a B<File::KDBX::Transaction> exists. Recursive
transactions are allowed.

Signals created during a transaction are delayed until all transactions are resolved. If the outermost
transaction is committed, then the signals are de-duplicated and delivered. Otherwise the signals are dropped.
This means that the KDBX database will not fix broken references or mark itself dirty until after the
transaction is committed.

How it works: With the beginning of a transaction, a snapshot of the object is created. In the event of
a rollback, the object's data is replaced with data from the snapshot.

By default, the snapshot is shallow (i.e. does not include subroups, entries or historical entries). This
means that only modifications to the object itself (its data, fields, strings, etc.) are atomic; modifications
to subroups etc., including adding or removing items, are auto-committed instantly and will persist regardless
of the result of the pending transaction. You can override this for groups, entries and history independently
using options:

=over 4

=item *

C<entries> - If set, snapshot entries within a group, deeply (default: false)

=item *

C<groups> - If set, snapshot subroups within a group, deeply (default: false)

=item *

C<history> - If set, snapshot historical entries within an entry (default: false)

=back

For example, if you begin a transaction on a group object using the C<entries> option, like this:

    $group->begin_work(entries => 1);

Then if you modify any of the group's entries OR add new entries OR delete entries, all of that will be undone
if the transaction is rolled back. With a default-configured transaction, however, changes to entries are kept
even if the transaction is rolled back.

=head2 commit

    $object->commit;

Commit a transaction, making updates to C<$object> permanent. Returns itself to allow method chaining.

=head2 rollback

    $object->rollback;

Roll back the most recent transaction, throwing away any updates to the L</object> made since the transaction
began. Returns itself to allow method chaining.

=for Pod::Coverage STORABLE_freeze STORABLE_thaw TO_JSON

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
