package File::DataClass::Storage;

use namespace::autoclean;

use Class::Null;
use English                    qw( -no_match_vars );
use File::Copy;
use File::DataClass::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use File::DataClass::Functions qw( is_stale merge_file_data
                                   merge_for_update throw );
use File::DataClass::Types     qw( Bool HashRef Object Str );
use Scalar::Util               qw( blessed );
use Try::Tiny;
use Unexpected::Functions      qw( RecordAlreadyExists PathNotFound
                                   NothingUpdated Unspecified );
use Moo;

has 'atomic_write'  => is => 'ro', isa => Bool, default => TRUE;

has 'backup'        => is => 'ro', isa => Str,  default => NUL;

has 'encoding'      => is => 'ro', isa => Str,  default => NUL;

has 'extn'          => is => 'ro', isa => Str,  default => NUL;

has 'read_options'  => is => 'ro', isa => HashRef, builder => sub { {} };

has 'schema'        => is => 'ro', isa => Object,
   handles          => { _cache => 'cache', _lock  => 'lock',
                         _log   => 'log',   _perms => 'perms', },
   required         => TRUE,  weak_ref => TRUE;

has 'write_options' => is => 'ro', isa => HashRef, builder => sub { {} };

has '_locks'        => is => 'ro', isa => HashRef, builder => sub { {} };

# Private functions
my $_get_src_attributes = sub {
   my ($cond, $src) = @_;

   return grep { not m{ \A _ }mx
                 and $_ ne 'id' and $_ ne 'name'
                 and $cond->( $_ ) } keys %{ $src };
};

my $_lock_set = sub {
   $_[ 0 ]->_lock->set( k => $_[ 1 ] ); $_[ 0 ]->_locks->{ $_[ 1 ] } = TRUE;
};

my $_lock_reset = sub {
   $_[ 0 ]->_lock->reset( k => $_[ 1 ] ); delete $_[ 0 ]->_locks->{ $_[ 1 ] };
};

my $_lock_reset_all = sub {
   my $self = shift;

   eval { $self->$_lock_reset( $_ ) } for (keys %{ $self->_locks });

   return;
};

# Public methods
sub create_or_update {
   my ($self, $path, $result, $updating, $cond) = @_;

   my $rsrc_name = $result->result_source->name;

   $self->validate_params( $path, $rsrc_name ); my $updated;

   my $data = ($self->read_file( $path, TRUE ))[ 0 ];

   try {
      my $filter = sub { $_get_src_attributes->( $cond, $_[ 0 ] ) };
      my $id     = $result->id; $data->{ $rsrc_name } //= {};

      not $updating and exists $data->{ $rsrc_name }->{ $id }
         and throw RecordAlreadyExists, [ $path, $id ], level => 2;

      $updated = merge_for_update
         ( \$data->{ $rsrc_name }->{ $id }, $result, $filter );
   }
   catch { $self->$_lock_reset( $path ); throw $_ };

   if ($updated) { $self->write_file( $path, $data, not $updating ) }
   else { $self->$_lock_reset( $path ) }

   return $updated ? $result : FALSE;
}

sub delete {
   my ($self, $path, $result) = @_;

   my $rsrc_name = $result->result_source->name;

   $self->validate_params( $path, $rsrc_name );

   my $data = ($self->read_file( $path, TRUE ))[ 0 ]; my $id = $result->id;

   if (exists $data->{ $rsrc_name } and exists $data->{ $rsrc_name }->{ $id }) {
      delete $data->{ $rsrc_name }->{ $id };
      scalar keys %{ $data->{ $rsrc_name } } or delete $data->{ $rsrc_name };
      $self->write_file( $path, $data );
      return TRUE;
   }

   $self->$_lock_reset( $path );
   return FALSE;
}

sub DEMOLISH {
   my ($self, $gd) = @_; $gd and return; $self->$_lock_reset_all(); return;
}

sub dump {
   my ($self, $path, $data) = @_;

   return $self->txn_do( $path, sub {
      $self->$_lock_set( $path ); $self->write_file( $path, $data, TRUE ) } );
}

sub insert {
   my ($self, $path, $result) = @_;

   return $self->create_or_update( $path, $result, FALSE, sub { TRUE } );
}

