# ----------------------------------------------------------------------------
#
# This module supports caching of data in an SQL database. Once the
# cache table format has been defined, a simple interface is available
# for inserting and retrieving data from the cache.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 4 November 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Cache;
our $VERSION = 0.01;

use File::Properties::Error;
use File::Properties::Database;
use base qw(File::Properties::Database);

require 5.005;
use strict;
use warnings;
use Error qw(:try);


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $dbfp = shift; # Database file path
  my $opts = shift; # Options hash

  # Initialisation for base
  $self->SUPER::_init($dbfp, $opts);
  # Initialise hash recording cache table information
  $self->{'ctbl'} = {};
  ## Initialise cache persistent metadata table
  if (not $self->tableexists('FilePropertiesCacheMetaData')) {
    $self->definetable('FilePropertiesCacheMetaData',
		      ['Attribute TEXT', 'Value TEXT']);
    $self->cmetadata('File::Properties::Cache::Version', $VERSION);
  }
}


# ----------------------------------------------------------------------------
# Define cache table
# ----------------------------------------------------------------------------
sub define {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $cols = shift; # Array of column specifications of form: Name Type
  my $opts = shift; # Define options

  # Set flag indicating whether insertion date column and an
  # associated trigger should be added to the table
  my $dtrg = (defined $opts and defined $opts->{'IncludeInsertDate'})?
    $opts->{'IncludeInsertDate'}:0;
  # Make record of insertion date flag, and initialise properties hash
  # for new table
  $self->{'ctbl'}->{$tbnm} = {'dtrg' => $dtrg, 'props' => {}};
  ## If table does not exist, initialise it
  if (!$self->tableexists($tbnm)) {
    # Add insertion date column to table definition if flag set
    push @$cols, 'InsertDate DATE' if ($dtrg);
    # Define the database table
    $self->definetable($tbnm, $cols);
    # Create the insertion date trigger if flag set
    $self->createinsertdatetrigger($tbnm, 'InsertDate') if ($dtrg);
    # Create a table version entry in the persistent metadata if
    # details provided
    $self->cmetadata($opts->{'TableVersion'}->[0],$opts->{'TableVersion'}->[1])
      if defined $opts and defined $opts->{'TableVersion'};
  }
}


# ----------------------------------------------------------------------------
# Create insertion date trigger
# ----------------------------------------------------------------------------
sub createinsertdatetrigger {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $tcol = shift; # Name of column for date insertion

  my $trgn = $tbnm . "InsertDate";
  my $sqlc = <<EOF;
CREATE TRIGGER IF NOT EXISTS $trgn AFTER INSERT ON $tbnm
BEGIN
  UPDATE $tbnm SET $tcol = STRFTIME('%Y-%m-%d','NOW')
    WHERE rowid = new.rowid;
END
EOF
  return $self->sql($sqlc);
}


# ----------------------------------------------------------------------------
# Insert a cache entry
# ----------------------------------------------------------------------------
sub cinsert {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $tbrw = shift; # Hash of column values to insert

  return $self->insert($tbnm, {'Data'=> $tbrw});
}


# ----------------------------------------------------------------------------
# Retrieve a cache entry
# ----------------------------------------------------------------------------
sub cretrieve {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $tkey = shift; # Hash of key columns and corresponding key values

  return $self->retrieve($tbnm, {'Where' => $tkey,
				 'FirstRow' => 1,
				 'ReturnType' => 'Hash'});
}


# ----------------------------------------------------------------------------
# Get (or set) cache properties (non-persistent metadata)
# ----------------------------------------------------------------------------
sub cproperties {
  my $self = shift;
  my $tbnm = shift; # Table name
  my $pnam = shift; # Property name

  $self->{'ctbl'}->{$tbnm}->{'props'}->{$pnam} = shift if (@_);
  return $self->{'ctbl'}->{$tbnm}->{'props'}->{$pnam};
}


# ----------------------------------------------------------------------------
# List of cache entries older than a specified number of days
# ----------------------------------------------------------------------------
sub expirelist {
   my $self = shift;
   my $tbnm = shift; # Table name
   my $nday = shift; # Expiry age in number of days

   ## Date based expiry is only possible if the table has an insertion
   ## date field with insertion trigger
   if ($self->{'ctbl'}->{$tbnm}->{'dtrg'}) {
     return $self->retrieve($tbnm,
			    {'Where' =>
			     "julianday('NOW')-julianday(InsertDate)>$nday",
			     'ReturnType' => 'Array'});
   } else {
     return [];
   }
}


