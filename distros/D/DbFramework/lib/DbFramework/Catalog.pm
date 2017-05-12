=head1 NAME

DbFramework::Catalog - Catalog class

=head1 SYNOPSIS

  use DbFramework::Catalog;
  my $c = new DbFramework::Catalog($dsn,$user,$password);
  $c->set_primary_key($table);
  $c->set_keys($table);
  $c->set_foreign_keys($dm);

=head1 DESCRIPTION

B<DbFramework::Catalog> is a class for manipulating the catalog
database used by various DbFramework modules and scripts.

=head2 The Catalog

DbFramework retrieves as much metadata as possible using DBI.  It aims
to store the metadata B<not> provided by DBI in a consistent manner
across all DBI drivers by using a catalog database called
I<dbframework_catalog>.  Each database you use with DbFramework
B<requires> corresponding key information added to the catalog.  The
I<dbframework_catalog> database will be created for each driver you
test when you build DbFramework.  Entries in the catalog only need to
be modified when the corresponding database schema changes.

The following (Mysql) SQL creates the catalog database schema.

	CREATE TABLE c_db (
  	  db_name varchar(50) DEFAULT '' NOT NULL,
  	  PRIMARY KEY (db_name)
	);

	CREATE TABLE c_key (
	  db_name varchar(50) DEFAULT '' NOT NULL,
	  table_name varchar(50) DEFAULT '' NOT NULL,
	  key_name varchar(50) DEFAULT '' NOT NULL,
	  key_type int(11) DEFAULT '0' NOT NULL,
	  key_columns varchar(255) DEFAULT '' NOT NULL,
	  PRIMARY KEY (db_name,table_name,key_name)
	);

	CREATE TABLE c_relationship (
	  db_name varchar(50) DEFAULT '' NOT NULL,
	  fk_table varchar(50) DEFAULT '' NOT NULL,
	  fk_key varchar(50) DEFAULT '' NOT NULL,
	  pk_table varchar(50) DEFAULT '' NOT NULL,
	  PRIMARY KEY (db_name,fk_table,fk_key,pk_table)
	);

	CREATE TABLE c_table (
	  table_name varchar(50) DEFAULT '' NOT NULL,
	  db_name varchar(50) DEFAULT '' NOT NULL,
	  labels varchar(127) DEFAULT '',
	  PRIMARY KEY (table_name,db_name)
	);

The example below shows the creation of a simple Mysql database and
the corresponding catalog entries required by DbFramework.

	CREATE DATABASE foo;
        use foo;

	CREATE TABLE foo (
  	  foo integer not null,
	  bar varchar(50),
	  KEY var(bar),
  	  PRIMARY KEY (foo)
	);

	CREATE TABLE bar (
  	  bar integer not null,
	  # foreign key to table foo
	  foo integer not null,
  	  PRIMARY KEY (bar)
	);

	use dbframework_catalog;

	# catalog entry for database 'foo'
	INSERT INTO c_db VALUES('foo');

	# catalog entries for table 'foo'
	INSERT INTO c_table VALUES('foo','foo','bar');
	# primary key type = 0
	INSERT INTO c_key VALUES('foo','foo','primary',0,'foo');
	# index type = 2
	INSERT INTO c_key VALUES('foo','foo','bar_index',2,'bar');

	# catalog entries for table 'bar'
	INSERT INTO c_table VALUES('bar','foo',NULL);
	# primary key type = 0
	INSERT INTO c_key VALUES('foo','bar','primary',0,'bar');
	# foreign key type = 1
	INSERT INTO c_key VALUES('foo','bar','foreign_foo',2,'foo');
	# relationship between 'bar' and 'foo'
	INSERT INTO c_relationship VALUES('foo','bar','foreign_foo','foo');

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Catalog;
use strict;
use base qw(DbFramework::Util);
use DbFramework::PrimaryKey;
use DbFramework::ForeignKey;
use Alias;
use Carp;
use vars qw($DBH $_DEBUG %keytypes $db);

## CLASS DATA

my %fields = (
              DBH => undef,
	     );

$db       = 'dbframework_catalog';
%keytypes = (primary => 0, foreign => 1, index => 2);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($dsn,$user,$password)

