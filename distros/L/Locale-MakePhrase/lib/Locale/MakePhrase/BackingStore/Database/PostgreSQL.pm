package Locale::MakePhrase::BackingStore::Database::PostgreSQL;
our $VERSION = 0.2;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::BackingStore::Database::PostgreSQL - Retrieve
translations from a table within a PostgreSQL database.

=head1 DESCRIPTION

This backing store is capable of loading language rules from a
PostgreSQL table. See L<Locale::MakePhrase::BackingStore::Database>
for more information.

The PostgreSQL database instanc should be setup to use UNICODE as the
text storage mechanism (ie: 'psql -l' should show you how the database
instance was created).

=head1 TABLE STRUCTURE

The table structure can be created with the following PostgreSQL
SQL statement:

  CREATE TABLE some_table (
    key TEXT,
    language TEXT,
    expression TEXT,
    priority INTEGER,
    translation TEXT
  );

This only differs from the generic database driver, in that TEXT
is being used as a replacement for VARCHAR (both statements do the
same thing).

=head1 API

The following methods are implemented:

=cut

use strict;
use warnings;
use utf8;
use Data::Dumper;
use DBI;
use DBD::Pg;
use base qw(Locale::MakePhrase::BackingStore);
our $default_connect_options = {
  RaiseError => 1,
  AutoCommit => 1,
  ChopBlanks => 1,
  pg_enable_utf8 => 1,  # assumes database is using UNICODE
};
local $Data::Dumper::Indent = 1 if $DEBUG;

#--------------------------------------------------------------------------

=head2 $self new([...])

[ Inherited from L<Locale::MakePhrase::BackingStore::Database>. ]

Any options defined for in the base class, can be set here. ie: you
could specify some of these options:

=over 2

=item C<table>

You must set this value.

=item C<dbh>

=item C<owned>

=item C<host>

This module defaults to B<localhost> unless it is defined.

=item C<port>

This module defaults to B<5432> unless it is defined.

=item C<user>

This module defaults to an empty string.

=item C<password>

This module defaults to an empty string.

=item C<connect_options>

The default PostgreSQL connections options are:

  RaiseError => 1
  AutoCommit => 1
  ChopBlanks => 1
  pg_enable_utf8 => 1

If you set this value, you must supply a hash_ref supplying the
appropriate PostgreSQL connection options.

Note that we set the AutoCommit simply because we only ever do
SELECT's from the table, thus we never need to concern ourselves
with aborted transations.

=back

Notes: you must specify either the C<dbh> option, or suitable connection
options.

=cut

sub init {
  my $self = shift;
  $self->{driver} = 'Pg';
  $self->{host} = 'localhost';
  $self->{port} = 5432;
  $self->{user} = '';
  $self->{password} = '';
  $self->{connect_options} = $default_connect_options;
  return $self;
}

1;
__END__
#--------------------------------------------------------------------------

=cut

