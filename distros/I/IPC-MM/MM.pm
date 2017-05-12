package IPC::MM;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT    = qw( );
@EXPORT_OK = qw(
	mm_create
	mm_permission
	mm_destroy
	mm_make_scalar
	mm_free_scalar
	mm_scalar_get
	mm_scalar_set
	mm_make_btree_table
	mm_clear_btree_table
	mm_free_btree_table
	mm_btree_table_get
	mm_btree_table_insert
	mm_btree_table_delete
	mm_btree_table_exists
	mm_btree_table_first_key
	mm_btree_table_next_key
	mm_make_hash
	mm_free_hash
	mm_hash_get
	mm_hash_insert
	mm_hash_delete
	mm_hash_clear
	mm_hash_exists
	mm_hash_first_key
	mm_hash_next_key
	mm_lock
	mm_unlock
	mm_maxsize
	mm_available
	mm_error
	mm_display_info
	MM_LOCK_RD
	MM_LOCK_RW
);
$VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined MM macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap IPC::MM $VERSION;

# Preloaded methods go here.

sub IPC::MM::Scalar::TIESCALAR
{
	my $class = shift;
	my ($val) = @_;
	return bless \$val, $class;
}

sub IPC::MM::Scalar::FETCH
{
	my $self = shift;
	return(IPC::MM::mm_scalar_get($$self));
}

sub IPC::MM::Scalar::STORE
{
	my $self = shift;
	my ($val) = @_;
	IPC::MM::mm_scalar_set($$self, $val) or croak("mm_scalar_set: " . &IPC::MM::mm_error);
	return $val;
}

sub IPC::MM::Scalar::DESTROY
{
}


sub IPC::MM::BTree::TIEHASH
{
	my $self = shift;
	my $btree = shift or croak("TIEHASH: no btree reference");
	my $hash = {
		BTREE => $btree
	};
	return bless $hash, $self;
}

sub IPC::MM::BTree::FETCH
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_btree_table_get($self->{BTREE}, $key));
}

sub IPC::MM::BTree::STORE
{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	IPC::MM::mm_btree_table_insert($self->{BTREE}, $key, $val) or croak("mm_btree_table_insert: " . &IPC::MM::mm_error);
}

sub IPC::MM::BTree::DELETE
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_btree_table_delete($self->{BTREE}, $key));
}

sub IPC::MM::BTree::CLEAR
{
	my $self = shift;
	IPC::MM::mm_clear_btree_table($self->{BTREE});
}

sub IPC::MM::BTree::EXISTS
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_btree_table_exists($self->{BTREE}, $key));
}

sub IPC::MM::BTree::FIRSTKEY
{
	my $self = shift;
	return(IPC::MM::mm_btree_table_first_key($self->{BTREE}));
}

sub IPC::MM::BTree::NEXTKEY
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_btree_table_next_key($self->{BTREE}, $key));
}

sub IPC::MM::BTree::DESTROY
{
}

# ---------------------

sub IPC::MM::Hash::TIEHASH
{
	my $self = shift;
	my $hash = shift or croak("TIEHASH: no hash reference");
	my $obj = {
		HASH => $hash
	};
	return bless $obj, $self;
}

sub IPC::MM::Hash::FETCH
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_hash_get_value($self->{HASH}, $key));
}

sub IPC::MM::Hash::STORE
{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	IPC::MM::mm_hash_insert($self->{HASH}, $key, $val)
	    or croak("mm_hash_insert: " . &IPC::MM::mm_error);
}

sub IPC::MM::Hash::DELETE
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_hash_delete($self->{HASH}, $key));
}

sub IPC::MM::Hash::CLEAR
{
	my $self = shift;
	IPC::MM::mm_hash_clear($self->{HASH});
}

sub IPC::MM::Hash::EXISTS
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_hash_exists($self->{HASH}, $key));
}

sub IPC::MM::Hash::FIRSTKEY
{
	my $self = shift;
	return(IPC::MM::mm_hash_first_key($self->{HASH}));
}

sub IPC::MM::Hash::NEXTKEY
{
	my $self = shift;
	my $key = shift;
	return(IPC::MM::mm_hash_next_key($self->{HASH}, $key));
}

sub IPC::MM::Hash::DESTROY
{
}

# ---------------------



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

IPC::MM - Perl interface to Ralf Engelschall's mm library

=head1 SYNOPSIS

  use IPC::MM;

  $MMSIZE = 65536;
  $MMFILE = 'mm_file';

  $mm = mm_create($MMSIZE, $MM_FILE);

  $scalar = mm_make_scalar($mm);
  tie $tied_scalar, 'IPC::MM::Scalar', $scalar;
  $tied_scalar = 'hello';

  $btree = mm_make_btree_table($mm);
  tie %tied_hash, 'IPC::MM::BTree', $btree;
  $tied_hash{key} = 'val';

  $hash = mm_make_hash($mm);
  tie %tied_hash, 'IPC::MM::Hash', $hash;
  $tied_hash{key} = 'val';

  $num = mm_maxsize();

  $num = mm_available($mm);

  $errstr = mm_error();

  mm_display_info($mm);

  mm_destroy($mm);

=head1 DESCRIPTION

IPC::MM provides an interface to Ralf Engelschall's mm library, allowing
memory to be shared between multiple processes in a relatively convenient
way.

IPC::MM provides methods to create and destoy shared memory segments and to
access data structures within those shared memory segments, as well as
miscellaneous methods. Additionally, it provides a tied interface for
scalars and hashes.

=head1 METHODS

=over 4

=item $mm = mm_create($size, $file)

