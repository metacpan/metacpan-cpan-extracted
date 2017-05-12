package Geo::TigerLine::Record::A;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
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
               'urcu' => {
                           'len' => 1,
                           'beg' => 187,
                           'bv' => 'Yes',
                           'fieldnum' => 45,
                           'type' => 'A',
                           'description' => 'Urban/Rural Indicator, Current',
                           'end' => 187,
                           'fmt' => 'L',
                           'field' => 'urcu'
                         },
               'tract' => {
                            'len' => 6,
                            'beg' => 31,
                            'bv' => 'No',
                            'fieldnum' => 8,
                            'type' => 'N',
                            'description' => 'Census Tract, 2000',
                            'end' => 36,
                            'fmt' => 'L',
                            'field' => 'tract'
                          },
               'rs_a18' => {
                             'len' => 6,
                             'beg' => 194,
                             'bv' => 'Yes',
                             'fieldnum' => 47,
                             'type' => 'A',
                             'description' => 'Reserved Space A18',
                             'end' => 199,
                             'fmt' => 'L',
                             'field' => 'rs_a18'
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
               'cbsacu' => {
                             'len' => 5,
                             'beg' => 152,
                             'bv' => 'Yes',
                             'fieldnum' => 37,
                             'type' => 'N',
                             'description' => 'FIPS Metropolitan Statistical Area/ Micropolitan Statistical Area Code, Current',
                             'end' => 156,
                             'fmt' => 'L',
                             'field' => 'cbsacu'
                           },
               'rs_a20' => {
                             'len' => 4,
                             'beg' => 101,
                             'bv' => 'Yes',
                             'fieldnum' => 25,
                             'type' => 'N',
                             'description' => 'Reserved Space A20',
                             'end' => 104,
                             'fmt' => 'L',
                             'field' => 'rs_a20'
                           },
               'sdelmcu' => {
                              'len' => 5,
                              'beg' => 86,
                              'bv' => 'Yes',
                              'fieldnum' => 22,
                              'type' => 'A',
                              'description' => 'Elementary School District Code, Current',
                              'end' => 90,
                              'fmt' => 'L',
                              'field' => 'sdelmcu'
                            },
               'rs_a19' => {
                             'len' => 11,
                             'beg' => 200,
                             'bv' => 'Yes',
                             'fieldnum' => 48,
                             'type' => 'A',
                             'description' => 'Reserved Space A19',
                             'end' => 210,
                             'fmt' => 'L',
                             'field' => 'rs_a19'
                           },
               'zcta5cu' => {
                              'len' => 5,
                              'beg' => 115,
                              'bv' => 'Yes',
                              'fieldnum' => 29,
                              'type' => 'A',
                              'description' => '5-Digit ZIP Code Tabulation Area, current',
                              'end' => 119,
                              'fmt' => 'L',
                              'field' => 'zcta5cu'
                            },
               'submcdcu' => {
                               'len' => 5,
                               'beg' => 76,
                               'bv' => 'Yes',
                               'fieldnum' => 20,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (Subbarrio), Current',
                               'end' => 80,
                               'fmt' => 'L',
                               'field' => 'submcdcu'
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
               'csacu' => {
                            'len' => 3,
                            'beg' => 157,
                            'bv' => 'Yes',
                            'fieldnum' => 38,
                            'type' => 'N',
                            'description' => 'FIPS Combined Statistical Area Code, Current',
                            'end' => 159,
                            'fmt' => 'L',
                            'field' => 'csacu'
                          },
               'rs_a17' => {
                             'len' => 6,
                             'beg' => 188,
                             'bv' => 'Yes',
                             'fieldnum' => 46,
                             'type' => 'A',
                             'description' => 'Reserved Space A17',
                             'end' => 193,
                             'fmt' => 'L',
                             'field' => 'rs_a17'
                           },
               'rs_a22' => {
                             'len' => 4,
                             'beg' => 109,
                             'bv' => 'Yes',
                             'fieldnum' => 27,
                             'type' => 'N',
                             'description' => 'Reserved Space A22',
                             'end' => 112,
                             'fmt' => 'L',
                             'field' => 'rs_a22'
                           },
               'aianhhfpcu' => {
                                 'len' => 5,
                                 'beg' => 43,
                                 'bv' => 'Yes',
                                 'fieldnum' => 12,
                                 'type' => 'N',
                                 'description' => 'FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current',
                                 'end' => 47,
                                 'fmt' => 'L',
                                 'field' => 'aianhhfpcu'
                               },
               'cnectacu' => {
                               'len' => 3,
                               'beg' => 165,
                               'bv' => 'Yes',
                               'fieldnum' => 40,
                               'type' => 'N',
                               'description' => 'FIPS Combined New England City and Town Area Code, Current',
                               'end' => 167,
                               'fmt' => 'L',
                               'field' => 'cnectacu'
                             },
               'rs_a1' => {
                            'len' => 1,
                            'beg' => 42,
                            'bv' => 'Yes',
                            'fieldnum' => 11,
                            'type' => 'A',
                            'description' => 'Reserved Space A1',
                            'end' => 42,
                            'fmt' => 'L',
                            'field' => 'rs_a1'
                          },
               'sdunicu' => {
                              'len' => 5,
                              'beg' => 96,
                              'bv' => 'Yes',
                              'fieldnum' => 24,
                              'type' => 'A',
                              'description' => 'Unified School District Code, Current',
                              'end' => 100,
                              'fmt' => 'L',
                              'field' => 'sdunicu'
                            },
               'statecu' => {
                              'len' => 2,
                              'beg' => 26,
                              'bv' => 'No',
                              'fieldnum' => 6,
                              'type' => 'N',
                              'description' => 'FIPS State Code, Current',
                              'end' => 27,
                              'fmt' => 'L',
                              'field' => 'statecu'
                            },
               'rs_a7' => {
                            'len' => 5,
                            'beg' => 135,
                            'bv' => 'Yes',
                            'fieldnum' => 34,
                            'type' => 'A',
                            'description' => 'Reserved Space A7',
                            'end' => 139,
                            'fmt' => 'R',
                            'field' => 'rs_a7'
                          },
               'blocksufcu' => {
                                 'len' => 1,
                                 'beg' => 41,
                                 'bv' => 'Yes',
                                 'fieldnum' => 10,
                                 'type' => 'A',
                                 'description' => 'Current Suffix for Census 2000 Block Number',
                                 'end' => 41,
                                 'fmt' => 'L',
                                 'field' => 'blocksufcu'
                               },
               'placecu' => {
                              'len' => 5,
                              'beg' => 81,
                              'bv' => 'Yes',
                              'fieldnum' => 21,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (Incorporated Place), Current',
                              'end' => 85,
                              'fmt' => 'L',
                              'field' => 'placecu'
                            },
               'cdcu' => {
                           'len' => 2,
                           'beg' => 113,
                           'bv' => 'Yes',
                           'fieldnum' => 28,
                           'type' => 'N',
                           'description' => 'Congressional District Code, Current (108th)',
                           'end' => 114,
                           'fmt' => 'R',
                           'field' => 'cdcu'
                         },
               'concitcu' => {
                               'len' => 5,
                               'beg' => 66,
                               'bv' => 'Yes',
                               'fieldnum' => 18,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (Consolidated City), Current',
                               'end' => 70,
                               'fmt' => 'L',
                               'field' => 'concitcu'
                             },
               'sdseccu' => {
                              'len' => 5,
                              'beg' => 91,
                              'bv' => 'Yes',
                              'fieldnum' => 23,
                              'type' => 'A',
                              'description' => 'Secondary School District Code, Current',
                              'end' => 95,
                              'fmt' => 'L',
                              'field' => 'sdseccu'
                            },
               'aitscu' => {
                             'len' => 5,
                             'beg' => 61,
                             'bv' => 'Yes',
                             'fieldnum' => 17,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (American Indian Tribal Subdivision), Current',
                             'end' => 65,
                             'fmt' => 'L',
                             'field' => 'aitscu'
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
               'rs_a21' => {
                             'len' => 4,
                             'beg' => 105,
                             'bv' => 'Yes',
                             'fieldnum' => 26,
                             'type' => 'N',
                             'description' => 'Reserved Space A21',
                             'end' => 108,
                             'fmt' => 'L',
                             'field' => 'rs_a21'
                           },
               'slducu' => {
                             'len' => 3,
                             'beg' => 129,
                             'bv' => 'Yes',
                             'fieldnum' => 32,
                             'type' => 'A',
                             'description' => 'State Legislative District Upper, Current (2006)',
                             'end' => 131,
                             'fmt' => 'R',
                             'field' => 'slducu'
                           },
               'rs_a8' => {
                            'len' => 6,
                            'beg' => 140,
                            'bv' => 'Yes',
                            'fieldnum' => 35,
                            'type' => 'A',
                            'description' => 'Reserved Space A8',
                            'end' => 145,
                            'fmt' => 'R',
                            'field' => 'rs_a8'
                          },
               'aihhtlicu' => {
                                'len' => 1,
                                'beg' => 52,
                                'bv' => 'Yes',
                                'fieldnum' => 14,
                                'type' => 'A',
                                'description' => 'American Indian/Hawaiian Home Land Trust Land Indicator, Current',
                                'end' => 52,
                                'fmt' => 'L',
                                'field' => 'aihhtlicu'
                              },
               'sldlcu' => {
                             'len' => 3,
                             'beg' => 132,
                             'bv' => 'Yes',
                             'fieldnum' => 33,
                             'type' => 'A',
                             'description' => 'State Legislative District Lower, Current (2006)',
                             'end' => 134,
                             'fmt' => 'R',
                             'field' => 'sldlcu'
                           },
               'metdivcu' => {
                               'len' => 5,
                               'beg' => 168,
                               'bv' => 'Yes',
                               'fieldnum' => 41,
                               'type' => 'N',
                               'description' => 'FIPS Metropolitan Division Code, Current',
                               'end' => 172,
                               'fmt' => 'L',
                               'field' => 'metdivcu'
                             },
               'rs_a14' => {
                             'len' => 4,
                             'beg' => 178,
                             'bv' => 'Yes',
                             'fieldnum' => 43,
                             'type' => 'A',
                             'description' => 'Reserved Space A14',
                             'end' => 181,
                             'fmt' => 'L',
                             'field' => 'rs_a14'
                           },
               'aianhhcu' => {
                               'len' => 4,
                               'beg' => 48,
                               'bv' => 'Yes',
                               'fieldnum' => 13,
                               'type' => 'N',
                               'description' => 'Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current',
                               'end' => 51,
                               'fmt' => 'L',
                               'field' => 'aianhhcu'
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
               'uacu' => {
                           'len' => 5,
                           'beg' => 182,
                           'bv' => 'Yes',
                           'fieldnum' => 44,
                           'type' => 'N',
                           'description' => 'Urban Area, Current',
                           'end' => 186,
                           'fmt' => 'L',
                           'field' => 'uacu'
                         },
               'countycu' => {
                               'len' => 3,
                               'beg' => 28,
                               'bv' => 'No',
                               'fieldnum' => 7,
                               'type' => 'N',
                               'description' => 'FIPS County Code, Current',
                               'end' => 30,
                               'fmt' => 'L',
                               'field' => 'countycu'
                             },
               'zcta3cu' => {
                              'len' => 3,
                              'beg' => 120,
                              'bv' => 'Yes',
                              'fieldnum' => 30,
                              'type' => 'A',
                              'description' => '3-Digit ZIP Code Tabulation Area, current',
                              'end' => 122,
                              'fmt' => 'R',
                              'field' => 'zcta3cu'
                            },
               'cousubcu' => {
                               'len' => 5,
                               'beg' => 71,
                               'bv' => 'No',
                               'fieldnum' => 19,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (County Subdivision), Current',
                               'end' => 75,
                               'fmt' => 'L',
                               'field' => 'cousubcu'
                             },
               'rs_a4' => {
                            'len' => 6,
                            'beg' => 123,
                            'bv' => 'Yes',
                            'fieldnum' => 31,
                            'type' => 'A',
                            'description' => 'Reserved Space A4',
                            'end' => 128,
                            'fmt' => 'R',
                            'field' => 'rs_a4'
                          },
               'aitscecu' => {
                               'len' => 3,
                               'beg' => 58,
                               'bv' => 'Yes',
                               'fieldnum' => 16,
                               'type' => 'N',
                               'description' => 'Census Code (American Indian Tribal Subdivision), Current',
                               'end' => 60,
                               'fmt' => 'L',
                               'field' => 'aitscecu'
                             },
               'block' => {
                            'len' => 4,
                            'beg' => 37,
                            'bv' => 'No',
                            'fieldnum' => 9,
                            'type' => 'N',
                            'description' => 'Census Block Number, 2000',
                            'end' => 40,
                            'fmt' => 'L',
                            'field' => 'block'
                          },
               'nectacu' => {
                              'len' => 5,
                              'beg' => 160,
                              'bv' => 'Yes',
                              'fieldnum' => 39,
                              'type' => 'N',
                              'description' => 'FIPS New England City and Town Area Code, Current',
                              'end' => 164,
                              'fmt' => 'L',
                              'field' => 'nectacu'
                            },
               'nectadivcu' => {
                                 'len' => 5,
                                 'beg' => 173,
                                 'bv' => 'Yes',
                                 'fieldnum' => 42,
                                 'type' => 'N',
                                 'description' => 'FIPS New England City and Town Area Division Code, Current',
                                 'end' => 177,
                                 'fmt' => 'L',
                                 'field' => 'nectadivcu'
                               },
               'rs_a9' => {
                            'len' => 6,
                            'beg' => 146,
                            'bv' => 'Yes',
                            'fieldnum' => 36,
                            'type' => 'A',
                            'description' => 'Reserved Space A9',
                            'end' => 151,
                            'fmt' => 'L',
                            'field' => 'rs_a9'
                          },
               'anrccu' => {
                             'len' => 5,
                             'beg' => 53,
                             'bv' => 'Yes',
                             'fieldnum' => 15,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (ANRC), Current',
                             'end' => 57,
                             'fmt' => 'L',
                             'field' => 'anrccu'
                           }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'polyid',
                 'statecu',
                 'countycu',
                 'tract',
                 'block',
                 'blocksufcu',
                 'rs_a1',
                 'aianhhfpcu',
                 'aianhhcu',
                 'aihhtlicu',
                 'anrccu',
                 'aitscecu',
                 'aitscu',
                 'concitcu',
                 'cousubcu',
                 'submcdcu',
                 'placecu',
                 'sdelmcu',
                 'sdseccu',
                 'sdunicu',
                 'rs_a20',
                 'rs_a21',
                 'rs_a22',
                 'cdcu',
                 'zcta5cu',
                 'zcta3cu',
                 'rs_a4',
                 'slducu',
                 'sldlcu',
                 'rs_a7',
                 'rs_a8',
                 'rs_a9',
                 'cbsacu',
                 'csacu',
                 'nectacu',
                 'cnectacu',
                 'metdivcu',
                 'nectadivcu',
                 'rs_a14',
                 'uacu',
                 'urcu',
                 'rs_a17',
                 'rs_a18',
                 'rs_a19'
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

Geo::TigerLine::Record::A - TIGER/Line 2006 Polygon Geographic Entity Codes: Current Geography

=head1 SYNOPSIS

  use Geo::TigerLine::Record::A;

  @records = Geo::TigerLine::Record::A->parse_file($fh);
  @records = Geo::TigerLine::Record::A->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::A->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->polyid();
  $record->statecu();
  $record->countycu();
  $record->tract();
  $record->block();
  $record->blocksufcu();
  $record->rs_a1();
  $record->aianhhfpcu();
  $record->aianhhcu();
  $record->aihhtlicu();
  $record->anrccu();
  $record->aitscecu();
  $record->aitscu();
  $record->concitcu();
  $record->cousubcu();
  $record->submcdcu();
  $record->placecu();
  $record->sdelmcu();
  $record->sdseccu();
  $record->sdunicu();
  $record->rs_a20();
  $record->rs_a21();
  $record->rs_a22();
  $record->cdcu();
  $record->zcta5cu();
  $record->zcta3cu();
  $record->rs_a4();
  $record->slducu();
  $record->sldlcu();
  $record->rs_a7();
  $record->rs_a8();
  $record->rs_a9();
  $record->cbsacu();
  $record->csacu();
  $record->nectacu();
  $record->cnectacu();
  $record->metdivcu();
  $record->nectadivcu();
  $record->rs_a14();
  $record->uacu();
  $record->urcu();
  $record->rs_a17();
  $record->rs_a18();
  $record->rs_a19();


=head1 DESCRIPTION

This is a class representing record type A of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type A files and turn them
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


=item B<statecu>

    $data = $record->statecu();
    $record->statecu($data);

FIPS State Code, Current.  

Expects numeric data of no more than 2 characters.  $data cannot be blank 
and should be left justified.


=item B<countycu>

    $data = $record->countycu();
    $record->countycu($data);

FIPS County Code, Current.  

Expects numeric data of no more than 3 characters.  $data cannot be blank 
and should be left justified.


=item B<tract>

    $data = $record->tract();
    $record->tract($data);

Census Tract, 2000.  

Expects numeric data of no more than 6 characters.  $data cannot be blank 
and should be left justified.


=item B<block>

    $data = $record->block();
    $record->block($data);

Census Block Number, 2000.  

Expects numeric data of no more than 4 characters.  $data cannot be blank 
and should be left justified.


=item B<blocksufcu>

    $data = $record->blocksufcu();
    $record->blocksufcu($data);

Current Suffix for Census 2000 Block Number.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<rs_a1>

    $data = $record->rs_a1();
    $record->rs_a1($data);

Reserved Space A1.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<aianhhfpcu>

    $data = $record->aianhhfpcu();
    $record->aianhhfpcu($data);

FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aianhhcu>

    $data = $record->aianhhcu();
    $record->aianhhcu($data);

Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<aihhtlicu>

    $data = $record->aihhtlicu();
    $record->aihhtlicu($data);

American Indian/Hawaiian Home Land Trust Land Indicator, Current.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<anrccu>

    $data = $record->anrccu();
    $record->anrccu($data);

FIPS 55 Code (ANRC), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aitscecu>

    $data = $record->aitscecu();
    $record->aitscecu($data);

Census Code (American Indian Tribal Subdivision), Current.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<aitscu>

    $data = $record->aitscu();
    $record->aitscu($data);

FIPS 55 Code (American Indian Tribal Subdivision), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<concitcu>

    $data = $record->concitcu();
    $record->concitcu($data);

FIPS 55 Code (Consolidated City), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<cousubcu>

    $data = $record->cousubcu();
    $record->cousubcu($data);

FIPS 55 Code (County Subdivision), Current.  

Expects numeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<submcdcu>

    $data = $record->submcdcu();
    $record->submcdcu($data);

FIPS 55 Code (Subbarrio), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<placecu>

    $data = $record->placecu();
    $record->placecu($data);

FIPS 55 Code (Incorporated Place), Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sdelmcu>

    $data = $record->sdelmcu();
    $record->sdelmcu($data);

Elementary School District Code, Current.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sdseccu>

    $data = $record->sdseccu();
    $record->sdseccu($data);

Secondary School District Code, Current.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sdunicu>

    $data = $record->sdunicu();
    $record->sdunicu($data);

Unified School District Code, Current.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_a20>

    $data = $record->rs_a20();
    $record->rs_a20($data);

Reserved Space A20.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<rs_a21>

    $data = $record->rs_a21();
    $record->rs_a21($data);

Reserved Space A21.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<rs_a22>

    $data = $record->rs_a22();
    $record->rs_a22($data);

Reserved Space A22.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<cdcu>

    $data = $record->cdcu();
    $record->cdcu($data);

Congressional District Code, Current (108th).  

Expects numeric data of no more than 2 characters.  $data can be blank 
and should be right justified.


=item B<zcta5cu>

    $data = $record->zcta5cu();
    $record->zcta5cu($data);

5-Digit ZIP Code Tabulation Area, current.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<zcta3cu>

    $data = $record->zcta3cu();
    $record->zcta3cu($data);

3-Digit ZIP Code Tabulation Area, current.  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be right justified.


=item B<rs_a4>

    $data = $record->rs_a4();
    $record->rs_a4($data);

Reserved Space A4.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be right justified.


=item B<slducu>

    $data = $record->slducu();
    $record->slducu($data);

State Legislative District Upper, Current (2006).  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be right justified.


=item B<sldlcu>

    $data = $record->sldlcu();
    $record->sldlcu($data);

State Legislative District Lower, Current (2006).  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be right justified.


=item B<rs_a7>

    $data = $record->rs_a7();
    $record->rs_a7($data);

Reserved Space A7.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be right justified.


=item B<rs_a8>

    $data = $record->rs_a8();
    $record->rs_a8($data);

Reserved Space A8.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be right justified.


=item B<rs_a9>

    $data = $record->rs_a9();
    $record->rs_a9($data);

Reserved Space A9.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<cbsacu>

    $data = $record->cbsacu();
    $record->cbsacu($data);

FIPS Metropolitan Statistical Area/ Micropolitan Statistical Area Code, Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<csacu>

    $data = $record->csacu();
    $record->csacu($data);

FIPS Combined Statistical Area Code, Current.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<nectacu>

    $data = $record->nectacu();
    $record->nectacu($data);

FIPS New England City and Town Area Code, Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<cnectacu>

    $data = $record->cnectacu();
    $record->cnectacu($data);

FIPS Combined New England City and Town Area Code, Current.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<metdivcu>

    $data = $record->metdivcu();
    $record->metdivcu($data);

FIPS Metropolitan Division Code, Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<nectadivcu>

    $data = $record->nectadivcu();
    $record->nectadivcu($data);

FIPS New England City and Town Area Division Code, Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<rs_a14>

    $data = $record->rs_a14();
    $record->rs_a14($data);

Reserved Space A14.  

Expects alphanumeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<uacu>

    $data = $record->uacu();
    $record->uacu($data);

Urban Area, Current.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<urcu>

    $data = $record->urcu();
    $record->urcu($data);

Urban/Rural Indicator, Current.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<rs_a17>

    $data = $record->rs_a17();
    $record->rs_a17($data);

Reserved Space A17.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<rs_a18>

    $data = $record->rs_a18();
    $record->rs_a18($data);

Reserved Space A18.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<rs_a19>

    $data = $record->rs_a19();
    $record->rs_a19($data);

Reserved Space A19.  

Expects alphanumeric data of no more than 11 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type A - Polygon Geographic Entity Codes: Current Geography
    
    Field      BV  Fmt Type  Beg End Len Description
    RT         No   L    A    1    1  1  Record Type
    VERSION    No   L   N     2    5  4  Version Number
    FILE       No   L   N     6   10  5  File Code
    CENID      No   L    A   11   15  5  Census File Identification Code
    POLYID     No   R   N    16   25 10  Polygon Identification Code
    STATECU    No   L   N    26   27  2  FIPS State Code, Current
    COUNTYCU   No   L   N    28   30  3  FIPS County Code, Current
    TRACT      No   L    N   31   36  6  Census Tract, 2000
    BLOCK      No   L   N    37   40  4  Census Block Number, 2000
    BLOCKSUFCU Yes  L    A   41   41  1  Current Suffix for Census 2000 Block Number
    RS-A1      Yes  L    A   42   42  1  Reserved Space A1
    AIANHHFPCU Yes  L   N    43   47  5  FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current
    AIANHHCU   Yes  L   N    48   51  4  Census Code (American Indian/Alaska Native Area/Hawaiian Home Land), Current
    AIHHTLICU  Yes  L    A   52   52  1  American Indian/Hawaiian Home Land Trust Land Indicator, Current
    ANRCCU     Yes  L    N   53   57  5  FIPS 55 Code (ANRC), Current
    AITSCECU   Yes  L    N   58   60  3  Census Code (American Indian Tribal Subdivision), Current
    AITSCU     Yes  L    N   61   65  5  FIPS 55 Code (American Indian Tribal Subdivision), Current
    CONCITCU   Yes  L   N    66   70  5  FIPS 55 Code (Consolidated City), Current
    COUSUBCU   No   L   N    71   75  5  FIPS 55 Code (County Subdivision), Current
    SUBMCDCU   Yes  L    N   76   80  5  FIPS 55 Code (Subbarrio), Current
    PLACECU    Yes  L    N   81   85  5  FIPS 55 Code (Incorporated Place), Current
    SDELMCU    Yes  L    A   86   90  5  Elementary School District Code, Current
    SDSECCU    Yes  L    A   91   95  5  Secondary School District Code, Current
    SDUNICU    Yes  L    A   96  100  5  Unified School District Code, Current
    RS-A20     Yes  L   N   101  104  4  Reserved Space A20
    RS-A21     Yes  L   N   105  108  4  Reserved Space A21
    RS-A22     Yes  L   N    109 112  4 Reserved Space A22
    CDCU       Yes	R N 113 114  2 Congressional District Code, Current (108th)
    ZCTA5CU    Yes	L A 115 119  5 5-Digit ZIP Code Tabulation Area, current
    ZCTA3CU    Yes	R A 120 122  3 3-Digit ZIP Code Tabulation Area, current
    RS-A4      Yes	R A 123 128  6 Reserved Space A4
    SLDUCU     Yes  R A 129 131  3 State Legislative District Upper, Current (2006) 
    SLDLCU     Yes  R A 132 134  3 State Legislative District Lower, Current (2006) 
    RS-A7      Yes	R A 135 139  5 Reserved Space A7
    RS-A8      Yes	R A 140 145  6 Reserved Space A8
    RS-A9      Yes	L A 146 151  6 Reserved Space A9
    CBSACU     Yes	L N 152 156  5 FIPS Metropolitan Statistical Area/ Micropolitan Statistical Area Code, Current
    CSACU      Yes	L N 157 159  3 FIPS Combined Statistical Area Code, Current
    NECTACU    Yes	L N 160 164  5 FIPS New England City and Town Area Code, Current
    CNECTACU   Yes	L N 165 167  3 FIPS Combined New England City and Town Area Code, Current
    METDIVCU   Yes L N 168 172  5 FIPS Metropolitan Division Code, Current
    NECTADIVCU Yes L N 173 177  5 FIPS New England City and Town Area Division Code, Current
    RS-A14     Yes L A 178 181  4 Reserved Space A14
    UACU       Yes L N 182 186  5 Urban Area, Current 
    URCU       Yes L A 187 187  1 Urban/Rural Indicator, Current
    RS-A17     Yes L A 188 193  6 Reserved Space A17
    RS-A18     Yes L A 194 199  6 Reserved Space A18
    RS-A19     Yes L A 200 210 11 Reserved Space A19
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
