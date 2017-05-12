package FeyX::Active::Table;
use Moose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use FeyX::Active::SQL::Select;
use FeyX::Active::SQL::Update;
use FeyX::Active::SQL::Insert;
use FeyX::Active::SQL::Delete;

extends 'Fey::Table';

sub select {
    my $self   = shift;
    my $select = FeyX::Active::SQL::Select->new(
        dbh => $self->schema->dbi_manager->default_source->dbh
    );

    $select->from( $self );
    $select->select( @_ ? @_ : $self );
    $select;
}

sub delete {
    my $self   = shift;
    my $delete = FeyX::Active::SQL::Delete->new(
        dbh => $self->schema->dbi_manager->default_source->dbh
    );

    $delete->from( $self );
    $delete;
}

sub insert {
    my $self   = shift;
    my $insert = FeyX::Active::SQL::Insert->new(
        dbh => $self->schema->dbi_manager->default_source->dbh
    );

    $insert->into( $self );
    $insert->values( @_ ) if @_;
    $insert;
}

sub update {
    my $self   = shift;
    my $update = FeyX::Active::SQL::Update->new(
        dbh => $self->schema->dbi_manager->default_source->dbh
    );

    $update->update( $self );
    $update->set( @_ ) if @_;
    $update;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

FeyX::Active::Table - An active Fey Table

=head1 SYNOPSIS

  use FeyX::Active::Table;

  my $Person = FeyX::Active::Table->new(name => 'Person');
  $Person->add_column( Fey::Column->new( name => 'first_name', type => 'varchar' ) );
  $Person->add_column( Fey::Column->new( name => 'last_name',  type => 'varchar' ) );

  $schema->add_table( $Person );

  my @people = (
      { first_name  => 'Homer', last_name => 'Simpson' },
      { first_name  => 'Marge', last_name => 'Simpson' },
      { first_name  => 'Bart',  last_name => 'Simpson' },
  );

  foreach my $person (@people) {
      $Person->insert( %$person )->execute;
  }

  my ($first_name, $last_name) = $Person->select
                                        ->where( $Person->column('first_name'), '==', 'Homer' )
                                        ->execute
                                        ->fetchrow;

=head1 DESCRIPTION

This is a subclass of L<Fey::Table> that adds a couple methods for creating
L<FeyX::Active::SQL> objects.

=head1 METHODS

All these methods will pass the C<default_source> database handle from the
associated L<FeyX::Active::Schema> to the L<FeyX::Active::SQL> object it
creates.

=over 4

=item B<select ( ?@columns )>

This will create a L<FeyX::Active::SQL::Select> object which that will
execute against the table associated. You can either pass in a list of
L<Fey::Column> objects to be passed to the L<select> method, or pass in
nothing which will be interpreted as selecting all the columns.

=item B<delete>

This will create a L<FeyX::Active::SQL::Delete> object which that will
execute against the table associated.

=item B<insert ( ?@values )>

This will create a L<FeyX::Active::SQL::Insert> object which that will
execute against the table associated. You can optionally pass in the
set of values you wish to insert and they will be passed to the C<values>
method.

=item B<update ( ?@values )>

This will create a L<FeyX::Active::SQL::Update> object which that will
execute against the table associated. You can optionally pass in the
set of values you wish to update and they will be passed to the C<set>
method.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
