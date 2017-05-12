package Interchange6::Test::Role::Database;

use Test::Roo::Role;

requires qw(_build_database _build_dbd_version);

=head1 NAME

Interchange6::Test::Role::Database

=head1 DESCRIPTION

Role consumed by all database-specific roles such as SQLite and Pg to provide common functionality.

=head1 ATTRIBUTES

=head2 database

The database object. We expect a database-specific role to supply the builder.

=cut

has database => (
    is      => 'lazy',
    clearer => 1,
);

=head2 database_info

Database backend version and other interesting info (if available).  We expect a database-specific role to supply the builder.

=cut

has database_info => (
    is => 'lazy',
);

sub _build_database_info {
    return "no info";
}

=head2 dbd_version

DBD::Foo version string. We expect a database-specific role to supply the builder.

=cut

has dbd_version => (
    is => 'lazy',
);

=head2 schema_class

Defaults to Interchange6::Schema. This gives tests the normal expected schema but allows them to overload with some other test schema if desired.

=cut

has schema_class => (
    is => 'ro',
    default => 'Interchange6::Schema',
);

=head2 ic6s_schema

Our connected and deployed schema,

=cut;

has ic6s_schema => (
    is => 'lazy',
    clearer => 1,
);

sub _build_ic6s_schema {
    my $self = shift;

    require DBIx::Class::Optional::Dependencies;
    if ( my $missing =
        DBIx::Class::Optional::Dependencies->req_missing_for('deploy') )
    {
        diag "WARN: missing $missing";
        plan skip_all => "$missing required to run tests";
    }

    my $schema_class = $self->schema_class;
    eval "require $schema_class"
      or die "failed to require $schema_class: $@";

    my $schema =  $schema_class->connect( $self->connect_info )
      or die "failed to connect to ";
    $schema->deploy();
    return $schema;
}

=head1 MODIFIERS

=head2 before setup

Add diag showing DBD version info.

=cut

before setup => sub {
    my $self = shift;
    diag "using: " . $self->dbd_version;
    diag "db: " . $self->database_info;
};

1;
