package File::DataClass::Cache;

use 5.01;
use namespace::autoclean;

use File::DataClass::Constants qw( FALSE NUL SPC TRUE );
use File::DataClass::Functions qw( merge_attributes throw );
use File::DataClass::Types     qw( Bool Cache ClassName HashRef
                                   LoadableClass Object Str );
use Storable                   qw( freeze );
use Try::Tiny;
use Moo;

# Public attributes
has 'cache'            => is => 'lazy', isa => Object, builder => sub {
   $_[ 0 ]->cache_class->new( %{ $_[ 0 ]->cache_attributes } ) };

has 'cache_attributes' => is => 'ro',   isa => HashRef, required => TRUE;

has 'cache_class'      => is => 'lazy', isa => LoadableClass,
   default             => 'Cache::FastMmap';

has 'log'              => is => 'ro',   isa => Object, required => TRUE;

# Private attributes
has '_mtimes_key'      => is => 'ro',   isa => Str, default => '_mtimes';

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $class, @args) = @_; my $attr = $orig->( $class, @args );

   $attr->{cache_attributes} //= {}; my $cache_class;

   $cache_class = delete $attr->{cache_attributes}->{cache_class}
      and $attr->{cache_class} = $cache_class;

   my $builder = delete $attr->{builder} or return $attr;

   merge_attributes $attr, $builder, [ 'log' ];

   return $attr;
};

# Private methods
my $_get_key_and_newest = sub {
   my ($self, $paths) = @_; my $newest = 0; my $is_valid = TRUE; my $key;

   for my $path (grep { defined && length "${_}" } @{ $paths }) {
      my $mtime = $self->get_mtime( "${path}" ) or $is_valid = FALSE;

      ($mtime and $path->exists and $mtime == $path->stat->{mtime})
         or $is_valid = FALSE;
      $mtime and $mtime > $newest and $newest = $mtime;
      $key .= $key ? "~${path}" : "${path}";
   }

   return ($key, $is_valid ? $newest : undef);
};

# Public methods
sub get {
   my ($self, $key) = @_; $key .= NUL;

   my $cached = $key ? $self->cache->get( $key ) : FALSE;

   $cached and return ($cached->{data}, $cached->{meta});

   return (undef, { mtime => undef });
}

sub get_by_paths {
   my ($self, $paths) = @_;
   my ($key, $newest) = $self->$_get_key_and_newest( $paths );

   return ($self->get( $key ), $newest);
}

sub get_mtime {
   my ($self, $k) = @_; $k or return;

   my $mtimes = $self->cache->get( $self->_mtimes_key ) or return;

   return $mtimes->{ $k };
}

sub remove {
   my ($self, $key) = @_; defined $key or return;

   $self->cache->remove( $key ); $self->set_mtime( $key, undef );

   return;
}

sub set {
   my ($self, $key, $data, $meta) = @_; $meta //= { mtime => undef };

   my $val = { data => $data, meta => $meta };

   try {
      $key eq $self->_mtimes_key and throw 'key not allowed';
      $self->cache->set( $key, $val ) or throw 'set operation returned false';
      $self->set_mtime( $key, $meta->{mtime} );
   }
   catch {
      my $len = length( $key ) + length( freeze $val );

      $self->log->error( "Cache key ${key}(${len}) set failed: ${_}" );
   };

   return ($data, $meta);
}

sub set_by_paths {
   my ($self, $paths, $data, $meta) = @_;

   my ($key, $newest) = $self->$_get_key_and_newest( $paths );

   $meta->{mtime} = $newest;

   return $self->set( $key, $data, $meta );
}

sub set_mtime {
   my ($self, $k, $v) = @_;

   return $self->cache->get_and_set( $self->_mtimes_key, sub {
      my (undef, $mtimes) = @_;

      if (defined $v) { $mtimes->{ $k } = $v } else { delete $mtimes->{ $k } }

      return $mtimes;
   } );
}

1;

__END__

=pod

=head1 Name

File::DataClass::Cache - Accessors and mutators for the cache object

=head1 Synopsis

   package File::DataClass::Schema;

   use Moo;
   use File::DataClass::Types qw(Cache);
   use File::DataClass::Cache;

   has 'cache'            => is => 'lazy', isa => Cache;

   has 'cache_attributes' => is => 'ro', isa => 'HashRef',
      default             => sub { return {} };

   my $_cache_objects = {};

   sub _build_cache {
      my $self  = shift; (my $ns = lc __PACKAGE__) =~ s{ :: }{-}gmx; my $cache;

      my $attrs = { cache_attributes => { %{ $self->cache_attributes } },
                    builder          => $self };

      $ns    = $attrs->{cache_attributes}->{namespace} ||= $ns;
      exists $_cache_objects->{ $ns } and return $_cache_objects->{ $ns };
      $self->cache_class eq 'none' and return Class::Null->new;
      $attrs->{cache_attributes}->{share_file}
           ||= NUL.$self->tempdir->catfile( "${ns}.dat" );

      return $_cache_objects->{ $ns } = $self->cache_class->new( $attrs );
   }

=head1 Description

Adds meta data and compound keys to the L<CHI> caching API. In instance of
this class is created by L<File::DataClass::Schema>

=head1 Configuration and Environment

The class defines these attributes

=over 3

=item C<cache>

An instance of the L<CHI> cache object

=item C<cache_attributes>

A hash ref passed to the L<CHI> constructor

=item C<cache_class>

The class name of the cache object, defaults to L<CHI>

=item C<log>

Log object which defaults to L<Class::Null>

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Constructs the attribute hash passed to the constructor method.

=head2 get

   ($data, $meta) = $schema->cache->get( $key );

Returns the data and metadata associated with the given key. If no cache
entry exists the data returned is C<undef> and the metadata is a hash ref
with a key of C<mtime> and a value of C<0>

=head2 get_by_paths

   ($data, $meta, $newest) = $schema->cache->get_by_paths( $paths );

The paths passed in the array ref are concatenated to form a compound key.
The L<CHI> cache entry is fetched and the data and meta data returned along
with the modification time of the newest file in the list of paths

=head2 get_mtime

   $mod_time = $schema->cache->get_mtime( $key );

Returns the mod time of a file if it's in the cache. Returns undef if it is not.
Returns zero if the filesystem was checked and the file did not exist

=head2 remove

   $schema->cache->remove( $key );

Removes the L<CHI> cache entry for the given key

=head2 set

   ($data, $meta) = $schema->cache->set( $key, $data, $meta );

Sets the L<CHI> cache entry for the given key

=head2 set_by_paths

   ($data, $meta) = $schema->cache->set_by_paths( $paths, $data, $meta );

Set the L<CHI> cache entry for the compound key formed from the array ref
C<$paths>

=head2 set_mtime

   $schema->cache->set_mtime( $key, $value );

Sets the mod time in the cache for the given key. Setting the mod time to
zero means the filesystem was checked and the file did not exist

=head2 _get_key_and_newest

   ($key, $newest) = $schema->cache->_get_key_and_newest( $paths );

Creates a key from the array ref of path names and also returns the most
recent mod time. Will return undef for newest if the cache entry is invalid

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<CHI>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
