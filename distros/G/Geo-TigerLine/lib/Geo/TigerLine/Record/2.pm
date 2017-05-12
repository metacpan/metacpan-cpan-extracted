package Geo::TigerLine::Record::2;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'long1' => {
                            'len' => 10,
                            'beg' => 19,
                            'bv' => 'No',
                            'fieldnum' => 5,
                            'type' => 'N',
                            'description' => 'Point 1, Longitude',
                            'end' => 28,
                            'fmt' => 'R',
                            'field' => 'long1'
                          },
               'long8' => {
                            'len' => 10,
                            'beg' => 152,
                            'bv' => 'Yes',
                            'fieldnum' => 19,
                            'type' => 'N',
                            'description' => 'Point 8, Longitude',
                            'end' => 161,
                            'fmt' => 'R',
                            'field' => 'long8'
                          },
               'long4' => {
                            'len' => 10,
                            'beg' => 76,
                            'bv' => 'Yes',
                            'fieldnum' => 11,
                            'type' => 'N',
                            'description' => 'Point 4, Longitude',
                            'end' => 85,
                            'fmt' => 'R',
                            'field' => 'long4'
                          },
               'lat5' => {
                           'len' => 9,
                           'beg' => 105,
                           'bv' => 'Yes',
                           'fieldnum' => 14,
                           'type' => 'N',
                           'description' => 'Point 5, Latitude',
                           'end' => 113,
                           'fmt' => 'R',
                           'field' => 'lat5'
                         },
               'long9' => {
                            'len' => 10,
                            'beg' => 171,
                            'bv' => 'Yes',
                            'fieldnum' => 21,
                            'type' => 'N',
                            'description' => 'Point 9, Longitude',
                            'end' => 180,
                            'fmt' => 'R',
                            'field' => 'long9'
                          },
               'lat8' => {
                           'len' => 9,
                           'beg' => 162,
                           'bv' => 'Yes',
                           'fieldnum' => 20,
                           'type' => 'N',
                           'description' => 'Point 8, Latitude',
                           'end' => 170,
                           'fmt' => 'R',
                           'field' => 'lat8'
                         },
               'long7' => {
                            'len' => 10,
                            'beg' => 133,
                            'bv' => 'Yes',
                            'fieldnum' => 17,
                            'type' => 'N',
                            'description' => 'Point 7, Longitude',
                            'end' => 142,
                            'fmt' => 'R',
                            'field' => 'long7'
                          },
               'lat4' => {
                           'len' => 9,
                           'beg' => 86,
                           'bv' => 'Yes',
                           'fieldnum' => 12,
                           'type' => 'N',
                           'description' => 'Point 4, Latitude',
                           'end' => 94,
                           'fmt' => 'R',
                           'field' => 'lat4'
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
               'lat6' => {
                           'len' => 9,
                           'beg' => 124,
                           'bv' => 'Yes',
                           'fieldnum' => 16,
                           'type' => 'N',
                           'description' => 'Point 6, Latitude',
                           'end' => 132,
                           'fmt' => 'R',
                           'field' => 'lat6'
                         },
               'lat7' => {
                           'len' => 9,
                           'beg' => 143,
                           'bv' => 'Yes',
                           'fieldnum' => 18,
                           'type' => 'N',
                           'description' => 'Point 7, Latitude',
                           'end' => 151,
                           'fmt' => 'R',
                           'field' => 'lat7'
                         },
               'long6' => {
                            'len' => 10,
                            'beg' => 114,
                            'bv' => 'Yes',
                            'fieldnum' => 15,
                            'type' => 'N',
                            'description' => 'Point 6, Longitude',
                            'end' => 123,
                            'fmt' => 'R',
                            'field' => 'long6'
                          },
               'long5' => {
                            'len' => 10,
                            'beg' => 95,
                            'bv' => 'Yes',
                            'fieldnum' => 13,
                            'type' => 'N',
                            'description' => 'Point 5, Longitude',
                            'end' => 104,
                            'fmt' => 'R',
                            'field' => 'long5'
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
               'lat2' => {
                           'len' => 9,
                           'beg' => 48,
                           'bv' => 'Yes',
                           'fieldnum' => 8,
                           'type' => 'N',
                           'description' => 'Point 2, Latitude',
                           'end' => 56,
                           'fmt' => 'R',
                           'field' => 'lat2'
                         },
               'long10' => {
                             'len' => 10,
                             'beg' => 190,
                             'bv' => 'Yes',
                             'fieldnum' => 23,
                             'type' => 'N',
                             'description' => 'Point 10, Longitude',
                             'end' => 199,
                             'fmt' => 'R',
                             'field' => 'long10'
                           },
               'lat9' => {
                           'len' => 9,
                           'beg' => 181,
                           'bv' => 'Yes',
                           'fieldnum' => 22,
                           'type' => 'N',
                           'description' => 'Point 9, Latitude',
                           'end' => 189,
                           'fmt' => 'R',
                           'field' => 'lat9'
                         },
               'lat10' => {
                            'len' => 9,
                            'beg' => 200,
                            'bv' => 'Yes',
                            'fieldnum' => 24,
                            'type' => 'N',
                            'description' => 'Point 10, Latitude',
                            'end' => 208,
                            'fmt' => 'R',
                            'field' => 'lat10'
                          },
               'long2' => {
                            'len' => 10,
                            'beg' => 38,
                            'bv' => 'Yes',
                            'fieldnum' => 7,
                            'type' => 'N',
                            'description' => 'Point 2, Longitude',
                            'end' => 47,
                            'fmt' => 'R',
                            'field' => 'long2'
                          },
               'lat1' => {
                           'len' => 9,
                           'beg' => 29,
                           'bv' => 'No',
                           'fieldnum' => 6,
                           'type' => 'N',
                           'description' => 'Point 1, Latitude',
                           'end' => 37,
                           'fmt' => 'R',
                           'field' => 'lat1'
                         },
               'tlid' => {
                           'len' => 10,
                           'beg' => 6,
                           'bv' => 'No',
                           'fieldnum' => 3,
                           'type' => 'N',
                           'description' => 'TIGER/Line ID, Permanent 1-Cell Number',
                           'end' => 15,
                           'fmt' => 'R',
                           'field' => 'tlid'
                         },
               'rtsq' => {
                           'len' => 3,
                           'beg' => 16,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'Record Sequence Number',
                           'end' => 18,
                           'fmt' => 'R',
                           'field' => 'rtsq'
                         },
               'lat3' => {
                           'len' => 9,
                           'beg' => 67,
                           'bv' => 'Yes',
                           'fieldnum' => 10,
                           'type' => 'N',
                           'description' => 'Point 3, Latitude',
                           'end' => 75,
                           'fmt' => 'R',
                           'field' => 'lat3'
                         },
               'long3' => {
                            'len' => 10,
                            'beg' => 57,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'N',
                            'description' => 'Point 3, Longitude',
                            'end' => 66,
                            'fmt' => 'R',
                            'field' => 'long3'
                          }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'tlid',
                 'rtsq',
                 'long1',
                 'lat1',
                 'long2',
                 'lat2',
                 'long3',
                 'lat3',
                 'long4',
                 'lat4',
                 'long5',
                 'lat5',
                 'long6',
                 'lat6',
                 'long7',
                 'lat7',
                 'long8',
                 'lat8',
                 'long9',
                 'lat9',
                 'long10',
                 'lat10'
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

Geo::TigerLine::Record::2 - TIGER/Line 2006 Complete Chain Shape Coordinates

=head1 SYNOPSIS

  use Geo::TigerLine::Record::2;

  @records = Geo::TigerLine::Record::2->parse_file($fh);
  @records = Geo::TigerLine::Record::2->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::2->new(\%fields);

  $record->rt();
  $record->version();
  $record->tlid();
  $record->rtsq();
  $record->long1();
  $record->lat1();
  $record->long2();
  $record->lat2();
  $record->long3();
  $record->lat3();
  $record->long4();
  $record->lat4();
  $record->long5();
  $record->lat5();
  $record->long6();
  $record->lat6();
  $record->long7();
  $record->lat7();
  $record->long8();
  $record->lat8();
  $record->long9();
  $record->lat9();
  $record->long10();
  $record->lat10();


=head1 DESCRIPTION

This is a class representing record type 2 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 2 files and turn them
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


=item B<tlid>

    $data = $record->tlid();
    $record->tlid($data);

TIGER/Line ID, Permanent 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<rtsq>

    $data = $record->rtsq();
    $record->rtsq($data);

Record Sequence Number.  

Expects numeric data of no more than 3 characters.  $data cannot be blank 
and should be right justified.


=item B<long1>

    $data = $record->long1();
    $record->long1($data);

Point 1, Longitude.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<lat1>

    $data = $record->lat1();
    $record->lat1($data);

Point 1, Latitude.  

Expects numeric data of no more than 9 characters.  $data cannot be blank 
and should be right justified.


=item B<long2>

    $data = $record->long2();
    $record->long2($data);

Point 2, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat2>

    $data = $record->lat2();
    $record->lat2($data);

Point 2, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long3>

    $data = $record->long3();
    $record->long3($data);

Point 3, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat3>

    $data = $record->lat3();
    $record->lat3($data);

Point 3, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long4>

    $data = $record->long4();
    $record->long4($data);

Point 4, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat4>

    $data = $record->lat4();
    $record->lat4($data);

Point 4, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long5>

    $data = $record->long5();
    $record->long5($data);

Point 5, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat5>

    $data = $record->lat5();
    $record->lat5($data);

Point 5, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long6>

    $data = $record->long6();
    $record->long6($data);

Point 6, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat6>

    $data = $record->lat6();
    $record->lat6($data);

Point 6, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long7>

    $data = $record->long7();
    $record->long7($data);

Point 7, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat7>

    $data = $record->lat7();
    $record->lat7($data);

Point 7, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long8>

    $data = $record->long8();
    $record->long8($data);

Point 8, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat8>

    $data = $record->lat8();
    $record->lat8($data);

Point 8, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long9>

    $data = $record->long9();
    $record->long9($data);

Point 9, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat9>

    $data = $record->lat9();
    $record->lat9($data);

Point 9, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.


=item B<long10>

    $data = $record->long10();
    $record->long10($data);

Point 10, Longitude.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<lat10>

    $data = $record->lat10();
    $record->lat10($data);

Point 10, Latitude.  

Expects numeric data of no more than 9 characters.  $data can be blank 
and should be right justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 2 - Complete Chain Shape Coordinates
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L    A    1   1  1  Record Type
    VERSION No   L    N    2   5  4  Version Number
    TLID    No   R    N    6  15 10  TIGER/Line ID, Permanent 1-Cell Number
    RTSQ    No   R    N   16  18  3  Record Sequence Number
    LONG1   No   R    N   19  28 10  Point 1, Longitude
    LAT1    No   R    N   29  37  9  Point 1, Latitude
    LONG2   Yes  R    N   38  47 10  Point 2, Longitude
    LAT2    Yes  R    N   48  56  9  Point 2, Latitude
    LONG3   Yes  R    N   57  66 10  Point 3, Longitude
    LAT3    Yes  R    N   67  75  9  Point 3, Latitude
    LONG4   Yes  R    N   76  85 10  Point 4, Longitude
    LAT4    Yes  R    N   86  94  9  Point 4, Latitude
    LONG5   Yes  R    N   95 104 10  Point 5, Longitude
    LAT5    Yes  R    N  105 113  9  Point 5, Latitude
    LONG6   Yes  R    N  114 123 10  Point 6, Longitude
    LAT6    Yes  R    N  124 132  9  Point 6, Latitude
    LONG7   Yes  R    N  133 142 10  Point 7, Longitude
    LAT7    Yes  R    N  143 151  9  Point 7, Latitude
    LONG8   Yes  R    N  152 161 10  Point 8, Longitude
    LAT8    Yes  R    N  162 170  9  Point 8, Latitude
    LONG9   Yes  R    N  171 180 10  Point 9, Longitude
    LAT9    Yes  R    N  181 189  9  Point 9, Latitude
    LONG10  Yes  R    N  190 199 10  Point 10, Longitude
    LAT10   Yes  R    N  200 208  9  Point 10, Latitude
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