# ----------------------------------------------------------------------------
# Expire cache entries older than a specified number of days
# ----------------------------------------------------------------------------
sub expire {
   my $self = shift;
   my $tbnm = shift; # Table name
   my $nday = shift; # Expiry age in number of days

   ## Date based expiry is only possible if the table has an insertion
   ## date field with insertion trigger
   if ($self->{'ctbl'}->{$tbnm}->{'dtrg'}) {
     $self->remove($tbnm,{'Where' =>
                          "julianday('NOW') - julianday(InsertDate) > $nday"});
   }
}


# ----------------------------------------------------------------------------
# Get (or set) cache persistent metadata
# ----------------------------------------------------------------------------
sub cmetadata {
  my $self = shift;
  my $atrb = shift; # Attribute name

  # Attempt to retrieve the cache persistent metadata table entry
  # corresponding to the specified attribute name
  my $row = $self->retrieve('FilePropertiesCacheMetaData',
			    {'Where' => {'Attribute' => $atrb},
			     'FirstRow' => 1, 'ReturnType' => 'Array'});
  ## If a second argument is provided to the method, it is used as a
  ## new attribute value for the specified attribute name
  if (@_) {
    ## The second argument for the method is used as a new attribute
    ## value for the specified attribute name. If the table row for the
    ## attribute name exists, update the row, otherwise insert a new
    ## row.
    if (defined $row) {
      $self->update('FilePropertiesCacheMetaData',
		    {'Data' => {'Attribute' => $atrb, 'Value' => shift}});
    } else {
      $self->insert('FilePropertiesCacheMetaData',
		    {'Data' => {'Attribute' => $atrb, 'Value' => shift}});
    }
  } else {
    # If a new attribute value is not specified, return the current
    # value of the specified attribute, or undef if the attribute
    # entry does not exist
    return (defined $row)?$row->[1]:undef;
  }
}


# ----------------------------------------------------------------------------
# Determine whether array includes the specified value
# ----------------------------------------------------------------------------
sub _inarray {
  my $aref = shift;
  my $eval = shift;

  my $hash = {};
  my $a;
  foreach $a (@$aref) {
    $hash->{$a} = 1;
  }
  return $hash->{$eval};
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Cache - Perl module providing a cache for use by
objects in the File::Properties hierarchy

=head1 SYNOPSIS

  use File::Properties::Cache;

  my $fpc = File::Properties::Cache->new('dbfile.db');
  $fpc->define('CacheTableName', ['Col1 INTEGER','Col2 TEXT'],
               {'IncludeInsertDate' => 1,
                'TableVersion' => ['CacheTableVersion', 0.01]});
  $fpc->cinsert('CacheTableName', {'Col1' => 1234, 'COl2' => 'ABCD'});
  my $row = $fpc->cretrieve('CacheTableName', {'Col1' => 1234});


=head1 ABSTRACT

File::Properties::Cache is a Perl module providing a cache for use by
objects in the File::Properties hierarchy.

=head1 DESCRIPTION

File::Properties::Cache provides a cache for use by objects in the
File::Properties hierarchy. The following methods are provided.

=over 4

=item B<new>

  my $db = File::Properties::Cache->new($path, $options);

Constructs a new File::Properties::Cache object. The $path parameter
specifies the path to an SQLite DB file and the optional $options hash
is passed to the constructor for the File::Properties::Database class
from which this class is derived.

=item B<define>

  $fpc->define($tablename, $options);

Define a cache table. The optional $options hash may have the
following entries:

=over 8

=item {'IncludeInsertDate' => 1}

Request an additional column representing row insertion date, together
with an associated trigger automatically setting its value.

=item {'TableVersion' => [$name, $value]}

Specify an attribute name and value to be inserted into the persistent
metadata table.

=back

=item B<createinsertdatetrigger>

  $db->createinsertdatetrigger(CacheTableName', 'ColumnName');

Create a trigger for inserting the current date into the named field
of the named table on insertion into that table.

=item B<cinsert>

  $fpc->cinsert('CacheTableName', {'Col1' => 1234,'COl2' => 'ABCD'});

Insert a cache table entry.

=item B<cretrieve>

   my $row = $fpc->cretrieve('CacheTableName', {'Col1' => 1234});

Retrieve a cache table entry.

=item B<cproperties>

   $fpc->cproperties('CacheTableName', 'PropName', 'PropValue');

Get or set a cache property name/value pair for the specified table.

=item B<expirelist>

   my $elst = $fpc->expirelist('CacheTableName', 365);

Get a list of cache entries older than a specified number of days.

=item B<expire>

   $fpc->expire('CacheTableName', 365);

Remove cache entries older than a specified number of days.

=item B<cmetadata>

   $fpc->cmetadata('AttribName', 'AttribValue');

Get or set cache persistent metadata.

=back

=head1 SEE ALSO

L<File::Properties::Database>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
