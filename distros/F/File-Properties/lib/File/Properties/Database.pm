# ----------------------------------------------------------------------------
#
# This module provides an interface to the SQLite database used to
# cache data for File::Properties modules.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 5 November 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Database;
our $VERSION = 0.01;

use File::Properties::Error;

require 5.005;
use strict;
use warnings;
use DBI qw(:sql_types);
use DBD::SQLite;
use Error qw(:try);


# ----------------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------------
sub new {
  my $clss = shift;

  my $self = {};
  bless $self, $clss;
  $self->_init(@_);
  return $self;
}


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $dbfp = shift; # Database file path
  my $opts = shift; # Options hash

  $opts = {} if undef $opts;
  # Throw exception if DB file $dpfp does not exist and 'NoCreate'
  # option is true.
  throw File::Properties::Error("DBI file $dbfp not found")
    if $opts->{'NoCreate'} and (not defined $dbfp or not -f $dbfp);
  # If DB file not specified, construct it in memory
  $dbfp = ':memory:' if (not defined $dbfp);
  ## Throw exception if error encountered opening DBI connection
  my $dbh = _dbopen($dbfp, $opts->{'ReadOnly'}?1:0);
  throw File::Properties::Error("Error opening DBI interface to file $dbfp")
      if not defined($dbh);
  # Record constructor options
  $self->opts($opts);
  # Record SQLite DBI interface
  $self->dbi($dbh);
  # Table column specifications
  $self->definedcolumns(undef,{});
}


# ----------------------------------------------------------------------------
# Destructor
# ----------------------------------------------------------------------------
sub DESTROY {
  my $self = shift;

  _dbclose($self->dbi);
}


# ----------------------------------------------------------------------------
# Get (or set) options specified at initialisation
# ----------------------------------------------------------------------------
sub opts {
  my $self = shift;

  $self->{'opts'} = shift if (@_);
  return $self->{'opts'}
}


# ----------------------------------------------------------------------------
# Get (or set) dbi handle
# ----------------------------------------------------------------------------
sub dbi {
  my $self = shift;

  $self->{'dbih'} = shift if (@_);
  return $self->{'dbih'}
}


# ----------------------------------------------------------------------------
# Get (or set) table column specification hash or hash entry
# ----------------------------------------------------------------------------
sub definedcolumns {
  my $self = shift;
  my $tbnm = shift; # Table name

  ## If table name is defined, additional parameter specifies new
  ## value for that hash entry, otherwise the additional parameter
  ## specifies new value for entire hash
  if (@_) {
    if (defined $tbnm) {
      $self->{'tblc'}->{$tbnm} = shift;
    } else {
      $self->{'tblc'} = shift;
    }
  }

  ## If table name is specified and the corresponding entry is not
  ## defined, obtain the column names from the SQL database
  if (defined $tbnm and not defined $self->{'tblc'}->{$tbnm}) {
    $self->{'tblc'}->{$tbnm} = $self->columns($tbnm);
  }

  # Return hash reference, or hash entry if table name specified
  return (defined $tbnm)? $self->{'tblc'}->{$tbnm}:$self->{'tblc'};
}


# ----------------------------------------------------------------------------
# Execute SQL command
# ----------------------------------------------------------------------------
sub sql {
  my $self = shift;
  my $sqlc = shift; # SQL command text

  return $self->dbi->do($sqlc);
}


# ----------------------------------------------------------------------------
# Define (and initialise) table
# ----------------------------------------------------------------------------
sub definetable {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $cols = shift; # Column specification

  ## Create table if it doesn't exist. WARNING: when the table already
  ## exists, there is currently not a test to ensure that the existing
  ## layout matches the column specification in the arguments to this
  ## method
  my $sqlc = "CREATE TABLE IF NOT EXISTS $tbnm (" . join(',',@$cols) . ');';
  my $drtv = $self->sql($sqlc);
  # Record column names for this table
  $self->definedcolumns($tbnm, [map { /^[^\s]+/; $& } @$cols]);
  return $drtv;
}


