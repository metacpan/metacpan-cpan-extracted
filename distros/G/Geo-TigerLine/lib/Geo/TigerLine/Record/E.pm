package Geo::TigerLine::Record::E;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
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
               'countyec' => {
                               'len' => 3,
                               'beg' => 28,
                               'bv' => 'No',
                               'fieldnum' => 7,
                               'type' => 'N',
                               'description' => 'FIPS County Code, 2002 Economic Census',
                               'end' => 30,
                               'fmt' => 'L',
                               'field' => 'countyec'
                             },
               'polyid' => {
                             'len' => 10,
                             'beg' => 16,
                             'bv' => 'No',
                             'fieldnum' => 5,
                             'type' => 'N',
                             'description' => 'Polygon Identification Code',
                             'end' => 25,
                             'fmt' => 'R',
                             'field' => 'polyid'
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
               'rs_e5' => {
                            'len' => 1,
                            'beg' => 55,
                            'bv' => 'Yes',
                            'fieldnum' => 13,
                            'type' => 'A',
                            'description' => 'Reserved Space E5',
                            'end' => 55,
                            'fmt' => 'L',
                            'field' => 'rs_e5'
                          },
               'rs_e4' => {
                            'len' => 4,
                            'beg' => 51,
                            'bv' => 'Yes',
                            'fieldnum' => 12,
                            'type' => 'N',
                            'description' => 'Reserved Space E4',
                            'end' => 54,
                            'fmt' => 'L',
                            'field' => 'rs_e4'
                          },
               'rs_e3' => {
                            'len' => 5,
                            'beg' => 46,
                            'bv' => 'Yes',
                            'fieldnum' => 11,
                            'type' => 'N',
                            'description' => 'Reserved Space E3',
                            'end' => 50,
                            'fmt' => 'L',
                            'field' => 'rs_e3'
                          },
               'rs_e2' => {
                            'len' => 5,
                            'beg' => 36,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'N',
                            'description' => 'Reserved Space E2',
                            'end' => 40,
                            'fmt' => 'L',
                            'field' => 'rs_e2'
                          },
               'rs_e6' => {
                            'len' => 17,
                            'beg' => 57,
                            'bv' => 'Yes',
                            'fieldnum' => 15,
                            'type' => 'A',
                            'description' => 'Reserved Space E6',
                            'end' => 73,
                            'fmt' => 'L',
                            'field' => 'rs_e6'
                          },
               'cenid' => {
                            'len' => 5,
                            'beg' => 11,
                            'bv' => 'No',
                            'fieldnum' => 4,
                            'type' => 'A',
                            'description' => 'Census File Identification Code',
                            'end' => 15,
                            'fmt' => 'L',
                            'field' => 'cenid'
                          },
               'rs_e1' => {
                            'len' => 5,
                            'beg' => 31,
                            'bv' => 'Yes',
                            'fieldnum' => 8,
                            'type' => 'N',
                            'description' => 'Reserved Space E1',
                            'end' => 35,
                            'fmt' => 'L',
                            'field' => 'rs_e1'
                          },
               'commregec' => {
                                'len' => 1,
                                'beg' => 56,
                                'bv' => 'Yes',
                                'fieldnum' => 14,
                                'type' => 'N',
                                'description' => 'Commercial Region Code, 2002 Economic Census',
                                'end' => 56,
                                'fmt' => 'L',
                                'field' => 'commregec'
                              },
               'placeec' => {
                              'len' => 5,
                              'beg' => 41,
                              'bv' => 'Yes',
                              'fieldnum' => 10,
                              'type' => 'N',
                              'description' => 'FIPS Economic Census PlaceCode, 2002 Economic Census',
                              'end' => 45,
                              'fmt' => 'L',
                              'field' => 'placeec'
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
               'stateec' => {
                              'len' => 2,
                              'beg' => 26,
                              'bv' => 'No',
                              'fieldnum' => 6,
                              'type' => 'N',
                              'description' => 'FIPS State Code, 2002 Economic Census',
                              'end' => 27,
                              'fmt' => 'L',
                              'field' => 'stateec'
                            }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'polyid',
                 'stateec',
                 'countyec',
                 'rs_e1',
                 'rs_e2',
                 'placeec',
                 'rs_e3',
                 'rs_e4',
                 'rs_e5',
                 'commregec',
                 'rs_e6'
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

Geo::TigerLine::Record::E - TIGER/Line 2006 Polygon Geographic Entity Codes: Economic Census

=head1 SYNOPSIS

  use Geo::TigerLine::Record::E;

  @records = Geo::TigerLine::Record::E->parse_file($fh);
  @records = Geo::TigerLine::Record::E->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::E->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->polyid();
  $record->stateec();
  $record->countyec();
  $record->rs_e1();
  $record->rs_e2();
  $record->placeec();
  $record->rs_e3();
  $record->rs_e4();
  $record->rs_e5();
  $record->commregec();
  $record->rs_e6();


=head1 DESCRIPTION

This is a class representing record type E of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type E files and turn them
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


=item B<cenid>

    $data = $record->cenid();
    $record->cenid($data);

Census File Identification Code.  

Expects alphanumeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<polyid>

    $data = $record->polyid();
    $record->polyid($data);

Polygon Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<stateec>

    $data = $record->stateec();
    $record->stateec($data);

FIPS State Code, 2002 Economic Census.  

Expects numeric data of no more than 2 characters.  $data cannot be blank 
and should be left justified.


=item B<countyec>

    $data = $record->countyec();
    $record->countyec($data);

FIPS County Code, 2002 Economic Census.  

Expects numeric data of no more than 3 characters.  $data cannot be blank 
and should be left justified.


=item B<rs_e1>

    $data = $record->rs_e1();
    $record->rs_e1($data);

Reserved Space E1.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_e2>

    $data = $record->rs_e2();
    $record->rs_e2($data);

Reserved Space E2.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<placeec>

    $data = $record->placeec();
    $record->placeec($data);

FIPS Economic Census PlaceCode, 2002 Economic Census.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_e3>

    $data = $record->rs_e3();
    $record->rs_e3($data);

Reserved Space E3.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_e4>

    $data = $record->rs_e4();
    $record->rs_e4($data);

Reserved Space E4.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<rs_e5>

    $data = $record->rs_e5();
    $record->rs_e5($data);

Reserved Space E5.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<commregec>

    $data = $record->commregec();
    $record->commregec($data);

Commercial Region Code, 2002 Economic Census.  

Expects numeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<rs_e6>

    $data = $record->rs_e6();
    $record->rs_e6($data);

Reserved Space E6.  

Expects alphanumeric data of no more than 17 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type E - Polygon Geographic Entity Codes: Economic Census
    
    Field     BV  Fmt  Type Beg End Len Description
    RT        No   L    A    1    1  1  Record Type
    VERSION   No   L    N    2    5  4  Version Number
    FILE      No   L    N    6   10  5  File Code
    CENID     No   L    A   11   15  5  Census File Identification Code
    POLYID    No   R    N   16   25 10  Polygon Identification Code
    STATEEC   No   L    N   26   27  2  FIPS State Code, 2002 Economic Census
    COUNTYEC  No   L    N   28   30  3  FIPS County Code, 2002 Economic Census
    RS-E1     Yes  L    N   31   35  5  Reserved Space E1
    RS-E2     Yes  L    N   36   40  5  Reserved Space E2
    PLACEEC   Yes  L    N   41   45  5  FIPS Economic Census PlaceCode, 2002 Economic Census
    RS-E3     Yes  L    N   46   50  5  Reserved Space E3
    RS-E4     Yes  L    N   51   54  4  Reserved Space E4
    RS-E5     Yes  L    A   55   55  1  Reserved Space E5
    COMMREGEC Yes  L    N   56   56  1  Commercial Region Code, 2002 Economic Census
    RS-E6     Yes  L    A   57   73 17  Reserved Space E6
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
