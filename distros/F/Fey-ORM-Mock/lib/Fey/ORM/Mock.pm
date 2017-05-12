package Fey::ORM::Mock;
{
  $Fey::ORM::Mock::VERSION = '0.06';
}

use strict;
use warnings;

use Class::Load qw( load_class );
use DBD::Mock;
use Fey::DBIManager;
use Fey::Object::Mock::Schema;
use Fey::Object::Mock::Table;
use Fey::ORM::Mock::Recorder;
use Fey::ORM::Mock::Seeder;
use Fey::Meta::Class::Table;

use Moose;

has 'schema_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
);

has 'recorder' => (
    is       => 'rw',
    isa      => 'Fey::ORM::Mock::Recorder',
    writer   => '_set_recorder',
    init_arg => undef,
);

sub BUILD {
    my $self = shift;

    $self->_mock_schema();

    $self->_mock_dbi();
}

sub _mock_schema {
    my $self = shift;

    $self->_replace_superclass( $self->schema_class(),
        'Fey::Object::Mock::Schema' );

    my $recorder = Fey::ORM::Mock::Recorder->new();
    $self->schema_class()->SetRecorder($recorder);
    $self->_set_recorder($recorder);

    $self->_mock_table($_) for $self->schema_class()->Schema()->tables();
}

sub _replace_superclass {
    my $self       = shift;
    my $class      = shift;
    my $superclass = shift;

    load_class($class);

    my $meta = $class->meta();

    my $was_immutable;
    if ( $meta->is_immutable() ) {
        $meta->make_mutable();
        $was_immutable = 1;
    }

    $meta->superclasses($superclass);

    $self->_reapply_method_modifiers($meta);

    $meta->make_immutable()
        if $was_immutable;
}

sub _reapply_method_modifiers {
    my $self = shift;
    my $meta = shift;

    for my $method (
        grep { $_->isa('Class::MOP::Method::Wrapped') }
        map  { $meta->get_method($_) } $meta->get_method_list()
        ) {
        next
            if $method->get_original_method()->package_name() eq
                $meta->name();

        $meta->remove_method( $method->name() );

        for my $before ( reverse $method->before_modifiers() ) {
            $meta->add_before_method_modifier( $method->name() => $before );
        }

        for my $after ( $method->after_modifiers() ) {
            $meta->add_after_method_modifier( $method->name() => $after );
        }

        for my $around ( reverse $method->around_modifiers() ) {
            $meta->add_around_method_modifier( $method->name() => $around );
        }
    }
}

sub _mock_table {
    my $self  = shift;
    my $table = shift;

    my $class = Fey::Meta::Class::Table->ClassForTable($table)
        or return;

    $self->_replace_superclass( $class, 'Fey::Object::Mock::Table' );

    my $seed = Fey::ORM::Mock::Seeder->new();
    $class->SetSeeder($seed);
}

sub seed_class {
    my $self  = shift;
    my $class = shift;

    my $seed = $class->Seeder();

    $seed->push_values(@_);
}

sub _mock_dbi {
    my $self = shift;

    my $dsn = 'dbi:Mock:';

    my $dbh = DBI->connect( $dsn, q{}, q{} );

    my $manager = Fey::DBIManager->new();
    $manager->add_source( dsn => $dsn, dbh => $dbh );

    $self->schema_class()->SetDBIManager($manager);
}

1;

# ABSTRACT: Mock Fey::ORM based classes so you can test without a DBMS

__END__

=pod

=head1 NAME

Fey::ORM::Mock - Mock Fey::ORM based classes so you can test without a DBMS

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Fey::ORM::Mock;
    use MyApp::Schema;

    my $mock = Fey::ORM::Mock->new( schema_class => 'MyApp::Schema' );

    $mock->seed_class( 'MyApp::User' =>
                       { user_id => 42,
                         name    => 'Doug',
                       },
                       ...
                     );

    # gets seeded data first
    my $user = User->new( ... );

    $user = User->insert( ... );
    $user->update( ... );

    my @actions = $mock->recorder()->actions_for_class('User');

=head1 DESCRIPTION

This class lets you mock a set of C<Fey::ORM> based classes. You can
seed data for each class's constructor, as well as track all inserts,
update, and deletes for each class.

This is all done at a higher level than is possible just using
C<DBD::Mock>. Instead of dealing with SQL and DBI's data structures,
you are able to work with the named attributes of each class.

=head1 METHODS

This class provides the following methods:

=head2 Fey::ORM::Mock->new( schema_class => $class )

Given a schema class (one which uses C<Fey::ORM::Schema>), this method
adds a mocking layer to the schema class and all of its tables'
associated classes. If a table does not have an associated class, it
will simply be skipped.

It also replaces the schema class's existing C<Fey::DBIManager> object
with one that has a single C<DBD::Mock> handle.

=head2 $mock->schema_class()

The schema class name that was passed to the constructor.

=head2 $mock->recorder()

Returns the L<Fey::ORM::Mock::Recorder> object that records all
inserts, updates, and deletes for tables in this schema.

=head2 $mock->seed_class( $class => \%attr, \%attr, ... )

This method accepts a class name and one or more hash references. Each
hash reference should consist of some or all of the class's attributes
and associated values.

These seeded hash references will be used the next time C<<
$class->new() >> is called without the "_from_query" parameter. This
prevents an attempt to fetch data from the database handle.

Note that any attribute values you pass to the constructor will
override seeded values.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fey-mock@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
