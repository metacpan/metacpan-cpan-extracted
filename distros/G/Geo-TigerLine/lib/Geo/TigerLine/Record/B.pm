package Geo::TigerLine::Record::B;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'statecq' => {
                              'len' => 2,
                              'beg' => 26,
                              'bv' => 'No',
                              'fieldnum' => 6,
                              'type' => 'N',
                              'description' => 'FIPS State Code, 2000 CQR',
                              'end' => 27,
                              'fmt' => 'L',
                              'field' => 'statecq'
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
               'anrccq' => {
                             'len' => 5,
                             'beg' => 60,
                             'bv' => 'Yes',
                             'fieldnum' => 15,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (ANRC), 2000 CQR',
                             'end' => 64,
                             'fmt' => 'L',
                             'field' => 'anrccq'
                           },
               'rs_b1' => {
                            'len' => 8,
                            'beg' => 91,
                            'bv' => 'Yes',
                            'fieldnum' => 22,
                            'type' => 'A',
                            'description' => 'Reserved Space B1',
                            'end' => 98,
                            'fmt' => 'L',
                            'field' => 'rs_b1'
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
               'tractcq' => {
                              'len' => 6,
                              'beg' => 31,
                              'bv' => 'No',
                              'fieldnum' => 8,
                              'type' => 'N',
                              'description' => 'Census Tract, 2000 CQR',
                              'end' => 36,
                              'fmt' => 'L',
                              'field' => 'tractcq'
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
               'countycq' => {
                               'len' => 3,
                               'beg' => 28,
                               'bv' => 'No',
                               'fieldnum' => 7,
                               'type' => 'N',
                               'description' => 'FIPS County Code, 2000 CQR',
                               'end' => 30,
                               'fmt' => 'L',
                               'field' => 'countycq'
                             },
               'submcdcq' => {
                               'len' => 5,
                               'beg' => 75,
                               'bv' => 'Yes',
                               'fieldnum' => 18,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (Subbarrio), 2000 CQR',
                               'end' => 79,
                               'fmt' => 'L',
                               'field' => 'submcdcq'
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
               'aihhtlicq' => {
                                'len' => 1,
                                'beg' => 51,
                                'bv' => 'Yes',
                                'fieldnum' => 12,
                                'type' => 'A',
                                'description' => 'American Indian/Hawaiian Home Land Trust Land Indicator, 2000 CQR',
                                'end' => 51,
                                'fmt' => 'L',
                                'field' => 'aihhtlicq'
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
               'aianhhfpcq' => {
                                 'len' => 5,
                                 'beg' => 42,
                                 'bv' => 'Yes',
                                 'fieldnum' => 10,
                                 'type' => 'N',
                                 'description' => 'FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR',
                                 'end' => 46,
                                 'fmt' => 'L',
                                 'field' => 'aianhhfpcq'
                               },
               'rs_b2' => {
                            'len' => 5,
                            'beg' => 85,
                            'bv' => 'Yes',
                            'fieldnum' => 20,
                            'type' => 'N',
                            'description' => 'Reserved Space B2',
                            'end' => 89,
                            'fmt' => 'L',
                            'field' => 'rs_b2'
                          },
               'aitscq' => {
                             'len' => 5,
                             'beg' => 55,
                             'bv' => 'Yes',
                             'fieldnum' => 14,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (American Indian Tribal Subdivision), 2000 CQR',
                             'end' => 59,
                             'fmt' => 'L',
                             'field' => 'aitscq'
                           },
               'cousubcq' => {
                               'len' => 5,
                               'beg' => 70,
                               'bv' => 'No',
                               'fieldnum' => 17,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (County Subdivision), 2000 CQR',
                               'end' => 74,
                               'fmt' => 'L',
                               'field' => 'cousubcq'
                             },
               'aianhhcq' => {
                               'len' => 4,
                               'beg' => 47,
                               'bv' => 'Yes',
                               'fieldnum' => 11,
                               'type' => 'N',
                               'description' => 'Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR',
                               'end' => 50,
                               'fmt' => 'L',
                               'field' => 'aianhhcq'
                             },
               'placecq' => {
                              'len' => 5,
                              'beg' => 80,
                              'bv' => 'Yes',
                              'fieldnum' => 19,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (Incorporated Place), 2000 CQR',
                              'end' => 84,
                              'fmt' => 'L',
                              'field' => 'placecq'
                            },
               'blockcq' => {
                              'len' => 5,
                              'beg' => 37,
                              'bv' => 'No',
                              'fieldnum' => 9,
                              'type' => 'A',
                              'description' => 'Census Block Number, 2000 CQR',
                              'end' => 41,
                              'fmt' => 'L',
                              'field' => 'blockcq'
                            },
               'aitscecq' => {
                               'len' => 3,
                               'beg' => 52,
                               'bv' => 'Yes',
                               'fieldnum' => 13,
                               'type' => 'N',
                               'description' => 'Census Code (American Indian Tribal Subdivision), 2000 CQR',
                               'end' => 54,
                               'fmt' => 'L',
                               'field' => 'aitscecq'
                             },
               'concitcq' => {
                               'len' => 5,
                               'beg' => 65,
                               'bv' => 'Yes',
                               'fieldnum' => 16,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (Consolidated City), 2000 CQR',
                               'end' => 69,
                               'fmt' => 'L',
                               'field' => 'concitcq'
                             },
               'rs_b3' => {
                            'len' => 1,
                            'beg' => 90,
                            'bv' => 'Yes',
                            'fieldnum' => 21,
                            'type' => 'A',
                            'description' => 'Reserved Space B3',
                            'end' => 90,
                            'fmt' => 'L',
                            'field' => 'rs_b3'
                          }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'polyid',
                 'statecq',
                 'countycq',
                 'tractcq',
                 'blockcq',
                 'aianhhfpcq',
                 'aianhhcq',
                 'aihhtlicq',
                 'aitscecq',
                 'aitscq',
                 'anrccq',
                 'concitcq',
                 'cousubcq',
                 'submcdcq',
                 'placecq',
                 'rs_b2',
                 'rs_b3',
                 'rs_b1'
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

Geo::TigerLine::Record::B - TIGER/Line 2006 Polygon Geographic Entity Codes: Corrections

=head1 SYNOPSIS

  use Geo::TigerLine::Record::B;

  @records = Geo::TigerLine::Record::B->parse_file($fh);
  @records = Geo::TigerLine::Record::B->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::B->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->polyid();
  $record->statecq();
  $record->countycq();
  $record->tractcq();
  $record->blockcq();
  $record->aianhhfpcq();
  $record->aianhhcq();
  $record->aihhtlicq();
  $record->aitscecq();
  $record->aitscq();
  $record->anrccq();
  $record->concitcq();
  $record->cousubcq();
  $record->submcdcq();
  $record->placecq();
  $record->rs_b2();
  $record->rs_b3();
  $record->rs_b1();


=head1 DESCRIPTION

This is a class representing record type B of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type B files and turn them
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


=item B<statecq>

    $data = $record->statecq();
    $record->statecq($data);

FIPS State Code, 2000 CQR.  

Expects numeric data of no more than 2 characters.  $data cannot be blank 
and should be left justified.


=item B<countycq>

    $data = $record->countycq();
    $record->countycq($data);

FIPS County Code, 2000 CQR.  

Expects numeric data of no more than 3 characters.  $data cannot be blank 
and should be left justified.


=item B<tractcq>

    $data = $record->tractcq();
    $record->tractcq($data);

Census Tract, 2000 CQR.  

Expects numeric data of no more than 6 characters.  $data cannot be blank 
and should be left justified.


=item B<blockcq>

    $data = $record->blockcq();
    $record->blockcq($data);

Census Block Number, 2000 CQR.  

Expects alphanumeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<aianhhfpcq>

    $data = $record->aianhhfpcq();
    $record->aianhhfpcq($data);

FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aianhhcq>

    $data = $record->aianhhcq();
    $record->aianhhcq($data);

Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<aihhtlicq>

    $data = $record->aihhtlicq();
    $record->aihhtlicq($data);

American Indian/Hawaiian Home Land Trust Land Indicator, 2000 CQR.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<aitscecq>

    $data = $record->aitscecq();
    $record->aitscecq($data);

Census Code (American Indian Tribal Subdivision), 2000 CQR.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<aitscq>

    $data = $record->aitscq();
    $record->aitscq($data);

FIPS 55 Code (American Indian Tribal Subdivision), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<anrccq>

    $data = $record->anrccq();
    $record->anrccq($data);

FIPS 55 Code (ANRC), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<concitcq>

    $data = $record->concitcq();
    $record->concitcq($data);

FIPS 55 Code (Consolidated City), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<cousubcq>

    $data = $record->cousubcq();
    $record->cousubcq($data);

FIPS 55 Code (County Subdivision), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<submcdcq>

    $data = $record->submcdcq();
    $record->submcdcq($data);

FIPS 55 Code (Subbarrio), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<placecq>

    $data = $record->placecq();
    $record->placecq($data);

FIPS 55 Code (Incorporated Place), 2000 CQR.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_b2>

    $data = $record->rs_b2();
    $record->rs_b2($data);

Reserved Space B2.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_b3>

    $data = $record->rs_b3();
    $record->rs_b3($data);

Reserved Space B3.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<rs_b1>

    $data = $record->rs_b1();
    $record->rs_b1($data);

Reserved Space B1.  

Expects alphanumeric data of no more than 8 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type B - Polygon Geographic Entity Codes: Corrections
    
    Field      BV  Fmt Type Beg End Len Description
    RT         No   L   A    1    1  1  Record Type
    VERSION    No   L   N    2    5  4  Version Number
    FILE       No   L   N    6   10  5  File Code
    CENID      No   L   A   11   15  5  Census File Identification Code
    POLYID     No   R   N   16   25 10  Polygon Identification Code
    STATECQ    No   L   N   26   27  2  FIPS State Code, 2000 CQR
    COUNTYCQ   No   L   N   28   30  3  FIPS County Code, 2000 CQR
    TRACTCQ    No   L   N   31   36  6  Census Tract, 2000 CQR
    BLOCKCQ    No   L   A   37   41  5  Census Block Number, 2000 CQR
    AIANHHFPCQ Yes  L   N   42   46  5  FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR
    AIANHHCQ   Yes  L   N   47   50  4  Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 CQR
    AIHHTLICQ  Yes  L   A   51   51  1  American Indian/Hawaiian Home Land Trust Land Indicator, 2000 CQR
    AITSCECQ   Yes  L   N   52   54  3  Census Code (American Indian Tribal Subdivision), 2000 CQR
    AITSCQ     Yes  L   N   55   59  5  FIPS 55 Code (American Indian Tribal Subdivision), 2000 CQR
    ANRCCQ     Yes  L   N   60   64  5  FIPS 55 Code (ANRC), 2000 CQR
    CONCITCQ   Yes  L   N   65   69  5  FIPS 55 Code (Consolidated City), 2000 CQR
    COUSUBCQ   No   L   N   70   74  5  FIPS 55 Code (County Subdivision), 2000 CQR
    SUBMCDCQ   Yes  L   N   75   79  5  FIPS 55 Code (Subbarrio), 2000 CQR
    PLACECQ    Yes  L   N   80   84  5  FIPS 55 Code (Incorporated Place), 2000 CQR
    RS-B2      Yes  L   N   85   89  5  Reserved Space B2 
    RS-B3      Yes  L   A   90   90  1  Reserved Space B3  
    RS-B1      Yes  L   A   91   98  8  Reserved Space B1



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
