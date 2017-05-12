use strict;
use 5.010;

package FusqlFS::Entry;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Entry - abstract fusqlfs file system entry class

=head1 SYNOPSIS

    use FusqlFS::Entry;
    use FusqlFS::Backend;

    my $fs = FusqlFS::Backend->new(engine => 'PgSQL', user => 'postgres', database => 'dbname');
    my $entry = FusqlFS::Entry->new($fs, "/tables/sometable/struct/field");
    print $entry->get();
    print $entry->read(0, 10);
    $entry->write($newdata, 0);

=head1 DESCRIPTION

This class represents file system object in FusqlFS, i.e. all files,
directories, symlinks etc. are instances of this class.

This class defines thin convenience layer between database backend and fuse
subsystem, providing file path to database artifact resolution and interface
between fuse subsystem hooks and actual backend database operations,
translating database artifacts storing/dropping/renaming/etc. to correspondent
file system operations.

You should never work with this class directly, as it's abstracts from database
backend nicely, so you should implement database backends most of time, but
this document can be useful if you want to understand what happens behind the
scene when file names are converted to real database backend object instances.

Every entry instance keeps following data about file system entry:

=over

=item 1

Last L<FusqlFS::Artifact> instance found in entry lookup process (see L</new>
description for more info about entry lookup). This instance is called entry's
"package" or "pkg" for short.

=item 2

All path elements used to lookup next entries with L<FusqlFS::Artifact/get>
calls. Number of such elements is called entry's "depth".

=item 3

Cached data about entry contents.

=item 4

All path elements seen after last L<FusqlFS::Artifact> instance met in lookup
process. Number of such elements is called entry's "height".

=back

Beside these data each kind of entry can contain some additional kind-specific
data.

=head1 METHODS

=over

=item new

File system entry constructor.

Input: $fs, $path, $leaf_absent=undef.
Output: $entry_instance.

This constructor is the heart of full file path to actual database artifact
object translation. Understanding of this method is the key to understanding
the process of finding different database artifacts in file system tree and
defining kind of found file system entry (i.e. if it is a plain file,
subdirectory, symlink or a pseudopipe).

C<$fs> is the L<FusqlFS::Backend::Base> instance, which represents file system
"root". This is an entry point where the search begins. C<$path> is the full
path to subject file system object passed to every fuse hook subroutine as
first argument.

At first C<$path> is cleaned up from spare /-es and is splitted into path
elements. And then it is walked through from head to tail, resolving every path
element one by one. If any of elements in the path is absent (except for the
last one, which is a special case reviewed a little later), undef is returned,
which means file is absent and usually translated to -ENOENT error by hooks in
L<FusqlFS>.

The first path element is looked for in C<$fs-E<gt>{subpackages}>, and any
subsequent element is looked for in the last found entry.

Every entry is searched for subsequent path element according following simple
rules:

=over

=item *

If the entry is a hashref or an arrayref, it is a directory, and it must have
key (or index) equal to currently parsed path element. If it isn't, undef is
returned immediately, otherwise the next entry is found and equal to this
hashref's (or arrayref's) value by given key name (or index).

=item *

If the entry is an L<FusqlFS::Artifact> instance, L<FusqlFS::Artifact/get> is
called with all gathered path elements used in C<FusqlFS::Artifact> lookup up
to this point, and entry is equal to the returned result. If the result is
undefined, undef is returned immediately.

For every C<FusqlFS::Artifact> instance met, path element used to lookup next
entry is remembered in a special C<@names> array, so for example
F</tables/sometable> lookup will lead to
C<$fs-E<gt>{subpackages}-E<gt>{tables}-E<gt>get('sometable')> invocation, while
F</tables/sometable/indices/someindex> lookup will result in the following
chain of calls:

    $fs->{subpackages}->{tables}->get('sometable')->{indices}->get('sometable', 'someindex');

=item *

If at any iteration except for the last one entry is not a directory, undef is
returned, as you can't lookup next path element in anything except
subdirectory.

=item *

On the last iteration the resulting entry type is defined. If the last found
entry is a hashref or an arrayref, it will be L<FusqlFS::Entry::Dir> instance
and is represented with directory, if it is a scalarref it will be
L<FusqlFS::Entry::Symlink> instance and will be visible as symlink, if it is a
coderef it will be L<FusqlFS::Entry::Pipe> instance and will be represented
with pseudopipe, and if it is a simple scalar it will be
L<FusqlFS::Entry::File> instance and will be represented with plain file.

