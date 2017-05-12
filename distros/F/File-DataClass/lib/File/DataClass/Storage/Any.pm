package File::DataClass::Storage::Any;

use namespace::autoclean;

use File::Basename             qw( basename );
use File::DataClass::Constants qw( FALSE TRUE );
use File::DataClass::Functions qw( ensure_class_loaded first_char
                                   qualify_storage_class map_extension2class
                                   is_stale merge_file_data throw );
use File::DataClass::Storage;
use File::DataClass::Types     qw( Object HashRef );
use Moo;

has 'schema'  => is => 'ro', isa => Object,
   handles    => [ 'cache', 'storage_attributes', ],
   required   => TRUE, weak_ref => TRUE;


has '_stores' => is => 'ro', isa => HashRef, default => sub { {} };

# Private methods
my $_get_store_from_extension = sub {
   my ($self, $extn) = @_; my $stores = $self->_stores;

   exists $stores->{ $extn } and return $stores->{ $extn };

   my $list; ($list = map_extension2class( $extn ) and my $class = $list->[ 0 ])
      or throw 'Extension [_1] has no class', [ $extn ];

   if (first_char $class eq '+') { $class = substr $class, 1 }
   else { $class = qualify_storage_class $class }

   ensure_class_loaded $class;

   return $stores->{ $extn } = $class->new
      ( { %{ $self->storage_attributes }, schema => $self->schema } );
};

my $_get_store_from_path = sub {
   my ($self, $path) = @_; my $file = basename( "${path}" );

   my $extn = (split m{ \. }mx, $file)[ -1 ]
      or throw 'File [_1] has no extension', [ $file ];

   my $store = $self->$_get_store_from_extension( ".${extn}" )
      or throw 'Extension [_1] has no store', [ $extn ];

   return $store;
};

# Public methods
sub create_or_update {
   return shift->$_get_store_from_path( $_[ 0 ] )->create_or_update( @_ );
}

sub delete {
   return shift->$_get_store_from_path( $_[ 0 ] )->delete( @_ );
}

sub dump {
   return shift->$_get_store_from_path( $_[ 0 ] )->dump( @_ );
}

sub extn {
}

sub insert {
   return shift->$_get_store_from_path( $_[ 0 ] )->insert( @_ );
}

sub load {
   my ($self, @paths) = @_; $paths[ 0 ] or return {};

   scalar @paths == 1 and return ($self->read_file( $paths[ 0 ], FALSE ))[ 0 ];

   my ($loaded, $meta, $newest) = $self->cache->get_by_paths( \@paths );
   my $cache_mtime = $self->meta_unpack( $meta );

   not is_stale $loaded, $cache_mtime, $newest and return $loaded;

   $loaded = {}; $newest = 0;

   for my $path (@paths) { # Different storage classes by filename extension
      my ($red, $path_mtime) = $self->read_file( $path, FALSE );

      $path_mtime > $newest and $newest = $path_mtime;
      merge_file_data $loaded, $red;
   }

   $self->cache->set_by_paths( \@paths, $loaded, $self->meta_pack( $newest ) );
   return $loaded;
}

sub meta_pack {
   my ($self, $mtime) = @_; my $attr = $self->{_meta_cache} || {};

   defined $mtime and $attr->{mtime} = $mtime; return $attr;
}

sub meta_unpack {
   my ($self, $attr) = @_; $self->{_meta_cache} = $attr;

   return $attr ? $attr->{mtime} : undef;
};

sub read_file {
   return shift->$_get_store_from_path( $_[ 0 ] )->read_file( @_ );
}

sub select {
   return shift->$_get_store_from_path( $_[ 0 ] )->select( @_ );
}

sub txn_do {
   return shift->$_get_store_from_path( $_[ 0 ] )->txn_do( @_ );
}

sub update {
   return shift->$_get_store_from_path( $_[ 0 ] )->update( @_ );
}

sub validate_params {
   return shift->$_get_store_from_path( $_[ 0 ] )->validate_params( @_ );
}

1;

__END__

=pod

=head1 Name

File::DataClass::Storage::Any - Selects storage class using the extension on the path

=head1 Synopsis

   use File::DataClass::Schema;

   my $schema = File::DataClass::Schema->new( storage_class => q(Any) );

   my $loaded = $schema->load( 'data_file1.xml', 'data_file2.json' );

=head1 Description

Selects storage class using the extension on the path

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<schema>

A weakened reference to the schema object

=back

=head1 Subroutines/Methods

=head2 create_or_update

=head2 delete

=head2 dump

=head2 extn

=head2 insert

=head2 load

=head2 meta_pack

=head2 meta_unpack

=head2 read_file

=head2 select

=head2 txn_do

=head2 update

=head2 validate_params

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::Storage>

=item L<Moo>

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
