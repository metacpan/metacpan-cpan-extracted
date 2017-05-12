package Fey::DBIManager;
BEGIN {
  $Fey::DBIManager::VERSION = '0.16';
}

use strict;
use warnings;
use namespace::autoclean;

use Fey::Exceptions qw( object_state_error param_error );
use Scalar::Util qw( blessed );

use Fey::DBIManager::Source;

use Moose 0.90;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has _sources => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Fey::DBIManager::Source]',
    default  => sub { {} },
    init_arg => undef,
    handles  => {
        get_source    => 'get',
        add_source    => 'set',
        remove_source => 'delete',
        _source_count => 'count',
        has_source    => 'exists',
        sources       => 'values',
    },
);

around 'add_source' => sub {
    my $orig = shift;
    my $self = shift;

    my $source;
    if ( @_ > 1 ) {
        $source = Fey::DBIManager::Source->new(@_);
    }
    else {
        $source = shift;
    }

    my $name;
    if ( blessed $source && $source->can('name') ) {
        $name = $source->name();

        param_error qq{You already have a source named "$name".}
            if $self->has_source($name);
    }

    my $return = $self->$orig( $name => $source );

    return $return;
};

sub default_source {
    my $self = shift;

    if ( $self->_source_count() == 0 ) {
        object_state_error
            'This manager has no default source because it has no sources at all.';
    }
    elsif ( $self->_source_count() == 1 ) {

        # Need to force scalar context for the return value
        return ( $self->sources() )[0];
    }
    elsif ( my $source = $self->get_source('default') ) {
        return $source;
    }
    else {
        object_state_error
            'This manager has multiple sources, but none are named "default".';
    }

    return;
}

sub source_for_sql {
    my $self = shift;

    return $self->default_source();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Manage a set of DBI handles



=pod

=head1 NAME

Fey::DBIManager - Manage a set of DBI handles

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  my $manager = Fey::DBIManager->new();

  $manager->add_source( dsn => 'dbi:Pg:dbname=MyDB' );

  my $source = $manager->default_source();

  my $source = $manager->source_for_sql($select_sql);

=head1 DESCRIPTION

C<Fey::DBIManager> manager a set of L<Fey::DBIManager::Source>
objects, each of which in turn represents a single C<DBI> handle.

It's main purpose is to provide a single interface to one or more data
sources, allowing you to easily define your database connections in
one spot.

=head1 METHODS

This class provides the following methods:

=head2 Fey::DBIManager->new()

Returns a new C<Fey::DBIManager> object.

=head2 $manager->add_source(...)

This method adds a new L<Fey::DBIManager::Source> object to the
manager. It can either accept an instantiated
L<Fey::DBIManager::Source> object, or a set of parameters needed to
create a new source.

Sources are identified by name, and if you try to add one that already
exists in the manager, an error will be thrown.

=head2 $manager->get_source($name)

Given a source name, this returns the named source, if it exists in
the manager.

=head2 $manager->remove_source($name)

Removes the named source, if it exists in the manager.

=head2 $manager->has_source($name)

Returns true if the manager has the named source.

=head2 $manager->sources()

Returns all of the source in the manager.

=head2 $manager->default_source()

This method returns the default source for the manager. If the manager
has only one source, then this is the default. Otherwise it looks for
a source named "default". If no such source exists, or if the manager
has no sources at all, then an exception is thrown.

=head2 $manager->source_for_sql($sql_object)

This method accepts a single C<Fey::SQL> object and returns an
appropriate source.

By default, this method simply returns the default source. It exists
to provide a spot for subclasses which want to do something more
clever, such as use one source for reads and another for writes.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fey-dbimanager@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