If the last found entry is an L<FusqlFS::Artifact> instance, its C<list()>
method will be called and if its result is not an undef, the entry will be
visible as directory, otherwise C<get()> method will be called and the
resulting value will be interpreted as described in previous paragraph (but it
won't be interpreted as directory anymore).

If this last entry is undef, undef will be returned unless C<$leaf_absent>
argument is given. If it is given and it is not undef, then this entry will be
assigned to its value and interpreted as described above. This way you can
create new files/directories/etc.

=back

=cut

our %SUBCLASSES = (
    ARRAY  => '::Dir',
    HASH   => '::Dir',
    SCALAR => '::Symlink',
    CODE   => '::Code',
    '', '::File',
);

sub new
{
    my ($class, $fs, $path, $leaf_absent) = @_;

    my $subclass = '';
    $path =~ s{^/}{};
    $path =~ s{/$}{};
    my @path = split /\//, $path;

    my $entry = $fs->{subpackages};
    my $pkg = $fs;
    my @names = ();
    my @tail = ();
    foreach my $p (@path)
    {
        return unless defined $entry;
        if (UNIVERSAL::isa($entry, 'FusqlFS::Artifact'))
        {
            @tail = ();
            $pkg = $entry;
            push @names, $p;
            $entry = $pkg->get(@names);
        }
        elsif (my $ref = ref $entry)
        {
            given ($ref)
            {
                when ('HASH')  { $entry = defined $entry->{$p}? $entry->{$p}: undef }
                when ('ARRAY') { $entry = defined $entry->[$p]? $entry->[$p]: undef }
                default        { undef $entry }
            }
            push @tail, $p;
        }
    }

    $entry = $leaf_absent unless defined $entry;
    return unless defined $entry;
    my $list;
    if (UNIVERSAL::isa($entry, 'FusqlFS::Artifact'))
    {
        $pkg = $entry;
        $list = $pkg->list(@names);
        if ($list) {
            $subclass = '::Dir';
        } else {
            $entry = $pkg->get(@names);
            $subclass = $SUBCLASSES{ref $entry};
        }
    } else {
        $subclass = $SUBCLASSES{ref $entry};
    }

    my $self = [ $pkg, \@names, $entry, $list, \@tail, undef ];

    bless $self, $class.$subclass;
    $self->init(@path);
    return $self;
}

=item init

I<Abstract method> called on entry initialization.

Input: @path.

This method is called every time after new entry instance is blessed into its
class, i.e. just after instance construction.

The C<@path> is the cleaned up and splitted into elements version of C<$path>
argument to L</new> constructor method. It can be used by this method anyway
it might be useful. The return value of this method is ignored.

=item get

Returns cached entry's content.

Output: $entry_content.

=item size

Returns size of entry's content.

Output: $entry_length.

=item list

Returns list of items contained in entry if the entry is a directory, undef
otherwise.

Output: $entry_items|undef.

=item move

Moves entry from one position in files tree to another.

Input: $target.

C<$target> is another target C<FusqlFS::Entry> instance. The original entry is
destroyed in process, and target entry becomes identical to original one.

This method is used in rename fuse hook. It is recommended to construct new
target entry with defined C<$leaf_absent> argument to L</new>, as this operation
on already existing entry backed up with real database object can be unpredictable
or even destructive.

=item drop

Removes entry from database.

=item create

Creates new file entry.

=item store

Stores new data into entry.

Input: $data.

=cut
sub init { }
sub get { $_[0]->[2] }
sub size { length $_[0]->[2] }
sub list { }
sub move
{
    my $self = shift;
    my $target = shift;

    unless ($self->depth())
    {
        $self->pkg()->rename($self->names(), $target->name());
    }
    else
    {
        my $entry = $target->tailref();
        $entry = $self->tailref($entry, undef);
        $self->pkg()->store($self->names(), $entry);
    }
}
sub drop { $_[0]->put(undef) or $_[0]->[0]->drop(@{$_[0]->[1]}); }
sub create { $_[0]->put('') or $_[0]->[0]->create(@{$_[0]->[1]}); }
sub store { my $data = $_[1]||$_[0]->[2]; $_[0]->put($data) or $_[0]->[0]->store(@{$_[0]->[1]}, $data); }

=item put

Modifies data, returned by L<FusqlFS::Artifact> instance in given tail point.

Input: $data.
Output: $success.

The problem this method is to solve is entry instance doesn't always correspond
to real C<FusqlFS::Artifact> instance directly, but to some substructure in
"subtree" exposed by this instance. But all modification operations are handled
by C<FusqlFS::Artifact>, so it is necessary to get whole structure from
entry's package, modify it in necessary place and store it back with
L<FusqlFS::Artifact/store> method call.

And that's what this method does.

It returns true if such complex modification/storage process is required and done,
undef otherwise.

=cut
sub put
{
    my $self = shift;
    my $data = shift;

    unless ($self->depth())
    {
        return;
    }
    else
    {
        my $entry = $self->tailref(undef, $data);
        $self->pkg()->store($self->names(), $entry);
    }
    return 1;
}

=item tailref

Backbone of different complex entry operations, such as L</put> and L</move>.

Input: $entry=undef, $data=undef.
Output: $entry.

This method gets full entry structure, returned by L<FusqlFS::Artifact/get>
call (defaults to current entry's structure returned with L</entry> method),
traverses it down to the last tail piece of data, correspondent to the entry
instance, modifies it with given data (or removes it altogether if the data
is undefined) and returns this modified entry structure back, ready to be
passed to L<FusqlFS::Artifact/store> method.

=cut
sub tailref
{
    my $self = shift;
    my @tail = $self->tail();
    my $tail = pop @tail;
    my $entry = shift || $self->entry();
    my $data = @_? shift: $self->get();
    my $tailref = $entry;
    $tailref = ref $tailref eq 'HASH'? $tailref->{$_}: $tailref->[$_] foreach (@tail);
    given (ref $tailref)
    {
        when ('HASH')  { if (defined $data) { $tailref->{$tail} = $data } else { delete $tailref->{$tail} } }
        when ('ARRAY') { if (defined $data) { $tailref->[$tail] = $data } else { delete $tailref->[$tail] } }
    }
    return $entry;
}

=item isdir, islink, isfile, ispipe

These are entry type identification methods and return true if the entry
implements correspondent behavior (i.e. if the entry is directory, symlink,
plain file or pseudopipe). Usually only one of these methods returns true,
and all the others return undef.

=cut
sub isdir { }
sub islink { }
sub isfile { }
sub ispipe { }

=item writable

Returns true if the entry is writable.

=cut
sub writable { !UNIVERSAL::isa($_[0]->[2], 'FusqlFS::Artifact') }

=item pkg, names, tail, name, depth

These are properties accessor methods (see L</DESCRIPTION> for full list of
data kept in entry instance, L</new> for description of file path resolution
process).

C<pkg> returns last L<FusqlFS::Artifact> instance met in file path traversion
(i.e. entry's "package"), C<names> returns list of all path elements used to
lookup next entry with L<FusqlFS::Artifact/get> call during file path
resolution, C<tail> returns list of all path elements met after the last
L<FusqlFS::Artifact> instance met, C<depth> and C<height> return number of
elements in lists, returned with C<names> and C<tail> methods correspondingly
(i.e. entry's "depth" and "height").

=cut
sub pkg { $_[0]->[0] }
sub names { @{$_[0]->[1]} }
sub tail { @{$_[0]->[4]} }
sub name { $_[0]->[4]->[-1] || $_[0]->[1]->[-1] }
sub depth { scalar @{$_[0]->[4]} }
sub height { scalar @{$_[0]->[1]} }

=item entry

Returns not cached entry contents, got with direct call to entry's package
C<get> call.

Please mention it can be quite different with what L</get> entry's method returns,
as C<get> returns only tail file object itself, while C<entry> method returns
full data structure got from original L<FusqlFS::Artifact> instance.

For example if you have role's struct entry instance for path
F</roles/somerole/struct> C<$entry-E<gt>get()> call will give you only
F<struct> file content, while C<$entry-E<gt>entry()> call will bring you full
raw role's structure, including all subroles symlinks, "struct" file itself
etc.

=cut
sub entry { $_[0]->[0]->get(@{$_[0]->[1]}) }

=item read, write

I<Abstract methods> implemented primarily for plain files to handle read and
write calls.

Read accepts offset and length arguments and returns data part stored in the
entry by given coordinates.

Write accepts offset and scalar data buffer and modifies and stores the entry
immediately.

All cached write operations must be (and they really are) handled by upper
fuse subsystem layer in L<FusqlFS>.

=cut
sub read { }
sub write { }

1;

package FusqlFS::Entry::File;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Entry';

sub isfile { 1 }

sub write { substr($_[0]->[2], $_[1], length($_[2]||$_[0]->[2])) = $_[2]||''; $_[0]->store($_[0]->[2]) }
sub read { substr($_[0]->[2], $_[1], $_[2]) }

1;

package FusqlFS::Entry::Pipe;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Entry';

sub init
{
    # 0=pkg, 1=names, 2=output buffer, 3=filter sub, 4=tail
    ($_[0]->[3], $_[0]->[2]) = ($_[0]->[2], $_[0]->[2]->());
}

sub ispipe { 1 }
sub isfile { 1 }

sub size { length $_[0]->[2] }
sub get { $_[0]->[3] }
sub read { substr($_[0]->[2], $_[1], $_[2]) }
sub write { $_[0]->[2] = $_[0]->[3]->($_[2]); }

1;

package FusqlFS::Entry::Dir;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Entry';

sub init
{
    # 0=pkg, 1=names, 2=dir entry, 3=list buffer, 4=tail
    return if defined $_[0]->[3];
    $_[0]->[3] = ref $_[0]->[2] eq 'HASH'? [ keys %{$_[0]->[2]} ]: [ 0..$#{$_[0]->[2]} ];
}

sub size { scalar @{$_[0]->[3]} }
sub isdir { 1 }
sub list { $_[0]->[3] }

1;

package FusqlFS::Entry::Symlink;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Entry';

sub init { $_[0]->[3] = ('../' x (scalar(@_)-2)).${$_[0]->[2]} }
sub read { $_[0]->[3] }
sub size { length $_[0]->[3] }
sub islink { 1 }

1;

