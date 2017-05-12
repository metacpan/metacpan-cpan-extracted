package Geo::TigerLine::Record::U;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'tlidov1' => {
                              'len' => 10,
                              'beg' => 22,
                              'bv' => 'Yes',
                              'fieldnum' => 6,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, First Overpass 1-Cell Number',
                              'end' => 31,
                              'fmt' => 'R',
                              'field' => 'tlidov1'
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
               'tlidun1' => {
                              'len' => 10,
                              'beg' => 42,
                              'bv' => 'Yes',
                              'fieldnum' => 8,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, First Underpass 1-Cell Number',
                              'end' => 51,
                              'fmt' => 'R',
                              'field' => 'tlidun1'
                            },
               'tlidov2' => {
                              'len' => 10,
                              'beg' => 32,
                              'bv' => 'Yes',
                              'fieldnum' => 7,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Second Overpass 1-Cell Number',
                              'end' => 41,
                              'fmt' => 'R',
                              'field' => 'tlidov2'
                            },
               'tzid' => {
                           'len' => 10,
                           'beg' => 11,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'TIGER Zero-Cell ID, Permanent Zero-Cell Number',
                           'end' => 20,
                           'fmt' => 'R',
                           'field' => 'tzid'
                         },
               'frlat' => {
                            'len' => 9,
                            'beg' => 72,
                            'bv' => 'No',
                            'fieldnum' => 11,
                            'type' => 'N',
                            'description' => 'TZID Latitude',
                            'end' => 80,
                            'fmt' => 'R',
                            'field' => 'frlat'
                          },
               'rtsq' => {
                           'len' => 1,
                           'beg' => 21,
                           'bv' => 'No',
                           'fieldnum' => 5,
                           'type' => 'N',
                           'description' => 'Record Sequence Number',
                           'end' => 21,
                           'fmt' => 'R',
                           'field' => 'rtsq'
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
               'tlidun2' => {
                              'len' => 10,
                              'beg' => 52,
                              'bv' => 'Yes',
                              'fieldnum' => 9,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Second Underpass 1-Cell Number',
                              'end' => 61,
                              'fmt' => 'R',
                              'field' => 'tlidun2'
                            },
               'frlong' => {
                             'len' => 10,
                             'beg' => 62,
                             'bv' => 'No',
                             'fieldnum' => 10,
                             'type' => 'N',
                             'description' => 'TZID Longitude',
                             'end' => 71,
                             'fmt' => 'R',
                             'field' => 'frlong'
                           }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'tzid',
                 'rtsq',
                 'tlidov1',
                 'tlidov2',
                 'tlidun1',
                 'tlidun2',
                 'frlong',
                 'frlat'
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

Geo::TigerLine::Record::U - TIGER/Line 2006 TIGER/Line ID Overpass/Underpass Identification

=head1 SYNOPSIS

  use Geo::TigerLine::Record::U;

  @records = Geo::TigerLine::Record::U->parse_file($fh);
  @records = Geo::TigerLine::Record::U->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::U->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->tzid();
  $record->rtsq();
  $record->tlidov1();
  $record->tlidov2();
  $record->tlidun1();
  $record->tlidun2();
  $record->frlong();
  $record->frlat();


=head1 DESCRIPTION

This is a class representing record type U of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type U files and turn them
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


=item B<tzid>

    $data = $record->tzid();
    $record->tzid($data);

TIGER Zero-Cell ID, Permanent Zero-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<rtsq>

    $data = $record->rtsq();
    $record->rtsq($data);

Record Sequence Number.  

Expects numeric data of no more than 1 characters.  $data cannot be blank 
and should be right justified.


=item B<tlidov1>

    $data = $record->tlidov1();
    $record->tlidov1($data);

TIGER/Line ID, First Overpass 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidov2>

    $data = $record->tlidov2();
    $record->tlidov2($data);

TIGER/Line ID, Second Overpass 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidun1>

    $data = $record->tlidun1();
    $record->tlidun1($data);

TIGER/Line ID, First Underpass 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidun2>

    $data = $record->tlidun2();
    $record->tlidun2($data);

TIGER/Line ID, Second Underpass 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<frlong>

    $data = $record->frlong();
    $record->frlong($data);

TZID Longitude.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<frlat>

    $data = $record->frlat();
    $record->frlat($data);

TZID Latitude.  

Expects numeric data of no more than 9 characters.  $data cannot be blank 
and should be right justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type U - TIGER/Line ID Overpass/Underpass Identification
    
    Field     BV  Fmt  Type Beg End  Len Description
    RT        No   L    A     1    1  1  Record Type
    VERSION   No   L    N     2    5  4  Version Number
    FILE      No   L    N     6   10  5  File Code
    TZID      No   R    N    11   20 10  TIGER Zero-Cell ID, Permanent Zero-Cell Number
    RTSQ      No   R    N    21   21  1  Record Sequence Number
    TLIDOV1   Yes  R    N    22   31 10  TIGER/Line ID, First Overpass 1-Cell Number
    TLIDOV2   Yes  R    N    32   41 10  TIGER/Line ID, Second Overpass 1-Cell Number
    TLIDUN1   Yes  R    N    42   51 10  TIGER/Line ID, First Underpass 1-Cell Number
    TLIDUN2   Yes  R    N    52   61 10  TIGER/Line ID, Second Underpass 1-Cell Number
    FRLONG    No   R    N    62   71 10  TZID Longitude
    FRLAT     No   R    N    72   80  9  TZID Latitude



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
