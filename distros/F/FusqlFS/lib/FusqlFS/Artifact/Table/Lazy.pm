use strict;
use 5.010;

package FusqlFS::Artifact::Table::Lazy;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Artifact::Table::Lazy - lazily created table artifact abstract class

=head1 SYNOPSIS

    package FusqlFS::Backend::PgSQL::Table::Indices;
    use parent 'FusqlFS::Artifact::Table::Lazy';

    sub new
    {
        my $class = shift;
        my $self = $class->SUPER::new(@_);

        $self->{template} = { '.order' => [] };

        # Initialize indices specific resources
        bless $self, $class;
    }

    sub get
    {
        my $self = shift;
        unless ($self->SUPER::get(@_))
        {
            # get and return object from database
        }
    }

    sub list
    {
        my $self = shift;
        my ($table) = @_;
        return [ @{$self->do($self->{list_expr}, [$table])}, @{$self->SUPER::list($table)} ];
    }

    sub store
    {
        my $self = shift;
        my ($table, $name, $data) = @_;

        # validate input $data and build query, e.g.
        # my $struct = $self->validate($data, { ... }) or return;

        $self->drop($table, $name) and $self->do($self->{store_expr}, [$table, $name, $struct]);
    }

    sub drop
    {
        my $self = shift;
        my ($table, $name) = @_;
        $self->SUPER::drop($table, $name) or $self->do($self->{drop_expr}, [$table, $name]);
    }

    sub rename
    {
        my $self = shift;
        my ($table, $name, $newname) = @_;
        $self->SUPER::rename($table, $name, $newname) or $self->do($self->{rename_expr}, [$table, $name, $newname]);
    }

=head1 DESCRIPTION

Some database artifacts can't be created without any initial data, like
indices, so it is impossible to implement L<FusqlFS::Artifact/create> to create
"empty" artifact.

This class implements "lazy" table artifacts creation. When new database object
is to be created, this class's C<create()> creates empty placeholder in special
inner cache by cloning C<template> instance property you should initialize in
C<new()> (default is empty hashref, so new object will be visible as empty
directory), so no actual database object is created at all. It should be
created in overriden C<store> method or this object will disappear after file
system is unmounted, as there's no corresponding database artifact behind it.

Overriden C<store> method should also either remove cache entry on successful
object creation by calling C<$self-E<gt>SUPER::drop> or update this cache entry
by calling C<$self-E<gt>SUPER::store> with already available data if these data
are not enough to create actual database artifact.

All the other methods of this class should be consulted by overriden methods to
make sure user will see underlying "creation" cache entry in case there's no
actual database object by given name.

The rule of thumb is to drop this cache's entry with C<drop> when database
artifact is created, so every time this cache is checked, no entry for already
created object should be found in it.

=head1 METHODS

=over

=item new

Constructor.

Output: $lazy_artifact_instance.

You should usually override this constructor, to set C<$self-E<gt>{template}>
to artifact placeholder template.

=cut

sub new
{
    my $class = shift;
    my $self = {};

    $self->{create_cache} = {};
    $self->{template} = {};

    bless $self, $class;
    $self->init(@_);
    return $self;
}

=item clone

Static method, clones given structure and returns this clone.

Input: $data.
Output: $cloned_data.

This method implements deep recursive cloning of input data. It is used to
clone C<template> property to keep it intact and avoid it's erroneous
modification.

=begin testing clone

is_deeply {_tpkg}::clone({ a => 1, b => 2, c => 3 }), { a => 1, b => 2, c => 3 };
is_deeply {_tpkg}::clone([ 3, 2, 1 ]), [ 3, 2, 1 ];
is_deeply {_tpkg}::clone(\'string'), \'string';
is_deeply {_tpkg}::clone({ a => [ 3, 2, 1 ], b => { c => 1, d => [ 6, \5, 4 ] }, c => \"string" }),
    { a => [ 3, 2, 1 ], b => { c => 1, d => [ 6, \5, 4 ] }, c => \"string" };

