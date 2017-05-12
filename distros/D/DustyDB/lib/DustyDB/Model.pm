package DustyDB::Model;
our $VERSION = '0.06';

use Moose;

=head1 NAME

DustyDB::Model - model classes represent the tables in your database

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use DustyDB;
  my $db = DustyDB->new( path => 'foo.db' );
  my $author = $db->model( 'Author' );

  # Create a record
  my $schwartz = $author->create( name => 'Randall Schwartz' );

  # New record that hasn't been saved yet
  my $chromatic = $author->construct( name => 'chromatic' );

  # Load a record from the disk
  my $the_damian = $author->load( 'Damian Conway' );

  # Load all/many of the records
  my @authors = $author->all;
  my @d_authors = $author->all_where( name => qr/^d/i );

  # Or as an iterator
  my $authors = $autor->all;
  while (my $author = $authors->next) {
      print " - ", $author->name, "\n";
  }

  # Delete the record
  $schwartz->delete;

=head1 DESCRIPTION

This class is the bridge between the storage database and the records in it. Normally, you won't need to create this object yourself, but use the C<model> method of L<DustyDB> to create it for you.

=head1 ATTRIBUTES

=head2 db

This is the L<DustyDB> that owns this model instance.

=cut

has db => (
    is       => 'rw',
    isa      => 'DustyDB',
    required => 1,
);

=head2 record_meta

This is the meta-class for something that does L<DustyDB::Record>.

=cut

has record_meta => (
    is       => 'rw',
    does     => 'DustyDB::Meta::Class',
    required => 1,
);

=head1 METHODS

=head2 construct

  my $record = $model->construct( %params );

This constructs an object, but does not save it.

=cut

sub construct {
    my ($self, %params) = @_;

    # Create the record
    my $record = $self->record_meta->new_object(
        db => $self->db,
        %params,
    );

    return $record;
}

=head2 create

  my $record = $model->create( %params );

This is essentially just sugar for:

  my $record = $model->construct( %params );
  $record->save;

This constructs the record and saves it to the database.

=cut

sub create {
    my ($self, %params) = @_;

    # Create the record and save
    my $record = $self->record_meta->new_object(
        db => $self->db,
        %params,
    );
    $record->save;

    return $record;
}

=head2 load

  my $record = $model->load( $value );
  my $record = $model->load( %key );

Given the names and values of key parameters, this will load an object from the database.

If there is only a single key attribute, you may pass just a value to this method.

=cut

sub load {
    my $self = shift;

    # Load the record
    my $record = $self->record_meta->load_object(
        db  => $self->db,
        key => [ @_ ],
    );

    return $record;
}

=head2 load_or_create

  my $record = $model->load_or_create( %params );

Given the record attributes, it uses the key parameters given to load an object if such an object exists. If not, the object will be created using the parameters given.

=cut

sub load_or_create {
    my ($self, %params) = @_;

    # Load the record, if possible
    my $record = $self->load( %params );
    return $record if $record;

    # Not found? Create it
    return $self->create( %params );
}

=head2 save

  my $record = $model->save( %params );

  # Or the more verbose synonym
  my $record = $model->load_and_update_or_create( %params );

Given the record attributes, it uses the key parameters given to load an object, if such an object can be found. If found, it will overwrite all the non-key parameters with the values given (and clear those that aren't given) and then save the object. If not found, it will create an object using the record attributes given.

=cut

sub save {
    my ($self, %params) = @_;

    # Try to load the record
    my $record = $self->load( %params );

    # Did we find one?
    if ($record) {

        # Update every attribute
        for my $attr (values %{ $self->record_meta->get_attribute_map }) {
            # TODO use a non-saved marker role instead of this crass hack
            next if $attr->name eq 'db';

            # If the parameter is defined, set it
            if (defined $params{ $attr->name }) {
                $attr->set_value($record, $params{ $attr->name });
            }

            # If the parameter is not defined, clear it
            else {
                $attr->clear_value($record);
            }
        }

        # Save it and then return
        $record->save;
        return $record;
    }

    # No such record found, we need to create it
    return $self->create( %params );
}

*load_and_update_or_create = *save;

=begin Pod::Coverage

  load_and_update_or_create

=end Pod::Coverage

=head2 all

=head2 all_where

The L</all> and L</all_where> are synonyms. In list context, they will return a list of zero or more records. In scalar context they will return a L<DustyDB::Collection> object. These methods will accept the same arguments as the L<DustyDB::Collection/filter> method of that class.

=cut

sub all {
    my $self = shift;

    my $collection = DustyDB::Collection->new( model => $self );
    $collection->filter(@_) if @_;

    return $collection->contextual;
}

*all_where = *all;

1;