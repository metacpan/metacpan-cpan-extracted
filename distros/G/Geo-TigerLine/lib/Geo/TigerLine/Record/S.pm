package Geo::TigerLine::Record::S;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'ua' => {
                         'len' => 5,
                         'beg' => 146,
                         'bv' => 'Yes',
                         'fieldnum' => 35,
                         'type' => 'N',
                         'description' => 'Urban Area, 2000',
                         'end' => 150,
                         'fmt' => 'L',
                         'field' => 'ua'
                       },
               'necma' => {
                            'len' => 4,
                            'beg' => 108,
                            'bv' => 'Yes',
                            'fieldnum' => 26,
                            'type' => 'N',
                            'description' => 'FIPS New England County Metropolitan Area (NECMA) Code, 2000',
                            'end' => 111,
                            'fmt' => 'L',
                            'field' => 'necma'
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
               'sldu' => {
                           'len' => 3,
                           'beg' => 158,
                           'bv' => 'Yes',
                           'fieldnum' => 38,
                           'type' => 'A',
                           'description' => 'State Legislative District Code (Upper Chamber), 2000',
                           'end' => 160,
                           'fmt' => 'R',
                           'field' => 'sldu'
                         },
               'sdelm' => {
                            'len' => 5,
                            'beg' => 85,
                            'bv' => 'Yes',
                            'fieldnum' => 21,
                            'type' => 'N',
                            'description' => 'Elementary School District Code, 2000',
                            'end' => 89,
                            'fmt' => 'L',
                            'field' => 'sdelm'
                          },
               'aianhhfp' => {
                               'len' => 5,
                               'beg' => 42,
                               'bv' => 'Yes',
                               'fieldnum' => 11,
                               'type' => 'N',
                               'description' => 'FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000',
                               'end' => 46,
                               'fmt' => 'L',
                               'field' => 'aianhhfp'
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
               'state' => {
                            'len' => 2,
                            'beg' => 26,
                            'bv' => 'No',
                            'fieldnum' => 6,
                            'type' => 'N',
                            'description' => 'FIPS State Code, 2000',
                            'end' => 27,
                            'fmt' => 'L',
                            'field' => 'state'
                          },
               'submcd' => {
                             'len' => 5,
                             'beg' => 75,
                             'bv' => 'Yes',
                             'fieldnum' => 19,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (Subbarrio), 2000',
                             'end' => 79,
                             'fmt' => 'L',
                             'field' => 'submcd'
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
               'puma1' => {
                            'len' => 5,
                            'beg' => 121,
                            'bv' => 'Yes',
                            'fieldnum' => 30,
                            'type' => 'N',
                            'description' => 'Public Use Microdata Area  1% File, 2000',
                            'end' => 125,
                            'fmt' => 'L',
                            'field' => 'puma1'
                          },
               'aitsce' => {
                             'len' => 3,
                             'beg' => 57,
                             'bv' => 'Yes',
                             'fieldnum' => 15,
                             'type' => 'N',
                             'description' => 'Census Code (American Indian Tribal Subdivision), 2000',
                             'end' => 59,
                             'fmt' => 'L',
                             'field' => 'aitsce'
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
               'pmsa' => {
                           'len' => 4,
                           'beg' => 104,
                           'bv' => 'Yes',
                           'fieldnum' => 25,
                           'type' => 'N',
                           'description' => 'FIPS Primary Metropolitan Statistical Area Code, 2000',
                           'end' => 107,
                           'fmt' => 'L',
                           'field' => 'pmsa'
                         },
               'tazcomb' => {
                              'len' => 6,
                              'beg' => 140,
                              'bv' => 'Yes',
                              'fieldnum' => 34,
                              'type' => 'A',
                              'description' => 'Traffic Analysis Zone Code-State Combined, 2000 (not filled)',
                              'end' => 145,
                              'fmt' => 'L',
                              'field' => 'tazcomb'
                            },
               'concit' => {
                             'len' => 5,
                             'beg' => 65,
                             'bv' => 'Yes',
                             'fieldnum' => 17,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (Consolidated City), 2000',
                             'end' => 69,
                             'fmt' => 'L',
                             'field' => 'concit'
                           },
               'county' => {
                             'len' => 3,
                             'beg' => 28,
                             'bv' => 'No',
                             'fieldnum' => 7,
                             'type' => 'N',
                             'description' => 'FIPS County Code, 2000',
                             'end' => 30,
                             'fmt' => 'L',
                             'field' => 'county'
                           },
               'ur' => {
                         'len' => 1,
                         'beg' => 151,
                         'bv' => 'Yes',
                         'fieldnum' => 36,
                         'type' => 'A',
                         'description' => 'Urban/Rural Indicator, 2000',
                         'end' => 151,
                         'fmt' => 'L',
                         'field' => 'ur'
                       },
               'place' => {
                            'len' => 5,
                            'beg' => 80,
                            'bv' => 'Yes',
                            'fieldnum' => 20,
                            'type' => 'N',
                            'description' => 'FIPS 55 Code (Incorporated Place/CDP), 2000',
                            'end' => 84,
                            'fmt' => 'L',
                            'field' => 'place'
                          },
               'blkgrp' => {
                             'len' => 1,
                             'beg' => 41,
                             'bv' => 'No',
                             'fieldnum' => 10,
                             'type' => 'N',
                             'description' => 'Census Block Group, 2000',
                             'end' => 41,
                             'fmt' => 'L',
                             'field' => 'blkgrp'
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
               'aits' => {
                           'len' => 5,
                           'beg' => 60,
                           'bv' => 'Yes',
                           'fieldnum' => 16,
                           'type' => 'N',
                           'description' => 'FIPS 55 Code (American Indian Tribal Subdivision), 2000',
                           'end' => 64,
                           'fmt' => 'L',
                           'field' => 'aits'
                         },
               'sldl' => {
                           'len' => 3,
                           'beg' => 161,
                           'bv' => 'Yes',
                           'fieldnum' => 39,
                           'type' => 'A',
                           'description' => 'State Legislative District Code (Lower Chamber), 2000',
                           'end' => 163,
                           'fmt' => 'R',
                           'field' => 'sldl'
                         },
               'sdsec' => {
                            'len' => 5,
                            'beg' => 90,
                            'bv' => 'Yes',
                            'fieldnum' => 22,
                            'type' => 'N',
                            'description' => 'Secondary School District Code, 2000',
                            'end' => 94,
                            'fmt' => 'L',
                            'field' => 'sdsec'
                          },
               'cousub' => {
                             'len' => 5,
                             'beg' => 70,
                             'bv' => 'No',
                             'fieldnum' => 18,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (County Subdivision), 2000',
                             'end' => 74,
                             'fmt' => 'L',
                             'field' => 'cousub'
                           },
               'aihhtli' => {
                              'len' => 1,
                              'beg' => 51,
                              'bv' => 'Yes',
                              'fieldnum' => 13,
                              'type' => 'A',
                              'description' => 'American Indian/Hawaiian Home Land Trust Land Indicator, 2000',
                              'end' => 51,
                              'fmt' => 'L',
                              'field' => 'aihhtli'
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
               'sduni' => {
                            'len' => 5,
                            'beg' => 95,
                            'bv' => 'Yes',
                            'fieldnum' => 23,
                            'type' => 'N',
                            'description' => 'Unified School District Code, 2000',
                            'end' => 99,
                            'fmt' => 'L',
                            'field' => 'sduni'
                          },
               'uga' => {
                          'len' => 5,
                          'beg' => 164,
                          'bv' => 'Yes',
                          'fieldnum' => 40,
                          'type' => 'A',
                          'description' => 'Oregon Urban Growth Area, 2000',
                          'end' => 168,
                          'fmt' => 'L',
                          'field' => 'uga'
                        },
               'msacmsa' => {
                              'len' => 4,
                              'beg' => 100,
                              'bv' => 'Yes',
                              'fieldnum' => 24,
                              'type' => 'N',
                              'description' => 'FIPS Consolidated Metropolitan Statistical Area/Metropolitan Statistical Area Code, 2000',
                              'end' => 103,
                              'fmt' => 'L',
                              'field' => 'msacmsa'
                            },
               'cd106' => {
                            'len' => 2,
                            'beg' => 112,
                            'bv' => 'No',
                            'fieldnum' => 27,
                            'type' => 'N',
                            'description' => 'Congressional District Code, 106th',
                            'end' => 113,
                            'fmt' => 'R',
                            'field' => 'cd106'
                          },
               'vtd' => {
                          'len' => 6,
                          'beg' => 152,
                          'bv' => 'Yes',
                          'fieldnum' => 37,
                          'type' => 'A',
                          'description' => 'Census Voting District Code, 2000',
                          'end' => 157,
                          'fmt' => 'R',
                          'field' => 'vtd'
                        },
               'puma5' => {
                            'len' => 5,
                            'beg' => 116,
                            'bv' => 'Yes',
                            'fieldnum' => 29,
                            'type' => 'N',
                            'description' => 'Public Use Microdata Area  5% File, 2000',
                            'end' => 120,
                            'fmt' => 'L',
                            'field' => 'puma5'
                          },
               'taz' => {
                          'len' => 6,
                          'beg' => 134,
                          'bv' => 'Yes',
                          'fieldnum' => 33,
                          'type' => 'A',
                          'description' => 'Traffic Analysis Zone Code, 2000',
                          'end' => 139,
                          'fmt' => 'L',
                          'field' => 'taz'
                        },
               'aianhh' => {
                             'len' => 4,
                             'beg' => 47,
                             'bv' => 'Yes',
                             'fieldnum' => 12,
                             'type' => 'N',
                             'description' => 'Census Code (American Indian/ Alaska Native Area/Hawaiian Home Land), 2000',
                             'end' => 50,
                             'fmt' => 'L',
                             'field' => 'aianhh'
                           },
               'zcta3' => {
                            'len' => 3,
                            'beg' => 131,
                            'bv' => 'Yes',
                            'fieldnum' => 32,
                            'type' => 'A',
                            'description' => '3-Digit ZIP Code Tabulation Area, 2000',
                            'end' => 133,
                            'fmt' => 'L',
                            'field' => 'zcta3'
                          },
               'anrc' => {
                           'len' => 5,
                           'beg' => 52,
                           'bv' => 'Yes',
                           'fieldnum' => 14,
                           'type' => 'N',
                           'description' => 'FIPS 55 Code (ANRC), 2000',
                           'end' => 56,
                           'fmt' => 'L',
                           'field' => 'anrc'
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
               'cd108' => {
                            'len' => 2,
                            'beg' => 114,
                            'bv' => 'Yes',
                            'fieldnum' => 28,
                            'type' => 'N',
                            'description' => 'Congressional District Code, 108th',
                            'end' => 115,
                            'fmt' => 'R',
                            'field' => 'cd108'
                          },
               'zcta5' => {
                            'len' => 5,
                            'beg' => 126,
                            'bv' => 'Yes',
                            'fieldnum' => 31,
                            'type' => 'A',
                            'description' => '5-Digit ZIP Code Tabulation Area, 2000',
                            'end' => 130,
                            'fmt' => 'L',
                            'field' => 'zcta5'
                          }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'polyid',
                 'state',
                 'county',
                 'tract',
                 'block',
                 'blkgrp',
                 'aianhhfp',
                 'aianhh',
                 'aihhtli',
                 'anrc',
                 'aitsce',
                 'aits',
                 'concit',
                 'cousub',
                 'submcd',
                 'place',
                 'sdelm',
                 'sdsec',
                 'sduni',
                 'msacmsa',
                 'pmsa',
                 'necma',
                 'cd106',
                 'cd108',
                 'puma5',
                 'puma1',
                 'zcta5',
                 'zcta3',
                 'taz',
                 'tazcomb',
                 'ua',
                 'ur',
                 'vtd',
                 'sldu',
                 'sldl',
                 'uga'
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

Geo::TigerLine::Record::S - TIGER/Line 2006 Polygon Additional Geographic Entity Codes

=head1 SYNOPSIS

  use Geo::TigerLine::Record::S;

  @records = Geo::TigerLine::Record::S->parse_file($fh);
  @records = Geo::TigerLine::Record::S->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::S->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->polyid();
  $record->state();
  $record->county();
  $record->tract();
  $record->block();
  $record->blkgrp();
  $record->aianhhfp();
  $record->aianhh();
  $record->aihhtli();
  $record->anrc();
  $record->aitsce();
  $record->aits();
  $record->concit();
  $record->cousub();
  $record->submcd();
  $record->place();
  $record->sdelm();
  $record->sdsec();
  $record->sduni();
  $record->msacmsa();
  $record->pmsa();
  $record->necma();
  $record->cd106();
  $record->cd108();
  $record->puma5();
  $record->puma1();
  $record->zcta5();
  $record->zcta3();
  $record->taz();
  $record->tazcomb();
  $record->ua();
  $record->ur();
  $record->vtd();
  $record->sldu();
  $record->sldl();
  $record->uga();


=head1 DESCRIPTION

This is a class representing record type S of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type S files and turn them
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


=item B<state>

    $data = $record->state();
    $record->state($data);

FIPS State Code, 2000.  

Expects numeric data of no more than 2 characters.  $data cannot be blank 
and should be left justified.


=item B<county>

    $data = $record->county();
    $record->county($data);

FIPS County Code, 2000.  

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


=item B<blkgrp>

    $data = $record->blkgrp();
    $record->blkgrp($data);

Census Block Group, 2000.  

Expects numeric data of no more than 1 characters.  $data cannot be blank 
and should be left justified.


=item B<aianhhfp>

    $data = $record->aianhhfp();
    $record->aianhhfp($data);

FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aianhh>

    $data = $record->aianhh();
    $record->aianhh($data);

Census Code (American Indian/ Alaska Native Area/Hawaiian Home Land), 2000.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<aihhtli>

    $data = $record->aihhtli();
    $record->aihhtli($data);

American Indian/Hawaiian Home Land Trust Land Indicator, 2000.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<anrc>

    $data = $record->anrc();
    $record->anrc($data);

FIPS 55 Code (ANRC), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aitsce>

    $data = $record->aitsce();
    $record->aitsce($data);

Census Code (American Indian Tribal Subdivision), 2000.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<aits>

    $data = $record->aits();
    $record->aits($data);

FIPS 55 Code (American Indian Tribal Subdivision), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<concit>

    $data = $record->concit();
    $record->concit($data);

FIPS 55 Code (Consolidated City), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<cousub>

    $data = $record->cousub();
    $record->cousub($data);

FIPS 55 Code (County Subdivision), 2000.  

Expects numeric data of no more than 5 characters.  $data cannot be blank 
and should be left justified.


=item B<submcd>

    $data = $record->submcd();
    $record->submcd($data);

FIPS 55 Code (Subbarrio), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<place>

    $data = $record->place();
    $record->place($data);

FIPS 55 Code (Incorporated Place/CDP), 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sdelm>

    $data = $record->sdelm();
    $record->sdelm($data);

Elementary School District Code, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sdsec>

    $data = $record->sdsec();
    $record->sdsec($data);

Secondary School District Code, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<sduni>

    $data = $record->sduni();
    $record->sduni($data);

Unified School District Code, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<msacmsa>

    $data = $record->msacmsa();
    $record->msacmsa($data);

FIPS Consolidated Metropolitan Statistical Area/Metropolitan Statistical Area Code, 2000.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<pmsa>

    $data = $record->pmsa();
    $record->pmsa($data);

FIPS Primary Metropolitan Statistical Area Code, 2000.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<necma>

    $data = $record->necma();
    $record->necma($data);

FIPS New England County Metropolitan Area (NECMA) Code, 2000.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<cd106>

    $data = $record->cd106();
    $record->cd106($data);

Congressional District Code, 106th.  

Expects numeric data of no more than 2 characters.  $data cannot be blank 
and should be right justified.


=item B<cd108>

    $data = $record->cd108();
    $record->cd108($data);

Congressional District Code, 108th.  

Expects numeric data of no more than 2 characters.  $data can be blank 
and should be right justified.


=item B<puma5>

    $data = $record->puma5();
    $record->puma5($data);

Public Use Microdata Area  5% File, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<puma1>

    $data = $record->puma1();
    $record->puma1($data);

Public Use Microdata Area  1% File, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<zcta5>

    $data = $record->zcta5();
    $record->zcta5($data);

5-Digit ZIP Code Tabulation Area, 2000.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<zcta3>

    $data = $record->zcta3();
    $record->zcta3($data);

3-Digit ZIP Code Tabulation Area, 2000.  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<taz>

    $data = $record->taz();
    $record->taz($data);

Traffic Analysis Zone Code, 2000.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<tazcomb>

    $data = $record->tazcomb();
    $record->tazcomb($data);

Traffic Analysis Zone Code-State Combined, 2000 (not filled).  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<ua>

    $data = $record->ua();
    $record->ua($data);

Urban Area, 2000.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<ur>

    $data = $record->ur();
    $record->ur($data);

Urban/Rural Indicator, 2000.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<vtd>

    $data = $record->vtd();
    $record->vtd($data);

Census Voting District Code, 2000.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be right justified.


=item B<sldu>

    $data = $record->sldu();
    $record->sldu($data);

State Legislative District Code (Upper Chamber), 2000.  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be right justified.


=item B<sldl>

    $data = $record->sldl();
    $record->sldl($data);

State Legislative District Code (Lower Chamber), 2000.  

Expects alphanumeric data of no more than 3 characters.  $data can be blank 
and should be right justified.


=item B<uga>

    $data = $record->uga();
    $record->uga($data);

Oregon Urban Growth Area, 2000.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type S - Polygon Additional Geographic Entity Codes
    
    Field    BV  Fmt Type Beg End Len Description
    RT       No    L  A     1   1   1 Record Type
    VERSION  No    L  N     2   5   4 Version Number
    FILE     No    L  N     6  10   5 File Code
    CENID    No    L  A    11  15   5 Census File Identification Code
    POLYID   No   R   N    16  25  10 Polygon Identification Code
    STATE    No    L  N    26  27   2 FIPS State Code, 2000
    COUNTY   No    L  N    28  30   3 FIPS County Code, 2000
    TRACT    No    L  N    31  36   6 Census Tract, 2000
    BLOCK    No    L  N    37  40   4 Census Block Number, 2000
    BLKGRP   No    L  N    41  41   1 Census Block Group, 2000
    AIANHHFP Yes   L  N    42  46   5 FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000
    AIANHH   Yes   L  N    47  50   4 Census Code (American Indian/ Alaska Native Area/Hawaiian Home Land), 2000
    AIHHTLI  Yes   L  A    51  51   1 American Indian/Hawaiian Home Land Trust Land Indicator, 2000
    ANRC     Yes   L  N    52  56   5 FIPS 55 Code (ANRC), 2000
    AITSCE   Yes   L  N    57  59   3 Census Code (American Indian Tribal Subdivision), 2000
    AITS     Yes   L  N    60  64   5 FIPS 55 Code (American Indian Tribal Subdivision), 2000
    CONCIT   Yes   L  N    65  69   5 FIPS 55 Code (Consolidated City), 2000
    COUSUB   No    L  N    70  74   5 FIPS 55 Code (County Subdivision), 2000
    SUBMCD   Yes   L  N    75  79   5 FIPS 55 Code (Subbarrio), 2000
    PLACE    Yes   L  N    80  84   5 FIPS 55 Code (Incorporated Place/CDP), 2000
    SDELM    Yes   L  N    85  89   5 Elementary School District Code, 2000
    SDSEC    Yes   L  N    90  94   5 Secondary School District Code, 2000
    SDUNI    Yes  L   N    95  99   5 Unified School District Code, 2000
    MSACMSA  Yes  L   N   100 103   4 FIPS Consolidated Metropolitan Statistical Area/Metropolitan Statistical Area Code, 2000
    PMSA     Yes  L   N   104 107   4 FIPS Primary Metropolitan Statistical Area Code, 2000
    NECMA    Yes  L   N   108 111   4 FIPS New England County Metropolitan Area (NECMA) Code, 2000
    CD106    No   R   N   112 113   2 Congressional District Code, 106th
    CD108    Yes  R   N   114 115   2 Congressional District Code, 108th
    PUMA5    Yes  L   N   116 120   5 Public Use Microdata Area  5% File, 2000
    PUMA1    Yes  L   N   121 125   5 Public Use Microdata Area  1% File, 2000
    ZCTA5   Yes L A 126 130 5 5-Digit ZIP Code Tabulation Area, 2000
    ZCTA3   Yes L A 131 133 3 3-Digit ZIP Code Tabulation Area, 2000
    TAZ     Yes L A 134 139 6 Traffic Analysis Zone Code, 2000
    TAZCOMB Yes L A 140 145 6 Traffic Analysis Zone Code-State Combined, 2000 (not filled)
    UA      Yes L N 146 150 5 Urban Area, 2000
    UR      Yes L A 151 151 1 Urban/Rural Indicator, 2000
    VTD     Yes R A 152 157 6 Census Voting District Code, 2000
    SLDU    Yes R A 158 160 3 State Legislative District Code (Upper Chamber), 2000
    SLDL    Yes R A 161 163 3 State Legislative District Code (Lower Chamber), 2000
    UGA     Yes L A 164 168 5 Oregon Urban Growth Area, 2000



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
