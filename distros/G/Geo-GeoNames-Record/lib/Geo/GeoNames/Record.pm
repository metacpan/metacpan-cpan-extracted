package Geo::GeoNames::Record;

=head1 NAME

Geo::GeoNames::Record - Perl module for handling GeoNames.org records

=head1 DESCRIPTION

Provides a Perl extension for handling GeoNames.org records.

=head1 AUTHOR

Xiangrui Meng <mengxr@stanford.edu>

=head1 LINKS

GoeNames:
http://www.geonames.org/

This package is part of the metadata generation and remediation suite:
http://cads.stanford.edu/

=head1 COPYRIGHT

Copyright (C) 2009 by Xiangrui Meng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.11';

use Carp ();
use Data::Dumper ();
use File::Basename ();
use Storable ();

## overloadings ##

use overload 
  q("") => \&as_string,
  q(eq) => \&op_eq,
  q(==) => \&op_eq,
  ;

## public static variables ##

our @fields = qw( geonameid name asciiname alternatenames latitude
		  longitude feature_class feature_code country_code cc2
		  admin1_code admin2_code admin3_code admin4_code
		  population elevation gtopo30 timezone modification_date
	       );

our $n_fields = @fields;

=head1 VARIABLES

Each Geo::GeoNames::Record instance has the following fields defined in
http://download.geonames.org/export/dump/readme.txt:

geonameid         : integer id of record in geonames database

name              : name of geographical point (utf8) varchar(200)

asciiname         : name of geographical point in plain ascii characters, varchar(200)

alternatenames    : alternatenames, comma separated varchar(4000) (varchar(5000) for SQL Server)

latitude          : latitude in decimal degrees (wgs84)

longitude         : longitude in decimal degrees (wgs84)

feature_class     : see http://www.geonames.org/export/codes.html, char(1)

feature_code      : see http://www.geonames.org/export/codes.html, varchar(10)

country_code      : ISO-3166 2-letter country code, 2 characters

cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 60 characters

admin1_code       : fipscode (subject to change to iso code), isocode for the us and ch, see file admin1Codes.txt for display names of this code; varchar(20)

admin2_code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 

admin3_code       : code for third level administrative division, varchar(20)

admin4_code       : code for fourth level administrative division, varchar(20)

population        : bigint (4 byte int) 

elevation         : in meters, integer

gtopo30           : average elevation of 30'x30' (ca 900mx900m) area in meters, integer

timezone          : the timezone id (see file timeZone.txt)

modification_date : date of last modification in yyyy-MM-dd format

For each member variable, we defined a member function to save the curly
brackets from your code.  For example, you can get the value of
$rec->{geonameid} by

    $rec->geonameid;

or set its value by

    $rec->geonameid = 123456;

=cut

## public variables and corresponding member functions ##

my @_PUBLIC_VARIABLES = @fields;

foreach (@_PUBLIC_VARIABLES)
{
  eval "sub $_ : lvalue { shift->{$_}; }";
}

=head1 VARIABLE ALIASES

We defined several aliases as followed: 

id                : geonameid;

coordinates       : (latitude,longitude);

=cut

my %_PUBLIC_VARIABLE_ALIASES = ( id => 'geonameid' );

foreach (keys %_PUBLIC_VARIABLE_ALIASES)
{
  eval "sub $_ : lvalue { shift->{$_PUBLIC_VARIABLE_ALIASES{$_}}; }";
}

sub coordinates : lvalue
{
  my $self = shift;
  ($self->{latitude}, $self->{longitude});
}

## private static variables ##

my $_admins_loaded;
my $_admin_code_to_record;

=head1 METHODS

=over

=item new()

Constructor for Geo::GeoNames::Record. 

    my $rec = Geo::GeoNames::Record->new();

It returns an empty Geo::GeoNames::Record object.

    my $rec = Geo::GeoNames::Record->new( $str_record );

You may also pass a GeoNames record string. It returns the corresponding
Geo::GeoNames::Record object or undef if the input is incorrect.

=cut

sub new
{
  my $class = shift;

  my $self = bless {}, $class;

  @{$self}{@fields} = ();

  if ( @_ )
  {
    $self->parse( @_ );
  }

  return $self;
}