# ----------------------------------------------------------------------------
# Insert rows into table
# ----------------------------------------------------------------------------
sub insert {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $opts = shift; # Insert options

  # Determine column names for insert
  my $clnm = $self->_optioncols($tbnm, $opts);
  # Determine data for insert
  my $data = _optiondata($tbnm, $clnm, $opts);
  # Start transaction (autocommit off)
  $self->dbi->begin_work or
    throw File::Properties::Error("DBI error ".$self->dbi->errstr);
  # Construct string describing columns corresponding to row data,
  # using either specified array of column names, or recorded column
  # names for this table
  my $clst = join(',',@$clnm);
  # Construct insert statement
  my $sqlc = "INSERT INTO $tbnm ($clst) VALUES (" .
    join(',', map { '?' } @$clnm) . ');';
  # Prepare for insertion
  my $sth = $self->dbi->prepare($sqlc);
  # Execute insertion
  return $self->_executedata($sth, $data);
}


# ----------------------------------------------------------------------------
# Update rows in table
# ----------------------------------------------------------------------------
sub update {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $opts = shift; # Update options

  # Determine column names for update
  my $clnm = $self->_optioncols($tbnm, $opts);
  # Determine data for update
  my $data = _optiondata($tbnm, $clnm, $opts);
  # Start transaction (autocommit off)
  $self->dbi->begin_work or
    throw File::Properties::Error("DBI error ".$self->dbi->errstr);
  # Construct update statement
  my $sqlc = "UPDATE $tbnm SET " . join(',', map { "$_=?" } @$clnm);
  $sqlc .= _optionwhere($opts);
  # Prepare for update
  my $sth = $self->dbi->prepare($sqlc);
  # Execute update
  return $self->_executedata($sth, $data);
}


# ----------------------------------------------------------------------------
# Select data from table
# ----------------------------------------------------------------------------
sub retrieve {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $opts = shift; # Select options

  my $slc = 'SELECT ';
  # Select statement includes DISTINCT if 'Distint' option true
  $slc .= 'DISTINCT ' if (ref($opts) eq 'HASH' and $opts->{'Distinct'});
  my ($ncl, $cln);
  ## List of returned columns is constructed from the array provided
  ## with the 'Columns' option, otherwise all columns are returned
  if (ref($opts) eq 'HASH' and ref($opts->{'Columns'}) eq 'ARRAY') {
    $slc .= join(',',@{$opts->{'Columns'}}) . ' ';
    $cln = $opts->{'Columns'};
    $ncl = scalar @$cln;
  } else {
    $slc .= '* ';
    $cln = $self->definedcolumns($tbnm);
    $ncl = scalar @$cln;
  }
  # Append FROM and WHERE clauses to select statement
  $slc .= "FROM $tbnm " . _optionwhere($opts);
  # Append optional additional clauses to select statement
  $slc .= $opts->{'Suffix'} if (ref($opts) eq 'HASH' and $opts->{'Suffix'});
  # Check option 'ReturnType' for invalid values
  throw File::Properties::Error("Option 'ReturnType' may only have".
				"values 'Array' or 'Hash'")
    if (ref($opts) eq 'HASH' and defined($opts->{'ReturnType'}) and
        not($opts->{'ReturnType'} eq 'Array' or
	    $opts->{'ReturnType'} eq 'Hash'));
  ## DBI method for retrieving data depends on options 'ReturnType'
  ## and 'FirstRow'. If 'ReturnType' is not specified, data is
  ## retrieved as an array. If 'FirstRow' option is unspecified, or is
  ## false, a single row is returned.
  my $dat = undef;
  if (ref($opts) eq 'HASH' and defined($opts->{'ReturnType'}) and
      $opts->{'ReturnType'} eq 'Hash') {
    if (ref($opts) eq 'HASH' and $opts->{'FirstRow'}) {
      # Retrieve single row as a hash indexed by column names
      $dat = $self->dbi->selectrow_hashref($slc);
    } else {
      # Retrieve rows as an array of arrays
      my $adt = $self->dbi->selectall_arrayref($slc);
      ## Map array to hash of arrays indexed by column names
      $dat = {};
      map { $dat->{$_} = [] } @$cln;
      map { my $r = $_; map { push @{$dat->{$cln->[$_]}}, $r->[$_] }
	      @{[0 .. (scalar @$cln-1)]} } @$adt;
    }
  } else {
    if (ref($opts) eq 'HASH' and $opts->{'FirstRow'}) {
      # Retrieve single row as an array
      $dat = $self->dbi->selectrow_arrayref($slc);
    } else {
      # Retrieve rows as an array of arrays
      $dat = $self->dbi->selectall_arrayref($slc);
    }
  }

  return $dat;
}