This method creates a shared memory segment. It corresponds to the function
in B<mm> of the same name.

I<$size> is the size of the shared memory segment, in bytes. A size of 0 means
to allocate the maximum allowed size which is platform dependent.

I<$file> is a filesystem path to a file which may be used as a lock file for
synchronizing access.

=item $rc = mm_permission($mm, $mode, $owner, $group)

This method sets the filesystem mode, owner, and group for the shared
memory segment mm. It will only do anything when the underlying shared
memory segment is based on files. It corresponds to the function in B<mm>
of the same name.

I<$mm> is the shared memory segment returned by I<mm_create>.

I<$mode>, I<$owner>, and I<$group> are passed directly to chown and chmod.

=item mm_destroy($mm)

This method destroys a shared memory segment created by I<mm_create>.

I<$mm> is the shared memory segment returned by I<mm_create>.

=item $scalar = mm_make_scalar($mm)

=item mm_free_scalar($scalar)

=item $val = mm_scalar_get($scalar)

=item $rc = mm_scalar_set($scalar, $val)

This family of methods provides a data structure for use by scalar variables.

I<mm_make_scalar> allocates the data structure used by the scalar.

I<mm_free_scalar> frees a data structure created by I<mm_make_scalar>.

I<mm_scalar_get> returns the contents of the scalar, I<$scalar>.

I<mm_scalar_set> sets the contents of the scalar, I<$scalar>, to I<$val>.

I<$val> is simply a Perl scalar value, meaning that it can be a string,
a number, a reference, et al.

It is possible for I<mm_scalar_set> to fail if there is not enough shared
memory.

It is possible to make the scalar a tied variable, like so:

  tie $tied_scalar, 'IPC::MM::Scalar', $scalar;

=item $btree = mm_make_btree_table($mm)

=item mm_clear_btree_table($btree)

=item mm_free_btree_table($btree)

=item $val = mm_btree_table_get($btree, $key)

=item $rc = mm_btree_table_insert($btree, $key, $val)

=item $oldval = mm_btree_table_delete($btree, $key)

=item $rc = mm_btree_table_exists($btree, $key)

=item $key = mm_btree_table_first_key($btree)

=item $key = mm_btree_table_next_key($btree, $key)

This family of methods provides a btree data structure for use by hashes.

I<mm_make_btree_table> allocates the data structure.

I<mm_clear_btree_table> clears the data structure, making it empty.

I<mm_free_btree_table> frees the data structure.

I<mm_btree_table_get> returns the value associated with I<$key>.

I<mm_btree_table_insert> inserts a new entry into the btree, with I<$key>
equal to I<$val>.

I<mm_btree_table_delete> deletes the entry in the btree identified by I<$key>.

I<mm_btree_table_exists> tests for the existence of an entry in the btree
identified by I<$key>.

I<mm_btree_table_first_key> returns the first key in the btree.

I<mm_btree_table_next_key> returns the next key after I<$key> in the btree.

It is possible to tie a btree to a hash, like so:

  tie %tied_hash, 'IPC::MM::BTree', $btree;

One interesting characteristic of the btree is that it is presorted, so
keys %tied_hash will return a sorted list of items.

=item $hash = mm_make_hash($mm)

=item mm_hash_clear($hash)

=item mm_free_hash($hash)

=item $val = mm_hash_get($hash, $key)

=item $rc = mm_hash_insert($hash, $key, $val)

=item $oldval = mm_hash_delete($hash, $key)

=item $rc = mm_hash_exists($hash, $key)

=item $key = mm_hash_first_key($hash)

=item $key = mm_hash_next_key($hash, $key)

This family of methods implements a shared memory hash list. These hash lists
are not presorted like btrees, but they can be faster than btrees (especially
unbalanced btrees).

I<mm_make_hash> allocates the data structure.

I<mm_clear_hash> clears the data structure, making it empty.

I<mm_free_hash> frees the data structure.

I<mm_hash_get> returns the value associated with I<$key>.

I<mm_hash_insert> inserts a new entry into the hash, with I<$key>
equal to I<$val>.

I<mm_hash_delete> deletes the entry in the hash identified by I<$key>.

I<mm_hash_exists> tests for the existence of an entry in the hash
identified by I<$key>.

I<mm_hash_first_key> returns the first key in the hash.

I<mm_hash_next_key> returns the next key after I<$key> in the hash.

It is possible to tie a shared-memory hash to a perl hash, like so:

  tie %tied_hash, 'IPC::MM::Hash', $hash;

=item $rc = mm_lock($mm, $mode)

This method locks the shared memory pool $mm for the current process in order
to perform either shared/read-only (mode MM_LOCK_RD) or exclusive/read-write
(mode MM_LOCK_RW) operations.

=item $rc = mm_unlock($mm)

This method unlocks the shared memory pool $mm.

=item $num = mm_maxsize

This method returns the maximum allowable size for a shared memory segment.
It corresponds to the function of the same name in the mm library.

=item $num = mm_available($mm)

This method returns the number of free bytes left in a shared memory segment.
It corresponds to the function of the same name in the mm library.

I<$mm> is a shared memory segment created by mm_create.

=item $errstr = mm_error

This method returns an error string, if any. It corresponds to the function
of the same name in B<mm>.

=item mm_display_info($mm)

This method displays some miscellaneous information about a shared memory
segment. It corresponds to the function of the same name in B<mm>.

=head1 BUGS

No effort is made to balance the btree.

=head1 AUTHOR

Copyright (c) 1999, Arthur Choung <arthur@etoys.com>.
All rights reserved.

This module is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<mm>, L<IPC::Shareable>, perl.

perl(1).

=cut