=end testing
=cut
sub clone
{
    my $ref = $_[0];
    my $result;
    given (ref $ref)
    {
        when ('HASH')   { $result = { map { $_ => clone($ref->{$_}) } keys %$ref } }
        when ('ARRAY')  { $result = [ map { clone($_) } @$ref ] }
        when ('SCALAR') { my $tmp = $$ref; $result = \$tmp; }
        default         { $result = $ref; }
    }
    return $result;
}

=item create

Create cache entry using C<template> instance property as a template for placeholder.

Input: $table, $name.
Output: $success.

This methods uses L</clone> method to clone C<$self-E<gt>{template}> and put
this fresh placeholder value into creation cache, returns true on success
or undef on failure.

=begin testing create after get list

isnt $_tobj->create('table', 'name'), undef;
isnt $_tobj->get('table', 'name'), $_tobj->{template};
is_deeply $_tobj->get('table', 'name'), $_tobj->{template};
is_deeply $_tobj->list('table'), [ 'name' ];

=end testing
=cut
sub create
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->{create_cache}->{$table} ||= {};
    $self->{create_cache}->{$table}->{$name} = clone($self->{template});
    return 1;
}

=item drop

Drops given item from creation cache by name.

Input: $table, $name.
Output: $success.

This method removes given object from inner creation cache and returns true
on success or undef on failure (in case given cache entry doesn't exist).

You should use this method in your own C<store> method in this class's subclass
to drop creation cache item if it was correctly created in database.

=begin testing drop after rename

isnt $_tobj->drop('table', 'newname'), undef;
is $_tobj->get('table', 'newname'), undef;
is_deeply $_tobj->list('table'), [];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    if (exists $self->{create_cache}->{$table}->{$name})
    {
        delete $self->{create_cache}->{$table}->{$name};
        return 1;
    }
    return;
}

=item rename

Renames given item in creation cache.

Input: $table, $name, $newname.
Output: $success.

This method drops old creation cache entry by given name and stores it under
new name. It returns true on success or undef on failure (in case given cache
entry doesn't exist).

=begin testing rename after create

is $_tobj->rename('table', 'aname', 'anewname'), undef;
is $_tobj->get('table', 'aname'), undef;
is $_tobj->get('table', 'anewname'), undef;

isnt $_tobj->rename('table', 'name', 'newname'), undef;
is $_tobj->get('table', 'name'), undef;
is_deeply $_tobj->get('table', 'newname'), $_tobj->{template};
is_deeply $_tobj->list('table'), [ 'newname' ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    if (exists $self->{create_cache}->{$table}->{$name})
    {
        $self->{create_cache}->{$table}->{$newname} = $self->{create_cache}->{$table}->{$name};
        delete $self->{create_cache}->{$table}->{$name};
        return 1;
    }
    return;
}

=item list

Returns arrayref with all objects contained in creation cache under given table
name.

Input: $table, $name.
Output: $arrayref.

This method accepts table name on input and returns keys from creation cache
stored under this name packed into single arrayref. Returns empty arrayref if
no objects in creation cache under given table name.

=begin testing list

is_deeply $_tobj->list('table'), [], 'list is sane';

=end testing
=cut
sub list
{
    my $self = shift;
    my ($table) = @_;
    return [ keys %{$self->{create_cache}->{$table}||{}} ];
}

=item get

Returns cache entry by given name or undef it cache is missed.

Input: $table, $name.
Output: $cache_entry.

This method checks creation cache and returns cache entry by given name.
If cache entry by the name is absent, it returns undef.

=begin testing get

is $_tobj->get('table', 'name'), undef, 'get is sane';
is $_tobj->get('table', 'name'), undef, 'get has no side effects';

=end testing
=cut
sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    return $self->{create_cache}->{$table}->{$name}||undef;
}

=item store

Updates creation cache under given name with new data.

Input: $table, $name, $data.
Output: $success.

This method stores new data in creation cache under given name and returns true
on success or undef on failure (which should never happen).

You should use this method in your own C<store> method in this class's subclass
to update creation cache item if there were not enough data to create the
object in database immediately.

=cut
sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    $self->{create_cache}->{$table} ||= {};
    $self->{create_cache}->{$table}->{$name} = $data;
}

1;

__END__

=back