Create a new B<DbFramework::Catalog> object.  I<$dsn> is the DBI data
source name containing the catalog database (default is
'dbframework_catalog').  I<$user> and I<$password> are optional
arguments specifying the username and password to use when connecting
to the database.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self  = bless({},$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->dbh(DbFramework::Util::get_dbh(@_));
  $self->dbh->{PrintError} = 0;
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 set_primary_key($table)

Set the primary key for the B<DbFramework::Table> object I<$table>.
The catalog column B<c_table.labels> may contain a colon seperated
list of column names to be used as 'labels' (see
L<DbFramework::Primary/new()>.)

=cut

sub set_primary_key {
  my $self           = attr shift;
  my $table          = shift;
  my $sth            = $self->_get_key_columns($table,'primary');
  if ( $sth->rows == 0 ) {
    $sth->finish;
    carp "Can't get primary key for ",$table->name,"\n"
  }
  my($name,$columns) = @{$sth->fetchrow_arrayref};
  $sth->finish;
  my @attributes = $table->get_attributes(split /:/,$columns);

  # get label columns
  my $table_name = $DBH->quote($table->name);
  my $db_name    = $DBH->quote($table->belongs_to->db);
  my $sql        = qq{
SELECT labels
FROM   c_table
WHERE  db_name    = $db_name
AND    table_name = $table_name
};
  print STDERR "$sql\n" if $_DEBUG;
  $sth           = $DBH->prepare($sql) || die($DBH->errstr);
  my $rv         = $sth->execute       || die($sth->errstr);
  my($labels)    = $sth->fetchrow_array;
  my $labels_ref = undef;
  @$labels_ref   = split /:/,$labels if defined $labels && $labels ne '';
  $sth->finish;
  print STDERR "$table_name.pk: $columns\n" if $_DEBUG;
  my $pk = new DbFramework::PrimaryKey(\@attributes,$table,$labels_ref);
  $table->is_identified_by($pk);
}

##-----------------------------------------------------------------------------

=head2 set_keys($table)

Set the keys (indexes) for the B<DbFramework::Table> object I<$table>.

=cut

sub set_keys {
  my $self  = attr shift;
  my $table = shift;
  my $sth   = $self->_get_key_columns($table,'index');
  my @keys;
  while ( my $rowref = $sth->fetchrow_arrayref ) {
    my($name,$columns) = @$rowref;
    print STDERR "$name $columns\n" if $_DEBUG;
    my @attributes     = $table->get_attributes(split /:/,$columns);
    my $key            = new DbFramework::Key($name,\@attributes);
    $key->belongs_to($table);
    push(@keys,$key);
  }
  $table->is_accessed_using_l(\@keys);
  $sth->finish;
}

##-----------------------------------------------------------------------------

=head2 set_foreign_keys($dm)

Set the foreign keys for the B<DbFramework::DataModel> object I<$dm>.

=cut

sub set_foreign_keys {
  my $self       = attr shift;
  my $dm         = shift;
  my $db_name    = $DBH->quote($dm->db);
  for my $table ( @{$dm->collects_table_l} ) {
    my $table_name = $DBH->quote($table->name);
    my $sql;
    if ( $dm->driver eq 'CSV' ) {
      $sql = qq{
SELECT key_name,key_columns,pk_table
FROM   c_relationship,c_key WHERE  c_relationship.db_name  = $db_name
AND    c_relationship.fk_table = $table_name
AND    c_relationsihp.db_name  = c_key.db_name
AND    c_relationship.fk_table = c_key.table_name
AND    c_relationship.fk_key   = c_key.key_name
};
    } else {
      $sql = qq{
SELECT k.key_name,k.key_columns,r.pk_table
FROM   c_relationship r, c_key k
WHERE  r.db_name  = $db_name
AND    r.fk_table = $table_name
AND    r.db_name  = k.db_name
AND    r.fk_table = k.table_name
AND    r.fk_key   = k.key_name
};
  }
    print STDERR "$sql\n" if $_DEBUG;
    my $sth = DbFramework::Util::do_sql($DBH,$sql);
    while ( my $rowref = $sth->fetchrow_arrayref ) {
      my($name,$columns,$pk_table_name) = @$rowref;
      print STDERR "name = $name, columns = $columns, pk_table = $pk_table_name)\n" if $_DEBUG;
      my @attributes = $table->get_attributes(split /:/,$columns);
      my $pk_table = $table->belongs_to->collects_table_h_byname($pk_table_name);

      my $fk = new DbFramework::ForeignKey($name,
					   \@attributes,
					   $pk_table->is_identified_by);
      $fk->belongs_to($table);
      $table->has_foreign_keys_l_add($fk);                # by number
      $table->has_foreign_keys_h_add({$fk->name => $fk}); # by name
      $pk_table->is_identified_by->incorporates($fk);     # pk ref
    }
    $sth->finish;

    $table->validate_foreign_keys;
    # default templates need updating after setting foreign keys
    #$table->_templates;
  }
}

##-----------------------------------------------------------------------------

sub _get_key_columns {
  my $self       = attr shift;
  my($table,$key_type) = @_;
  my $table_name = $DBH->quote($table->name);
  my $db_name    = $DBH->quote($table->belongs_to->db);
  my $sql        = qq{
SELECT key_name,key_columns
FROM   c_key
WHERE  db_name    = $db_name
AND    table_name = $table_name
AND    key_type   = $keytypes{$key_type}
};
  print STDERR "$sql\n" if $_DEBUG;
  my $sth = $DBH->prepare($sql) || die($DBH->errstr);
  my $rv  = $sth->execute       || die($sth->errstr);
  return $sth;
}

##-----------------------------------------------------------------------------

sub DESTROY {
  my $self = attr shift;
  $DBH->disconnect;
}

1;

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
