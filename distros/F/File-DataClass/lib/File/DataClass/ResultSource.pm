package File::DataClass::ResultSource;

use namespace::autoclean;

use File::DataClass::Constants qw( FALSE NUL TRUE );
use File::DataClass::ResultSet;
use File::DataClass::Types     qw( ArrayRef ClassName HashRef
                                   Object SimpleStr Str );
use Moo;

# Private functions
my $_build_attributes = sub {
   my $self = shift; my $attr = {};

   $attr->{ $_ } = TRUE for (@{ $self->attributes });

   return $attr;
};

# Public attributes
has 'attributes'           => is => 'ro', isa => ArrayRef[Str],
   required                => TRUE;

has 'defaults'             => is => 'ro', isa => HashRef, builder => sub { {} };

has 'name'                 => is => 'ro', isa => SimpleStr, required => TRUE;

has 'label_attr'           => is => 'ro', isa => SimpleStr, default => NUL;

has 'resultset_attributes' => is => 'ro', isa => HashRef, builder => sub { {} };

has 'resultset_class'      => is => 'ro', isa => ClassName,
   default                 => 'File::DataClass::ResultSet';

has 'schema'               => is => 'ro', isa => Object,
   handles                 => [ 'path', 'storage' ],
   required                => TRUE, weak_ref => TRUE;

has 'types'                => is => 'ro', isa => HashRef, builder => sub { {} };

has '_attributes' => is => 'lazy', isa => HashRef,
   builder        => $_build_attributes, init_arg => undef;

# Public methods
sub columns {
   return @{ $_[ 0 ]->attributes };
}

sub has_column {
   my $key = $_[ 1 ] // '_invalid_key_';

   return exists $_[ 0 ]->_attributes->{ $key } ? TRUE : FALSE;
}

sub resultset {
   my $self = shift;

   my $attrs = { %{ $self->resultset_attributes }, result_source => $self };

   return $self->resultset_class->new( $attrs );
}

1;

__END__

=pod

=head1 Name

File::DataClass::ResultSource - A source of result sets for a given schema

=head1 Synopsis

   use File::DataClass::Schema;

   $schema = File::DataClass::Schema->new
      ( path    => [ qw(path to a file) ],
        result_source_attributes => { source_name => {}, },
        tempdir => [ qw(path to a directory) ] );

   $schema->source( q(source_name) )->attributes( [ qw(list of attr names) ] );
   $rs = $schema->resultset( q(source_name) );
   $result = $rs->find( { name => q(id of field element to find) } );
   $result->$attr_name( $some_new_value );
   $result->update;
   @result = $rs->search( { 'attr name' => q(some value) } );

=head1 Description

Provides new result sources for a given schema

Each element in a data file requires a schema definition to define it's
attributes

=head1 Configuration and Environment

Defines the following attributes

=over 3

=item B<attributes>

Array reference of attribute names defined in this result source

=item B<defaults>

A hash reference of attribute names. The values are the defaults for the
result class attributes

=item B<name>

The name of the result source. Required

=item B<label_attr>

An attribute name which, if set, is used by the list class to return a list
of labels suitable for display purposes

=item B<resultset_attributes>

A hash reference passed to the result constructor

=item B<resultset_class>

Classname of the result set

=item B<schema>

A required weak reference to the schema object that is instantiating this
result source

=item B<types>

A hash reference, keyed by attribute name. The types of the attributes in
the result class

=back

=head1 Subroutines/Methods

=head2 columns

   @attributes = $self->columns;

Returns a list of attributes

=head2 has_column

   $bool = $self->has_column( $attribute_name );

Predicate return true if the attribute exists, false otherwise

=head2 resultset

   $rs = $self->resultset;

Creates and returns a new L<File::DataClass::ResultSet> object

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::ResultSet>

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
