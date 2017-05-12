package Geo::TigerLine::Record::7;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'source' => {
                             'len' => 1,
                             'beg' => 21,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'Source or First Source Code to Update',
                             'end' => 21,
                             'fmt' => 'L',
                             'field' => 'source'
                           },
               'lalat' => {
                            'len' => 9,
                            'beg' => 65,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'N',
                            'description' => 'Latitude',
                            'end' => 73,
                            'fmt' => 'R',
                            'field' => 'lalat'
                          },
               'version' => {
                              'len' => 4,
                              'beg' => 2,
                              'bv' => 'No',
                              'fieldnum' => 2,
                              'type' => 'N',
                              'description' => 'Version Number',
                              'end' => 5,
                              'fmt' => 'L',
                              'field' => 'version'
                            },
               'lalong' => {
                             'len' => 10,
                             'beg' => 55,
                             'bv' => 'Yes',
                             'fieldnum' => 8,
                             'type' => 'N',
                             'description' => 'Longitude',
                             'end' => 64,
                             'fmt' => 'R',
                             'field' => 'lalong'
                           },
               'file' => {
                           'len' => 5,
                           'beg' => 6,
                           'bv' => 'No',
                           'fieldnum' => 3,
                           'type' => 'N',
                           'description' => 'File Code',
                           'end' => 10,
                           'fmt' => 'L',
                           'field' => 'file'
                         },
               'land' => {
                           'len' => 10,
                           'beg' => 11,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'Landmark Identification Number',
                           'end' => 20,
                           'fmt' => 'R',
                           'field' => 'land'
                         },
               'laname' => {
                             'len' => 30,
                             'beg' => 25,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Landmark Name',
                             'end' => 54,
                             'fmt' => 'L',
                             'field' => 'laname'
                           },
               'filler' => {
                             'len' => 1,
                             'beg' => 74,
                             'bv' => 'Yes',
                             'fieldnum' => 10,
                             'type' => 'A',
                             'description' => 'Filler (to make even character count)',
                             'end' => 74,
                             'fmt' => 'L',
                             'field' => 'filler'
                           },
               'rt' => {
                         'len' => 1,
                         'beg' => 1,
                         'bv' => 'No',
                         'fieldnum' => 1,
                         'type' => 'A',
                         'description' => 'Record Type',
                         'end' => 1,
                         'fmt' => 'L',
                         'field' => 'rt'
                       },
               'cfcc' => {
                           'len' => 3,
                           'beg' => 22,
                           'bv' => 'No',
                           'fieldnum' => 6,
                           'type' => 'A',
                           'description' => 'Census Feature Class Code',
                           'end' => 24,
                           'fmt' => 'L',
                           'field' => 'cfcc'
                         }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'land',
                 'source',
                 'cfcc',
                 'laname',
                 'lalong',
                 'lalat',
                 'filler'
               );


assert(keys %Data_Dict == @Data_Fields);

# Turn the data dictionary into class data
__PACKAGE__->mk_classdata('Fields');
__PACKAGE__->mk_classdata('Dict');
__PACKAGE__->mk_classdata('Pack_Tmpl');

__PACKAGE__->Dict(\%Data_Dict);
__PACKAGE__->Fields(\@Data_Fields);

# Generate a pack template for parsing and turn it into class data.
my $pack_tmpl = join ' ', map { "A$_" } map { $_->{len} } 
                                          @Data_Dict{@Data_Fields};
__PACKAGE__->Pack_Tmpl($pack_tmpl);

# Generate accessors for each data field
foreach my $def (@Data_Dict{@Data_Fields}) {
    __PACKAGE__->mk_accessor($def);
}


=pod

=head1 NAME

Geo::TigerLine::Record::7 - TIGER/Line 2006 Landmark Features

=head1 SYNOPSIS

  use Geo::TigerLine::Record::7;

  @records = Geo::TigerLine::Record::7->parse_file($fh);
  @records = Geo::TigerLine::Record::7->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::7->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->land();
  $record->source();
  $record->cfcc();
  $record->laname();
  $record->lalong();
  $record->lalat();
  $record->filler();


=head1 DESCRIPTION

This is a class representing record type 7 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 7 files and turn them
into objects.

This is intended as an intermediate format between pulling the raw
data out of the simplistic TIGER/Line data files into something more
sophisticated (a process you should only have to do once).  As such,
it's not very fast, but its careful, easy to use and performs some
verifications on the data being read.

As this class is autogenerated by mk_parsers, think before you modify this
file.  It's OO, so consider sub-classing instead.


=head2 Accessors

These are simple get/set accessors for each field of a record
generated from the TIGER/Line 2006 data dictionary.  They perform some
data validation.

=over 4

=item B<rt>

    $data = $record->rt();
    $record->rt($data);

Record Type.  

Expects alphanumeric data of no more than 1 characters.  $data cannot be blank 
and should be left justified.


=item B<version>

    $data = $record->version();
    $record->version($data);

Version Number.  

Expects numeric data of no more than 4 characters.  $data cannot be blank 
and should be left justified.


=item B<file>

    $data = $record->file();
    $record->file($data);

File Code.  

Expects numeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<land>

    $data = $record->land();
    $record->land($data);

Landmark Identification Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<source>

    $data = $record->source();
    $record->source($data);

Source or First Source Code to Update.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<cfcc>

    $data = $record->cfcc();
    $record->cfcc($data);

Census Feature Class Code.  

Expects alphanumeric data of no more than 3 characters.  $data cannot be blank 
and should be left justified.


=item B<laname>

    $data = $record->laname();
    $record->laname($data);

Landmark Name.  

Expects alphanumeric data of no more than 30 characters.  $data can be blank 
and should be left justified.


=item B<lalong>

    $data = $record->lalong();
    $record->lalong($data);

Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lalat>

    $data = $record->lalat();
    $record->lalat($data);

Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<filler>

    $data = $record->filler();
    $record->filler($data);

Filler (to make even character count).  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 7 - Landmark Features
    
    Field BV Fmt Type Beg End Len Description
    RT      No  L A  1  1  1 Record Type
    VERSION No  L N  2  5  4 Version Number
    FILE    No  L N  6 10  5 File Code
    LAND    No  R N 11 20 10 Landmark Identification Number
    SOURCE  Yes L A 21 21  1 Source or First Source Code to Update
    CFCC    No  L A 22 24  3 Census Feature Class Code
    LANAME  Yes L A 25 54 30 Landmark Name
    LALONG  Yes R N 55 64 10 Longitude
    LALAT   Yes R N 65 73  9 Latitude
    FILLER  Yes L A 74 74  1 Filler (to make even character count)
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