sub load {
   my ($self, @paths) = @_; $paths[ 0 ] or return {};

   scalar @paths == 1 and return ($self->read_file( $paths[ 0 ], FALSE ))[ 0 ];

   my ($loaded, $meta, $newest) = $self->_cache->get_by_paths( \@paths );
   my $cache_mtime = $self->meta_unpack( $meta );

   not is_stale $loaded, $cache_mtime, $newest and return $loaded;

   $loaded = {}; $newest = 0;

   for my $path (@paths) {
      my ($red, $path_mtime) = $self->read_file( $path, FALSE );

      $path_mtime > $newest and $newest = $path_mtime;
      merge_file_data $loaded, $red;
   }

   $self->_cache->set_by_paths( \@paths, $loaded, $self->meta_pack( $newest ) );
   return $loaded;
}

sub meta_pack { # Modified in a subclass
   my ($self, $mtime) = @_; return { mtime => $mtime };
}

sub meta_unpack { # Modified in a subclass
   my ($self, $attr) = @_; return $attr ? $attr->{mtime} : undef;
}

sub read_file {
   my ($self, $path, $for_update) = @_;

   $self->$_lock_set( $path ); my ($data, $path_mtime);

   try {
      my $stat = $path->stat; defined $stat and $path_mtime = $stat->{mtime};

      my $meta; ($data, $meta) = $self->_cache->get( $path );

      my $cache_mtime = $self->meta_unpack( $meta );

      if (is_stale $data, $cache_mtime, $path_mtime) {
         if ($for_update and not $path->exists) {
            $data = {}; # uncoverable statement
         }
         else {
            $data = $self->read_from_file( $path->lock ); $path->close;
            $meta = $self->meta_pack( $path_mtime );
            $self->_cache->set( $path, $data, $meta );
            $self->_log->debug( "Read file  ${path}" );
         }
      }
      else { $self->_log->debug( "Read cache ${path}" ) }
   }
   catch { $self->$_lock_reset( $path ); throw $_ };

   $for_update or $self->$_lock_reset( $path );

   return ($data, $path_mtime);
}

sub read_from_file {
   throw 'Method [_1] not overridden in subclass [_2]',
         [ 'read_from_file', blessed $_[ 0 ] ];
}

sub select {
   my ($self, $path, $rsrc_name) = @_;

   $self->validate_params( $path, $rsrc_name );

   my $data = ($self->read_file( $path, FALSE ))[ 0 ];

   return exists $data->{ $rsrc_name } ? $data->{ $rsrc_name } : {};
}

sub txn_do {
   my ($self, $path, $code_ref) = @_;

   my $wantarray = wantarray; $self->validate_params( $path, TRUE );

   my $key = "txn:${path}"; $self->$_lock_set( $key ); my $res;

   try {
      if ($wantarray) { $res = [ $code_ref->() ] }
      else { $res = $code_ref->() }
   }
   catch { $self->$_lock_reset( $key ); throw $_, { level => 4 } };

   $self->$_lock_reset( $key );

   return $wantarray ? @{ $res } : $res;
}

sub update {
   my ($self, $path, $result, $updating, $cond) = @_;

   $updating //= TRUE; $cond //= sub { TRUE };

   my $updated = $self->create_or_update( $path, $result, $updating, $cond )
      or throw NothingUpdated, level => 2;

   return $updated;
}

sub validate_params {
   my ($self, $path, $rsrc_name) = @_;

   $path         or throw Unspecified, [ 'path name' ], level => 2;
   blessed $path or throw 'Path [_1] is not blessed', [ $path ], level => 2;
   $rsrc_name    or throw 'Path [_1] result source not specified', [ $path ],
                          level => 2;

   return;
}

sub write_file {
   my ($self, $path, $data, $create) = @_; my $exists = $path->exists;

   try {
      $create or $exists or throw PathNotFound, [ $path ];
      $exists or $path->perms( $self->_perms );
      $self->atomic_write and $path->atomic;

      if ($exists and $self->backup and not $path->empty) {
         copy( "${path}", $path.$self->backup )
            or throw 'Backup copy failed: [_1]', [ $OS_ERROR ];
      }

      try   { $data = $self->write_to_file( $path->lock, $data ); $path->close }
      catch { $path->delete; throw $_ };

      $self->_cache->remove( $path );
      $self->_log->debug( "Write file ${path}" )
   }
   catch { $self->$_lock_reset( $path ); throw $_ };

   $self->$_lock_reset( $path );
   return $data;
}