# ----------------------------------------------------------------------------
# Remove data from table
# ----------------------------------------------------------------------------
sub remove {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $opts = shift; # Delete options

  # Throw exception if options hash includes neither a 'Where'
  # constraint nor the 'RemoveAll' flag
  throw File::Properties::Error("Method remove called without row selection")
    if (ref($opts) ne 'HASH' or (not defined $opts->{'Where'}
				 #and not defined $opts->{'Suffix'}
				 and not $opts->{'RemoveAll'}));
  # Set up SQL DELETE statement
  my $sqlc = "DELETE FROM $tbnm "._optionwhere($opts);
  ## Append optional additional clauses to delete statement
  #$sqlc .= $opts->{'Suffix'} if (ref($opts) eq 'HASH' and $opts->{'Suffix'});
  # Execute SQL DELETE statement
  return $self->sql($sqlc);
}


# ----------------------------------------------------------------------------
# Determine names of all tables
# ----------------------------------------------------------------------------
sub tables {
  my $self = shift;

  # Set up SQL statement
  my $sqlc = "SELECT * FROM sqlite_master WHERE type = 'table'";
  # Execute SQL statement
  my $rar = $self->dbi->selectall_arrayref($sqlc);
  return [map { $_->[1] } @$rar];
}


# ----------------------------------------------------------------------------
# Determine names of columns in specified table
# ----------------------------------------------------------------------------
sub columns {
  my $self = shift;
  my $tbnm = shift; # Table name

  # Set up SQL statement
  my $sqlc = "PRAGMA table_info($tbnm)";
  # Execute SQL statement
  my $rar = $self->dbi->selectall_arrayref($sqlc);
  return [map { $_->[1] } @$rar];
}


# ----------------------------------------------------------------------------
# Determine number of rows in specified table
# ----------------------------------------------------------------------------
sub numrows {
  my $self = shift;
  my $tbnm = shift; # Table name

  # Set up SQL statement
  my $sqlc = "SELECT Count(*) FROM $tbnm";
  # Execute SQL statement
  my $rar = $self->dbi->selectall_arrayref($sqlc);
  return $rar->[0]->[0];
}


# ----------------------------------------------------------------------------
# Determine whether table exists
# ----------------------------------------------------------------------------
sub tableexists {
  my $self = shift;
  my $tbnm = shift; # Table name

  return _tableexists($self->dbi, $tbnm);
}


# ----------------------------------------------------------------------------
# Create column name array for insert and update operations
# ----------------------------------------------------------------------------
sub _optioncols {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $opts = shift; # Options hash

  ## Column names are taken from keys of the 'Data' option if it is a
  ## hash, otherwise from 'Columns' option if provided, otherwise
  ## assumed to be all columns in table order
  my $clnm;
  if (ref($opts) eq 'HASH') {
    if (ref($opts->{'Data'}) eq 'HASH') {
      $clnm = [sort keys %{$opts->{'Data'}}];
    } elsif (ref($opts->{'Columns'}) eq 'ARRAY') {
      $clnm = $opts->{'Columns'};
    } else {
      $clnm = $self->definedcolumns($tbnm);
    }
  } else {
    $clnm = $self->definedcolumns($tbnm);
  }

  return $clnm;
}


