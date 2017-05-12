package Fey::Meta::Class::Schema;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::DBIManager;
use Fey::Exceptions qw( param_error );
use Fey::ORM::Types qw( ClassName HashRef );

use Moose;
use MooseX::ClassAttribute;
use MooseX::Params::Validate qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor;

extends 'Moose::Meta::Class';

class_has '_SchemaClassMap' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef ['Fey::Schema'],
    default => sub { {} },
    lazy    => 1,
    handles => {
        SchemaForClass     => 'get',
        _SetSchemaForClass => 'set',
        _ClassHasSchema    => 'exists',
    },
);

has 'schema' => (
    is        => 'rw',
    isa       => 'Fey::Schema',
    writer    => '_set_schema',
    predicate => '_has_schema',
);

has 'dbi_manager' => (
    is      => 'rw',
    isa     => 'Fey::DBIManager',
    lazy    => 1,
    default => sub { Fey::DBIManager->new() },
);

has 'sql_factory_class' => (
    is      => 'rw',
    isa     => ClassName,
    lazy    => 1,
    default => 'Fey::SQL',
);

sub ClassForSchema {
    my $class = shift;
    my ($schema) = pos_validated_list( \@_, { isa => 'Fey::Schema' } );

    my $map = $class->_SchemaClassMap();

    for my $class_name ( keys %{$map} ) {
        return $class_name
            if $map->{$class_name}->name() eq $schema->name();
    }

    return;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _associate_schema {
    my $self   = shift;
    my $schema = shift;

    my $caller = $self->name();

    param_error 'Cannot call has_schema() more than once per class'
        if $self->_has_schema();

    param_error 'Cannot associate the same schema with multiple classes'
        if __PACKAGE__->ClassForSchema($schema);

    __PACKAGE__->_SetSchemaForClass( $self->name() => $schema );

    $self->_set_schema($schema);
}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A metaclass for schema classes

__END__

=pod

=head1 NAME

Fey::Meta::Class::Schema - A metaclass for schema classes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Schema;

  use Fey::ORM::Schema;

  print __PACKAGE__->meta()->ClassForSchema($schema);

=head1 DESCRIPTION

This is the metaclass for schema classes. When you use
L<Fey::ORM::Schema> in your class, it uses this class to do all the
heavy lifting.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Meta::Class::Schema->ClassForSchema($schema)

Given a L<Fey::Schema> object, this method returns the name of the
class which "has" that schema, if any.

=head2 Fey::Meta::Class::Schema->SchemaForClass($class)

Given a class, this method returns the L<Fey::Schema> object
associated with that class, if any.

=head2 $meta->table()

Returns the L<Fey::Schema> for the metaclass's class.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
