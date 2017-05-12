package DustyDB::Record;
our $VERSION = '0.06';

use Moose::Role;

=head1 NAME

DustyDB::Record - role for DustyDB models

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package MyModel;
  use DustyDB::Object;

  has key name => (
      is  => 'rw',
      isa => 'Str',
  );
  has description => (
      is => 'rw',
      isa => 'Str',
  );

=head1 DESCRIPTION

Do not use this class directly. Use L<DustyDB::Object> instead. The attributes and methods shown here are available in any class that uses L<DustyDB::Object> because such classes do this role.

=head1 ATTRIBUTES

=head2 db

This is a required attribute that must be set to a L<DustyDB> object that will be used to save this. In general, you will never need to set this yourself. 

However, if you want to construct your record class directly, you can do something like this.

  my $db = DustyDB->new( path => 'foo.db' );
  my $object = MyModel->new( db => $db, name => 'foo', description => 'bar' );

=cut

has db => (
    is       => 'rw',
    isa      => 'DustyDB',
    required => 1,
);

=head1 METHODS

=head2 save

  my $key = $self->save;

This method saves the object into the database and returns a key identifying the object. The key is a hash reference created using the attributes that have the L<DustyDB::Key> trait set.

=cut

sub save {
    my $self = shift;
    return $self->meta->save_object(
        db     => $self->db, 
        record => $self,
        @_,
    );
}

=head2 delete

  $self->delete;

This method delets the object from the database. This does not invalidate the object in memory or alter it in any other way.

=cut

sub delete {
    my $self = shift;
    $self->meta->delete_object(
        db     => $self->db,
        record => $self, 
        @_
    );
}

=head1 CAVEATS

When creating your models you cannot have an attribute named C<db> or an attribute named C<class_name>. The C<db> name is used directly as an attribute by this role and C<class_name> may be used when storing the data in some cases.

=cut

1;