sub write_to_file {
   throw 'Method [_1] not overridden in subclass [_2]',
         [ 'write_to_file', blessed $_[ 0 ] ];
}

# Backcompat
sub _read_file {
   throw 'Class [_1] should never call _read_file', [ blessed $_[ 0 ] ];
}

sub _write_file {
   throw 'Class [_1] should never call _write_file', [ blessed $_[ 0 ] ];
}

1;

__END__

=pod

=head1 Name

File::DataClass::Storage - Storage base class

=head1 Synopsis

=head1 Description

Storage base class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<atomic_write>

Hash reference containing the keys of any locks set by the storage object.
Used during object destruction to free any left over locks

=item C<backup>

Extension appended to the file name. Used to create a backup of the updated
file. Defaults to the null string so no backup created

=item C<encoding>

Used by subclasses to encode/decode the file data on ouput/input. Defaults
to the null string

=item C<extn>

The filename extension for this type of file. Usually overridden in the
subclass. Default to the null string

=item C<read_options>

This hash reference is used to customise the decoder object used when
reading the file. It defaults to an empty reference

=item C<schema>

A weakened schema object reference

=item C<write_options>

This hash reference is used to customise the encoder object used when
writing the file. It defaults to an empty reference

=back

=head1 Subroutines/Methods

=head2 create_or_update

   $bool = $self->create_or_update( $path, $result, $updating, $condition );

Does the heavy lifting for L</insert> and L</update>. The C<$updating> boolean
is true for updating false otherwise. The C<$condition> code reference is
used to filter updates

=head2 delete

   $bool = $storage->delete( $path, $result );

Deletes the specified result object returning true if successful. Throws
an error otherwise. Path is an instance of L<File::DataClass::IO>. The
result is an instance of L<File::DataClass::Result>

=head2 DEMOLISH

Called during object destruction it deletes any outstanding locks

=head2 dump

   $data = $storage->dump( $path, $data );

Dumps the data to the specified path. Path is an instance of
L<File::DataClass::IO>

=head2 insert

   $bool = $storage->insert( $path, $result );

Inserts the specified result object returning true if successful. Throws
an error otherwise. Path is an instance of L<File::DataClass::IO>. The
result is an instance of L<File::DataClass::Result>

=head2 load

   $hash_ref = $storage->load( @paths );

Loads each of the specified files merging the resultant hash ref which
it returns. Paths are instances of L<File::DataClass::IO>

=head2 meta_pack

Converts from scalar to hash reference. The scalar is the modification time
of the file

=head2 meta_unpack

Converts from hash reference to scalar. The scalar is the modification time
of the file

=head2 read_file

   ($data, $mtime) = $self->read_file( $path, $for_update ):

Read a file from cache or disk

=head2 read_from_file

   $data = $self->read_from_file( $io_object_ref );

Should be overridden in the subclass

=head2 select

   $hash_ref = $storage->select( $path );

Returns a hash reference containing all the records for the result source
specified in the schema. Path is an instance of L<File::DataClass::IO>

=head2 txn_do

Executes the supplied coderef wrapped in lock on the pathname

=head2 update

   $bool = $storage->update( $path, $result, $updating, $condition );

Updates the specified result object returning true if successful. Throws
an error otherwise. Path is an instance of L<File::DataClass::IO>. The
result is an instance of L<File::DataClass::Result>

=head2 validate_params

   $storage->validate_params( $path, $rsrc_name );

Throw if C<$path> or C<$rsrc_name> are not specified or C<$path> is not blessed

=head2 write_file

   $data = $self->write_file( $path, $data, $create );

Writes C<$data> to C<$path>. Will throw if C<$create> is not true and C<$path>
does not exist

=head2 write_to_file

   $data = $self->write_to_file( $io_object_ref, $data );

Should be overridden in the subclass

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
