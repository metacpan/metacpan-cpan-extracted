use 5.008001;
use strict;
use warnings;

package Metabase::Backend::SQL;
# ABSTRACT: Metabase backend role for SQL-based backends

our $VERSION = '1.001';

use Class::Load qw/load_class try_load_class/;
use SQL::Translator::Schema;
use Storable qw/nfreeze/;

use Moose::Role;

has [qw/dsn db_user db_pass db_type/] => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

has dbis => (
  is => 'ro',
  isa => 'DBIx::Simple',
  lazy_build => 1,
  handles => [qw/dbh/],
);

has schema => (
  is => 'ro',
  isa => 'SQL::Translator::Schema',
  lazy_build => 1,
);

has '_blob_field_params' => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

has '_guid_field_params' => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

#--------------------------------------------------------------------------#
# to be implemented by Metabase::Backend::${DBNAME}
#--------------------------------------------------------------------------#

requires '_build_dsn';
requires '_build_db_user';
requires '_build_db_pass';
requires '_build_db_type';
requires '_fixup_sql_diff';
requires '_build__blob_field_params';
requires '_build__guid_field_params';
requires '_munge_guid';
requires '_unmunge_guid';


#--------------------------------------------------------------------------#

sub _build_dbis {
  my ($self) = @_;
  my @connect = map { $self->$_ } qw/dsn db_user db_pass/;
  my $dbis = eval { DBIx::Simple->connect(@connect, {PrintWarn => 0}) }
    or die "Could not connect via " . join(":",map { qq{'$_'} } @connect[0,1],"...")
    . " because: $@\n";
  return $dbis;
}

sub _build_schema {
  my $self = shift;
  return SQL::Translator::Schema->new(
    name => 'Metabase',
    database => $self->db_type,
  );
}

sub _deploy_schema {
  my ($self) = @_;

  my $schema = $self->schema;

  # Blow up if this doesn't seem OK
  $schema->is_valid or die "Could not validate schema: $schema->error";
#  use Data::Dumper;
#  warn "Schema: " . Dumper($schema);

  my $db_type = $self->db_type;
  # See what we already have
  my $existing = SQL::Translator->new(
    parser => 'DBI',
    parser_args => {
      dbh => $self->dbh,
    },
    producer => $db_type,
    show_warnings => 0, # suppress warning from empty DB
  );
  {
    # shut up P::RD when there is no text -- the SQL::Translator parser
    # forces things on when loaded.  Gross.
    no warnings 'once';
    load_class( "SQL::Translator::Parser::" . $db_type );
    load_class( "SQL::Translator::Producer::" . $db_type );
    local *main::RD_ERRORS;
    local *main::RD_WARN;
    local *main::RD_HINT;
    my $existing_sql = $existing->translate();
#    warn "*** Existing schema: " . $existing_sql;
  }

  # Convert our target schema
  my $fake = SQL::Translator->new(
    parser => 'Storable',
    producer => $db_type,
  );
  my $fake_sql = $fake->translate( \( nfreeze($schema) ) );
#  warn "*** Fake schema: $fake_sql";

  my $diff = SQL::Translator::Diff::schema_diff(
    $existing->schema, $db_type, $fake->schema, $db_type
  );

  $diff = $self->_fixup_sql_diff($diff);

  # DBIx::RunSQL requires a file (ugh)
  my ($fh, $sqlfile) = File::Temp::tempfile();
  print {$fh} $diff;
  close $fh;
#  warn "*** Schema Diff:\n$diff\n"; # XXX

  $self->clear_dbis; # ensure we re-initailize handle
  unless ( $diff =~ /-- No differences found/i ) {
    DBIx::RunSQL->create(
      dbh => $self->dbh,
      sql => $sqlfile,
      verbose_handler => sub { return },
    );
    $self->dbh->disconnect;
  }

  # must reset the connection
  $self->clear_dbis;
  $self->dbis; # rebuild

#  my ($count) = $self->dbis->query(qq{select count(*) from "core"})->list;
#  warn "Initialized with $count records";
  return;
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Backend::SQL - Metabase backend role for SQL-based backends

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  # SQLite

  require Metabase::Archive::SQLite;
  require Metabase::Index::SQLite;

  my $archive = Metabase::Archive::SQLite->new(
    filename => $sqlite_file,
  );

  my $index = Metabase::Index::SQLite->new(
    filename => $sqlite_file,
  );

  # PostgreSQL

  use Metabase::Archive::PostgreSQL;
  use Metabase::Index::PostgreSQL;

  my $archive = Metabase::Archive::PostgreSQL->new(
    db_name => "cpantesters",
    db_user => "johndoe",
    db_pass => "PaSsWoRd",
  );

  my $index = Metabase::Index::PostgreSQL->new(
    db_name => "cpantesters",
    db_user => "johndoe",
    db_pass => "PaSsWoRd",
  );

=head1 DESCRIPTION

This distribution contains implementations of L<Metabase::Archive> and
L<Metabase::Index> using SQL databases.  >See L<Metabase::Backend::SQLite> or
L<Metabase::Backend::PostgreSQL> for details about specific implementations.

The main module, itself, is merely a Moose role that provides common attributes
for all the SQL-based Metabase backends.  It is not intended to be used
directly by end-users.

=head1 ATTRIBUTES

=head2 dsn

Database connection string

=head2 db_user

Database username

=head2 db_pass

Database password

=head2 db_type

SQL::Translator sub-type for a given database.  E.g. "SQLite" or "PostgreSQL".

=head2 dbis

DBIx::Simple class connected to the database

=head2 schema

SQL::Translator::Schema class

=for Pod::Coverage method_names_here

=head1 REQUIRED METHODS

The following builders must be provided by consuming classes.

  _build_dsn        # a DSN string for DBI
  _build_db_user    # a username for DBI
  _build_db_pass    # a password for DBI
  _build_db_type    # a SQL::Translator type for the DB vendor

The following method must be provided to modify the output of
SQL::Translator::Diff to fix up any dialect quirks

  _fixup_sql_diff

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/metabase-backend-sql/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/metabase-backend-sql>

  git clone https://github.com/dagolden/metabase-backend-sql.git

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Leon Brocard <acme@astray.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
