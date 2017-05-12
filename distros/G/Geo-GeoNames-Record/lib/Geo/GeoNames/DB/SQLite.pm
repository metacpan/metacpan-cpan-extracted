package Geo::GeoNames::DB::SQLite;

=head1 NAME

Geo::GeoNames::DB::SQLite - Perl module for handling GeoNames.org data stored in a SQLite database. 

=head1 SYNOPSIS

use Geo::GeoNames::DB::SQLite;

my $dbh = Geo::GeoNames::DB::SQLite->connect( "geoname.sqlite" );

my @records = $dbh->query( "Beijing" );

print join( "\n", @records ) . "\n";

=head1 DESCRIPTION

Geo::GeoNames::DB::SQLite is a Perl module to store GeoNames.org records,
which tries to balance the trade-offs between the memory cost of using a
Perl hash of Geo::GeoNames::Record objects and the speed of using using a
GeoNames.org data file.

=head1 AUTHOR

Xiangrui Meng <mengxr@stanford.edu>

=head1 COPYRIGHT

Copyright (C) 2010 by Xiangrui Meng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.008007;
use strict;
use warnings;

use Carp ();
use Data::Dumper ();

use DBI;

use Geo::GeoNames::Record;

use base qw(DBI::db);

=head1 METHODS

=over

=item connect()

Constructor.

    my $dbh = Geo::GeoNames::DB::SQLite->connect( $dbname );

=cut

sub connect
{
  my ( $class, $dbname ) = @_;
    
  $class = (ref $class) || $class;

  my $self = DBI->connect( "dbi:SQLite:dbname=$dbname", "", "", {AutoCommit=>0} )
    or Carp::carp( $DBI::errstr );

  $self->{sqlite_unicode} = 1;

  bless $self, $class;

  $self->_init;
    
  return $self;
}

=item insert()

Insert or replace GeoNames.org records. It accepts Geo::GeoNames::Record
and Geo::GeoNames::File object(s) as input.

Always remember to commit changes by

    $db->commit;

=cut

sub insert
{
  my $self = shift;

  while ( my $data = shift )
  {
    if ( ref( $data ) eq "Geo::GeoNames::Record" )
    {
      $self->_insert( $data );
    }
    elsif ( ref( $data ) eq "Geo::GeoNames::File" )
    {
      while ( my $rec = $data->next() )
      {
	$self->_insert( $rec );
      }
    }
    elsif ( ref( $data ) eq "ARRAY" )
    {
      foreach ( @$data )
      {
	$self->_insert( $_ );
      }
    }
    else
    {
      Carp::carp( "Cannot recgonize input type!" );
    }
  }

  return $self;
}

# insert or replace a single Geo::GeoNames::Record object

sub _insert
{
  my ( $self, $record ) = @_;
    
  if ( ref( $record ) eq "Geo::GeoNames::Record" )
  {
    $self->do( "INSERT OR REPLACE INTO geoname VALUES (" . join( ", ", map( $self->quote($_), @{$record}{@Geo::GeoNames::Record::fields} ) ) . ")" );
	
    foreach ( $record->names() )
    {
      $self->do( "INSERT OR REPLACE INTO alternate_name (geonameid, alternate_name) VALUES ( $record->{geonameid}, " . $self->quote($_) . ")" );
    }
  }
  else
  {
    Carp::carp( "Wrong type in insertion!" );
  }
  
  return $self;
}

=item select_all_records()

Select all records. (slow)

=cut

sub select_all_records
{
  my $self = shift;

  my $records = $self->selectall_hashref( "SELECT * FROM geoname", "geonameid" );

  return map( bless($_, "Geo::GeoNames::Record"), values(%$records) );
}

=item select_all_alternate_names()

Select all the alternate names and corresponding geonameids.

=cut

sub select_all_alternate_names
{
  my $self = shift;

  return $self->selectall_arrayref( "SELECT alternate_name, geonameid FROM alternate_name" );
}

=item query()

Query function.

    my @records = $dbh->query( $geonameid );
    my @records = $dbh->query( $name1, $name2 );

=cut

sub query
{
  my $self = shift;

  my @records;

  foreach my $word (@_)
  {
    if ( $word =~ /^\d+$/ )
    {
      push @records, $self->_query_id( $word );
    }
    else
    {
      push @records, $self->_query_name( $word );
    }
  }

  return @records;
}

sub _query_id
{
  my ( $self, $id ) = @_;
    
  my $record = $self->selectrow_hashref( "SELECT * FROM geoname where geonameid = $id" );

  if( $record )
  {
    bless $record, "Geo::GeoNames::Record";
  }

  return $record;
}

sub _query_name
{
  my ( $self, $name ) = @_;

  $name = $self->quote($name);

  my $records = $self->selectall_hashref( "SELECT * FROM geoname WHERE geonameid IN (SELECT DISTINCT geonameid from alternate_name where alternate_name = $name)", "geonameid" );

  return map( bless($_, "Geo::GeoNames::Record"), values(%$records) );
}


# check and build database structure

sub _init
{
  my $self = shift;
  
  # check tables
  
  my @tbl_names = map( $_->[0], 
		       @{$self->selectall_arrayref("SELECT name FROM sqlite_master WHERE type='table'")} 
		     );
  
  unless( grep {$_ eq "geoname";} @tbl_names ) 
  { 
    $self->do( "CREATE TABLE geoname (geonameid INTEGER NOT NULL, name TEXT NOT NULL, asciiname TEXT NOT NULL, alternatenames TEXT, latitude REAL, longitude REAL, feature_class TEXT, feature_code TEXT, country_code TEXT, cc2 TEXT, admin1_code TEXT, admin2_code TEXT, admin3_code TEXT, admin4_code TEXT, population INTEGER, elevation INTEGER, gtopo30 INTEGER, timezone TEXT, modification_date TEXT, PRIMARY KEY (geonameid) )" );
  } 
  
  unless( grep {$_ eq "alternate_name";} @tbl_names ) 
  { 
    $self->do( "CREATE TABLE alternate_name (geonameid INTEGER NOT NULL, alternate_name TEXT NOT NULL, PRIMARY KEY (geonameid, alternate_name) )" ); 
  }
  
  # check index

  my @idx_names = map( $_->[0],
		       @{$self->selectall_arrayref("SELECT name FROM sqlite_master WHERE type='index'")}
		     );

  unless( grep {$_ eq "alternate_name_idx";} @idx_names )
  {
    $self->do( "CREATE INDEX alternate_name_idx ON alternate_name (alternate_name)" );
  }

  return $self;
}

=back

=cut

1;
__END__