# ----------------------------------------------------------------------------
# Create data array for insert and update operations
# ----------------------------------------------------------------------------
sub _optiondata {
  my $tbnm = shift; # Table name
  my $clnm = shift; # Column names
  my $opts = shift; # Options hash

  ## If 'Data' option provided, process it into a form ready for
  ## insertion
  my $data = undef;
  if (ref($opts) eq 'HASH' and ref($opts->{'Data'})) {
    # Data is provided as a hash
    if (ref($opts->{'Data'}) eq 'HASH') {
      # If first column in hash is an array reference, assume all
      # columns are array references, specifying multiple insertion
      # rows
      if (ref($opts->{'Data'}->{$clnm->[0]}) eq 'ARRAY') {
	$data = [];
	my $nrow = scalar @{$opts->{'Data'}->{$clnm->[0]}};
	for (my $n = 0; $n < $nrow; $n++) {
	  push @$data, [map { $opts->{'Data'}->{$_}->[$n] } @$clnm];
	}
      }
      # Assume that only a single row is to be inserted
      else {
	$data = [[map { $opts->{'Data'}->{$_} } @$clnm]];
      }
    }
    # Data is provided as an array
    elsif (ref($opts->{'Data'}) eq 'ARRAY') {
      # If the first entry in the array is an array reference, assume
      # multiple insertion rows are provided
      if (ref($opts->{'Data'}->[0]) eq 'ARRAY') {
	$data = $opts->{'Data'};
      }
      # Assume that only a single row is to be inserted
      else {
	$data = [[@{$opts->{'Data'}}]];
      }
    } else {
      throw File::Properties::Error("Data option must be a hash or an array");
    }
  }

  return $data;
}


# ----------------------------------------------------------------------------
# Create where statement for retrieve and remove operations
# ----------------------------------------------------------------------------
sub _optionwhere {
  my $opts = shift; # Options hash

  my $whr = '';
  ## If option 'Where' is a hash reference, key/value pairs are
  ## assumed to correspond to column name/value pairs in a conjunction
  ## of equality constraints in a WHERE clause. If it is not a hash
  ## reference, the value is assume to be a string containing the
  ## WHERE clause.
  if (ref($opts) eq 'HASH' and defined $opts->{'Where'}) {
    if (ref($opts->{'Where'}) eq 'HASH') {
      $whr .= " WHERE " . join ' AND ',
	map { "$_='$opts->{'Where'}->{$_}'" } keys %{$opts->{'Where'}};
    } else {
      $whr .= " WHERE " . $opts->{'Where'};
    }
  }

  return $whr;
}


# ----------------------------------------------------------------------------
# Execute statement handle object over specified data
# ----------------------------------------------------------------------------
sub _executedata {
  my $self = shift;
  my $sth = shift;  # Statement handle object
  my $data = shift; # Data array

  ## If data provided, insert each row and then commit,
  ## otherwise return the statement handle object from prepare
  if (defined $data) {
    my $row;
    foreach $row (@$data) {
      $sth->execute(@$row) or
	throw File::Properties::Error("DBI error ".$self->dbi->errstr);
    }
    if (not $self->dbi->commit) {
      my $err = $self->dbi->errstr;
      $self->dbi->rollback;
      throw File::Properties::Error("DBI error $err");
    }
    return $data;
  } else {
    return $sth;
  }
}


# ----------------------------------------------------------------------------
# Connect to SQLite database
# ----------------------------------------------------------------------------
sub _dbopen {
  my $dbf = shift; # DB file path
  my $rof = shift; # Read only flag

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbf",'','',
			 { ReadOnly   => $rof,
			   AutoCommit => 1,
			   PrintError => 0,
			   RaiseError => 1,
			   HandleError =>
			     sub {throw File::Properties::Error($_[0])} });
  $dbh->{sqlite_unicode} = 1 if defined $dbh;
  return $dbh;
}


# ----------------------------------------------------------------------------
# Disconnect from SQLite database
# ----------------------------------------------------------------------------
sub _dbclose {
  my $dbh = shift; # DBI handle

  $dbh->disconnect();
}


