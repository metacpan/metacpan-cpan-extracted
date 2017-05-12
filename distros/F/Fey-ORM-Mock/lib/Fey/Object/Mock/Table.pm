package Fey::Object::Mock::Table;
{
  $Fey::Object::Mock::Table::VERSION = '0.06';
}

use strict;
use warnings;

use Fey::Meta::Class::Schema;

use Moose;

extends 'Fey::Object::Table';

sub insert_many {
    my $class = shift;
    my @rows  = @_;

    $class->__record_insert($_) for @rows;

    return $class->SUPER::insert_many(@rows);
}

sub __record_insert {
    my $class = shift;
    my $vals  = shift;

    $class->__recorder->record_action(
        action => 'insert',
        class  => $class,
        values => $vals,
    );
}

sub update {
    my $self = shift;
    my %p    = @_;

    $self->__record_update( \%p );

    $self->SUPER::update(%p);
}

sub __record_update {
    my $self = shift;
    my $vals = shift;

    $self->__recorder->record_action(
        action => 'update',
        class  => ( ref $self ),
        values => $vals,
        pk     => { $self->pk_values_hash() },
    );
}

sub delete {
    my $self = shift;

    $self->__record_delete();

    $self->SUPER::delete(@_);
}

sub __record_delete {
    my $self = shift;

    $self->__recorder->record_action(
        action => 'delete',
        class  => ( ref $self ),
        pk     => { $self->pk_values_hash() },
    );
}

sub __recorder {
    my $self = shift;

    return Fey::Meta::Class::Schema->ClassForSchema( $self->Table->schema )
        ->Recorder();
}

sub _load_from_dbms {
    my $self = shift;

    if ( my $values = $self->Seeder()->next() ) {
        $self->_set_column_values_from_hashref($values);

        return;
    }

    return $self->SUPER::_load_from_dbms(@_);
}

{
    my %Seeder;

    sub Seeder {
        my $self = shift;

        return $Seeder{ ref $self || $self };
    }

    sub SetSeeder {
        my $self = shift;

        return $Seeder{ ref $self || $self } = shift;
    }
}

no Moose;

# inlining the constructor makes no sense, since we expect to be
# inherited from anyway, and those modules can inline their own
# constructor.
__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: Mock schema class subclass of Fey::Object::Table

__END__

=pod

=head1 NAME

Fey::Object::Mock::Table - Mock schema class subclass of Fey::Object::Table

=head1 VERSION

version 0.06

=head1 DESCRIPTION

When you use L<Fey::ORM::Mock> to mock a schema, this class will
become the immediate parent for each of your table classes. It in turn
inherits from C<Fey::Object::Table>.

This class overrides various methods in order to record inserts,
updates, and deletes. It also overrides C<_load_from_dbms()> in order
to use seeded values rather than fetching data from the DBMS.

=head1 METHODS

This class provides the following methods:

=head2 $class->Seeder

Returns the L<Fey::ORM::Mock::Seeder> object associated with the
table.

=head2 $class->SetSeeder($seeder)

Sets the L<Fey::ORM::Mock::Recorder> object associated with the table.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