=item parse()

    $rec->parse( $line );

Parses a record line from a GeoNames.org data file and updates the current
object.

=cut

sub parse
{
  my ( $self, $str ) = @_;

  chomp($str);

  my @data = split /\t/, $str;

  if ( @data == $n_fields )
  {
    for ( my $i = 0; $i < $n_fields; $i++ )
    {
      $self->{$fields[$i]} = $data[$i];
    }
  }
  else
  {
    Carp::croak "Wrong number of GeoNames fields";
  }

  return $self;
}

=item names()

Returns all unique names.

=cut

sub names
{
  my $self = shift;

  my %saw;
  @saw{ ( $self->{name}, $self->{asciiname}, split(/,/, $self->{alternatenames}) ) } = ();

  return keys %saw;
}

=item has_name( $name )

Returns true if the record has a name matching the $name argument.

=cut

sub has_name
{
  my ($self, $name) = @_;
  return ( grep { $_ eq $name; } $self->names() ) ? 1 : 0;
}

=item country()

Return the country of the record as a Geo::GeoNames::Record object.

=cut

sub country
{
  _load_admins() unless $_admins_loaded;

  my $self = shift;
    
  if ( $self->{country_code} && exists( $_admin_code_to_record->{$self->{country_code}} ) )
  {
    return $_admin_code_to_record->{$self->{country_code}};
  }
    
  return;
}

=item admin1()

Return the admin1 of the record as a Geo::GeoNames::Record object.

=cut

sub admin1
{
  _load_admins() unless $_admins_loaded;

  my $self = shift;
    
  if ( $self->{admin1_code} )
  {
    my $admin1_key = $self->{country_code} . "." . $self->{admin1_code};

    if ( exists( $_admin_code_to_record->{$admin1_key} ) )
    {
      return $_admin_code_to_record->{$admin1_key};
    }
  }

  return;
}

=item admin2

Return the admin2 of the record as a Geo::GeoNames::Record object.

=cut

sub admin2
{
  _load_admins() unless $_admins_loaded;

  my $self = shift;

  if ( $self->{admin2_code} )
  {
    my $admin2_key = $self->{country_code} . "." . $self->{admin1_code} . "." . $self->{admin2_code};

    if ( exists( $_admin_code_to_record->{$admin2_key} ) )
    {
      return $_admin_code_to_record->{$admin2_key};
    }
  }

  return;
}

=item as_string()

Convert the record to a GeoNames.org record line.

=cut

sub as_string
{
  my $self = shift;

  return join( "\t", @{$self}{@fields} );
}

=item op_eq()

Compare records based on their geonameids.

=cut

sub op_eq
{
  return ($_[0]->id eq $_[1]->id);
}

=item is_country()

Return true if the record is a country.

=cut

sub is_country
{
  my $self = shift;
  return ( $self->{feature_class} eq 'A' ) && ( $self->{feature_code} =~ /^P/ );
}

=item is_admin1()

Return true if the record is a primary administrative division.

=cut

sub is_admin1
{
  my $self = shift;
  return ( $self->{feature_class} eq 'A' ) && ( $self->{feature_code} eq 'ADM1' );
}

=item is_admin2()

Return true if the record is a second-order administrative division.

=cut

sub is_admin2
{
  my $self = shift;
  return ( $self->{feature_class} eq 'A' ) && ( $self->{feature_code} eq 'ADM2' );
}

## private functions ##

# load data files for decoding country_code, admin1_code and admin2_code

sub _load_admins
{
  use File::HomeDir;
  use File::Spec;
  
  my $admins_filename = File::Spec->catfile( File::HomeDir->my_home(), 
					     ".Geo-GeoNames-Record", 
					     "admin_code_to_record.hash" );
  
  if( -e $admins_filename )
  {
    $_admin_code_to_record = Storable::retrieve( $admins_filename );
    $_admins_loaded = 1;
  }
  else
  {
    Carp::croak( "$admins_filename doesn't exist. Please run gn_update_admins first." );
  }
}

=back

=cut

1;
__END__
