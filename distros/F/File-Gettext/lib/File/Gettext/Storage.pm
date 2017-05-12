package File::Gettext::Storage;

use namespace::autoclean;

use File::Basename             qw( basename );
use File::DataClass::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use File::DataClass::Functions qw( is_stale merge_file_data throw );
use File::DataClass::Types     qw( Object );
use File::Gettext;
use Try::Tiny;
use Unexpected::Functions      qw( NothingUpdated Unspecified );
use Moo;

has 'gettext' => is => 'lazy', isa => Object,
   builder    => sub { File::Gettext->new( builder => $_[ 0 ]->schema ) };

has 'schema'  => is => 'ro',   isa => Object,  required => TRUE,
   handles    => [ qw( cache language ) ],     weak_ref => TRUE;

has 'storage' => is => 'ro',   isa => Object,  required => TRUE,
   handles    => [ qw( extn meta_pack meta_unpack
                       read_file txn_do validate_params ) ];

# Private functions
my $_get_attributes = sub {
   my ($condition, $source) = @_;

   return grep { not m{ \A _ }msx
                 and $_ ne 'id' and $_ ne 'name'
                 and $condition->( $_ ) } @{ $source->attributes || [] };
};

# Private methods
my $_extn = sub {
   my ($self, $path) = @_; $path //= NUL;

   my $extn = (split m{ \. }mx, ("${path}" // NUL))[ -1 ];

   return $extn ? ".${extn}" : $self->extn;
};

my $_gettext = sub {
   my ($self, $path) = @_; $path or throw Unspecified, [ 'path name' ];

   my $gettext = $self->gettext; my $extn = $self->$_extn( $path );

   $gettext->set_path( $self->language, basename( "${path}", $extn ) );

   return $gettext;
};

my $_create_or_update = sub {
   my ($self, $path, $result, $updating) = @_;

   my $source    = $result->can( 'result_source' )
                 ? $result->result_source : $result->_resultset->source;
   my $condition = sub { not $source->language_dependent->{ $_[ 0 ] } };
   my $updated   = $self->storage->create_or_update
      ( $path, $result, $updating, $condition );
   my $rs        = $self->$_gettext( $path )->resultset;
   my $element   = $source->name;

   $condition = sub { $source->language_dependent->{ $_[ 0 ] } };

   for my $attr_name ($_get_attributes->( $condition, $source )) {
      my $msgstr = $result->$attr_name() or next;
      my $attrs  = { msgctxt => "${element}.${attr_name}",
                     msgid   => $result->name,
                     msgstr  => [ $msgstr ], };

      $attrs->{name} = $rs->storage->make_key( $attrs ); my $name;

      try {
         $name = $updating ? $rs->create_or_update( $attrs )
                           : $rs->create( $attrs );
      }
      catch { $_->class ne NothingUpdated and throw $_ };

      $updated ||= $name ? TRUE : FALSE;
   }

   $updating and not $updated and throw NothingUpdated, level => 4;
   $updated  and $path->touch;
   return $updated;
};

my $_get_key_and_newest = sub {
   my ($self, $paths) = @_;

   my $gettext = $self->gettext; my $key; my $newest = 0; my $valid = TRUE;

   for my $path (grep { length } map { "${_}" } @{ $paths }) {
      $key .= $key ? "~${path}" : $path;

      my $mtime = $self->cache->get_mtime( $path );

      if ($mtime) { $mtime > $newest and $newest = $mtime }
      else { $valid = FALSE }

      my $file      = basename( "${path}", $self->$_extn( $path ) );
      my $lang_file = $gettext->object_file( $self->language, $file );

      if (defined ($mtime = $self->cache->get_mtime( "${lang_file}" ))) {
         if ($mtime) {
            $key .= $key ? "~${lang_file}" : "${lang_file}";
            $mtime > $newest and $newest = $mtime;
         }
      }
      else {
         if ($lang_file->exists and $lang_file->is_file) {
            $key .= $key ? "~${lang_file}" : "${lang_file}"; $valid = FALSE;
         }
         else { $self->cache->set_mtime( "${lang_file}", 0 ) }
      }
   }

   return ($key, $valid ? $newest : undef);
};

my $_load_gettext = sub {
   my ($self, $data, $path) = @_;

   my $gettext = $self->$_gettext( $path ); $gettext->path->is_file or return;

   my $gettext_data = $gettext->load->{ $gettext->source_name };

   for my $key (keys %{ $gettext_data }) {
      my ($msgctxt, $msgid)     = $gettext->storage->decompose_key( $key );
      my ($element, $attr_name) = split m{ [\.] }msx, $msgctxt, 2;

      ($element and $attr_name and $msgid) or next;

      $data->{ $element }->{ $msgid }->{ $attr_name }
         = $gettext_data->{ $key }->{msgstr}->[ 0 ];
   }

   return $gettext->path->stat->{mtime};
};

# Public methods
sub delete {
   my ($self, $path, $result) = @_;

   my $source    = $result->can( 'result_source' )
                 ? $result->result_source : $result->_resultset->source;
   my $condition = sub { $source->language_dependent->{ $_[ 0 ] } };
   my $deleted   = $self->storage->delete( $path, $result );
   my $rs        = $self->$_gettext( $path )->resultset;
   my $element   = $source->name;

   for my $attr_name ($_get_attributes->( $condition, $source )) {
      my $attrs  = { msgctxt => "${element}.${attr_name}",
                     msgid   => $result->name, };
      my $name   = $rs->storage->make_key( $attrs );

      $name      = $rs->delete( { name => $name, optional => TRUE } );
      $deleted ||= $name ? TRUE : FALSE;
   }

   return $deleted;
}

sub dump {
   my ($self, $path, $data) = @_; $self->validate_params( $path, TRUE );

   my $gettext      = $self->$_gettext( $path );
   my $gettext_data = $gettext->path->exists ? $gettext->load : {};

   for my $source (values %{ $self->schema->source_registrations }) {
      my $element = $source->name; my $element_ref = $data->{ $element };

      for my $msgid (keys %{ $element_ref }) {
         for my $attr_name (keys %{ $source->language_dependent || {} }) {
            my $msgstr = delete $element_ref->{ $msgid }->{ $attr_name }
                      or next;
            my $attrs  = { msgctxt => "${element}.${attr_name}",
                           msgid   => $msgid,
                           msgstr  => [ $msgstr ] };
            my $key    = $gettext->storage->make_key( $attrs );

            $gettext_data->{ $gettext->source_name }->{ $key } = $attrs;
         }
      }
   }

   $gettext->dump( { data => $gettext_data } );

   return $self->storage->dump( $path, $data );
}

sub insert {
   return $_[ 0 ]->$_create_or_update( $_[ 1 ], $_[ 2 ], FALSE );
}

sub load {
   my ($self, @paths) = @_; $paths[ 0 ] or return {};

   my ($key, $newest) = $self->$_get_key_and_newest( \@paths );
   my ($data, $meta)  = $self->cache->get( $key );
   my $cache_mtime    = $self->meta_unpack( $meta );

   not is_stale $data, $cache_mtime, $newest and return $data;

   $data = {}; $newest = 0;

   for my $path (@paths) {
      my ($red, $path_mtime) = $self->read_file( $path, FALSE );

      merge_file_data $data, $red;
      $path_mtime > $newest and $newest = $path_mtime;
      $path_mtime = $self->$_load_gettext( $data, $path );
      $path_mtime and $path_mtime > $newest and $newest = $path_mtime;
   }

   $self->cache->set( $key, $data, $self->meta_pack( $newest ) );

   return $data;
}

sub select {
   my ($self, $path, $element) = @_; $self->validate_params( $path, $element );

   my $data = $self->load( $path );

   return exists $data->{ $element } ? $data->{ $element } : {};
}

sub update {
   return $_[ 0 ]->$_create_or_update( $_[ 1 ], $_[ 2 ], TRUE );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::Storage - Split/merge language dependent data

=head1 Synopsis

=head1 Description

This is a proxy for the storage class. In general, for each call made to a
storage method this class makes two instead. The "second" call handles
attributes stored in the language dependent file

=head1 Configuration and Environment

Defines the attributes

=over 3

=item C<lang>

Two character language code

=item C<schema>

A weakened reference to the schema object

=item C<storage>

Instance of L<File::DataClass::Storage>

=back

=head1 Subroutines/Methods

=head2 delete

   $bool = $self->delete( $path, $result );

Deletes the specified element object returning true if successful. Throws
an error otherwise

=head2 dump

   $data = $self->dump( $path, $data );

Exposes L<File::DataClass::Storage/dump> in the storage class

=head2 insert

   $bool = $self->insert( $path, $result );

Inserts the specified element object returning true if successful. Throws
an error otherwise

=head2 load

   $data = $self->load( $path );

Exposes L<File::DataClass::Storage/load> in the storage class

=head2 select

   $hash_ref = $self->select( $element );

Returns a hash ref containing all the elements of the type specified in the
result source

=head2 update

   $bool = $self->update( $path, $result );

Updates the specified element object returning true if successful. Throws
an error otherwise

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::Gettext>

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

Copyright (c) 2016 Peter Flanigan. All rights reserved

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