# ----------------------------------------------------------------------------
# Determine whether specified table exists in database
# ----------------------------------------------------------------------------
sub _tableexists {
  my $dbs = shift; # DBI handle or DB file path
  my $tbl = shift; # Table name

  my $dbh;
  ## If $dbs is a DBI handle, use that handle for database access,
  ## otherwise assume it is the path to an SQLite DB file and attempt
  ## to open it.
  if (ref($dbs) eq 'DBI::db') {
    $dbh = $dbs;
  } else {
    my $dbf = $dbs;
    return 0 if not -f $dbf;
    $dbh = DBI->connect("dbi:SQLite:$dbf",'','', {PrintError => 0,
						  RaiseError => 0});
    return 0 if not defined $dbh;
  }
  ## Determine whether named table exists
  my $slc = "SELECT NAME FROM sqlite_master WHERE TYPE='table' ".
            "AND NAME='$tbl'";
  my $a = $dbh->selectrow_arrayref($slc);
  # Close database connection if it was opened in this function
  $dbh->disconnect() if not ref($dbs) eq 'DBI::db';
  return (defined $a)?(@$a > 0):0;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Database - Perl module providing an interface to an SQLite
database

=head1 SYNOPSIS

  use File::Properties::Database;

  my $db = File::Properties::Database->new('dbfile.db');
  $db->definetable('TableName', ['Col1 INTEGER','Col2 TEXT']);
  $db->insert('TableName', {'Data' => ['1234', 'ABCD']});
  my $ra = $db->retrieve('TableName', {'ReturnType' => 'Array',
	                               'FirstRow' => 1,
                                       'Where' => {'Col1' => '1234'}});

=head1 ABSTRACT

  File::Properties::Database is a Perl module providing a simplified
  interface to an SQLite database.

=head1 DESCRIPTION

  File::Properties::Database provides a simplified interface to a
  SQLite database. The following methods are provided.

=over 4

=item B<new>

  my $db = File::Properties::Database->new($path, $options);

Constructs a new File::Properties::Database object. The $path
parameter specifies the path to an SQLite DB file and the optional
$options hash may have the following entries:

=over 8

=item {'NoCreate' => 1}

The DB file $path should not be created if it does not already exist.

=item {'ReadOnly' => 0}

The DB file should be opened in read-only mode.

=back

=item B<opts>

  my $opt = $db->opts;

Access the options specified at initialisation

=item B<dbi>

  my $dbi = $db->dbi;

Access the DBI object used by File::Properties::Database object $db.

=item B<definedcolumns>

  my $dc = $db->definedcolumns('TableName');

Get the an array of column names for the specified table.

=item B<sql>

  $db->sql('CREATE TABLE tablename (Field1 INTEGER, Field2 TEXT)');

Execute an SQL statement string.

=item B<definetable>

  $db->definetable('TableName', ['Col1 INTEGER','Col2 TEXT']);

Define a table, which will be created if it does not already
exist. Existing tables must also be defined using this method to
provide information required by a number of other methods.

=item B<insert>

  $db->insert('TableName', {'Columns' => ['Col1', 'Col2'],
                            'Data' => ['1234', 'ABCD']});
  $db->insert('TableName', {'Columns' => ['Col1', 'Col2'],
                            'Data' => [['1234', 'ABCD'],
                                       ['9876', 'DEFG']]});
  $db->insert('TableName', {'Data' => {'Col1' => '1234',
                                       'Col2' => 'ABCD'}});
  $db->insert('TableName', {'Data' => {'Col1' => ['1234', '9876'],
                                       'Col2' => ['ABCD', 'DEFG']}});

Insert one or more rows into the specified table.

=item B<update>

  $db->update('TableName', {'Data' => {'Col2' => 'Abcd'},
                            'Where' => 'Col1="1234"'});

Update one or more rows in the specified table.

=item B<retrieve>

  my $row = $db->retrieve('TableName', {'ReturnType' => 'Array',
	                                'FirstRow' => 1,
                                        'Where' => {'Col1' => '1234'}});
  my $rows = $db->retrieve('TableName', {'ReturnType' => 'Array',
                                        'Where' => {'Col1' => '1234'}});
  my $rows = $db->retrieve('TableName', {'ReturnType' => 'Hash',
                                        'Where' => {'Col1' => '1234'}});

Retrieve one or more rows from the specified table.

=item B<remove>

  $db->remove('TableName', {'Where' => {'Col1' => '1234'}});
  $db->remove('TableName', {'RemoveAll' => 1});

Remove specified rows from the specified table.

=item B<tables>

  my $tables = $db->tables;

Get names of tables in database.

=item B<columns>

  my $cols = $db->columns('TableName');

Get names of columns in specified table.

=item B<tableexists>

  my $exist = $db->tableexists('TableName');

Determine whether specified table exists.

=back

=head1 SEE ALSO

L<DBI>, L<DBD::SQLite>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
