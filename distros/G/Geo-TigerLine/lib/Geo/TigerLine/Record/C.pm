package Geo::TigerLine::Record::C;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'vtdtract' => {
                               'len' => 6,
                               'beg' => 39,
                               'bv' => 'Yes',
                               'fieldnum' => 14,
                               'type' => 'A',
                               'description' => 'Census Voting District Code/Census Tract Code',
                               'end' => 44,
                               'fmt' => 'R',
                               'field' => 'vtdtract'
                             },
               'commreg' => {
                              'len' => 1,
                              'beg' => 61,
                              'bv' => 'Yes',
                              'fieldnum' => 19,
                              'type' => 'N',
                              'description' => 'Commercial Region Code, Economic Census',
                              'end' => 61,
                              'fmt' => 'L',
                              'field' => 'commreg'
                            },
               'state' => {
                            'len' => 2,
                            'beg' => 6,
                            'bv' => 'Yes',
                            'fieldnum' => 3,
                            'type' => 'N',
                            'description' => 'FIPS State Code',
                            'end' => 7,
                            'fmt' => 'L',
                            'field' => 'state'
                          },
               'cbsanecta' => {
                                'len' => 5,
                                'beg' => 56,
                                'bv' => 'Yes',
                                'fieldnum' => 18,
                                'type' => 'N',
                                'description' => 'Metropolitan Statistical Area/Micropolitan Statistical Area/New England City and Town Area/Metropolitan Division/New England City and Town Area Division Code',
                                'end' => 60,
                                'fmt' => 'L',
                                'field' => 'cbsanecta'
                              },
               'entity' => {
                             'len' => 1,
                             'beg' => 25,
                             'bv' => 'No',
                             'fieldnum' => 10,
                             'type' => 'A',
                             'description' => 'Entity Type Code',
                             'end' => 25,
                             'fmt' => 'L',
                             'field' => 'entity'
                           },
               'ma' => {
                         'len' => 4,
                         'beg' => 26,
                         'bv' => 'Yes',
                         'fieldnum' => 11,
                         'type' => 'N',
                         'description' => 'Metropolitan Area Code',
                         'end' => 29,
                         'fmt' => 'L',
                         'field' => 'ma'
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
               'fipscc' => {
                             'len' => 2,
                             'beg' => 20,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'FIPS 55 Class Code',
                             'end' => 21,
                             'fmt' => 'L',
                             'field' => 'fipscc'
                           },
               'datayr' => {
                             'len' => 4,
                             'beg' => 11,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'FIPS Code, Name, and/or Attribute Data Applicable Year',
                             'end' => 14,
                             'fmt' => 'L',
                             'field' => 'datayr'
                           },
               'placedc' => {
                              'len' => 1,
                              'beg' => 22,
                              'bv' => 'Yes',
                              'fieldnum' => 8,
                              'type' => 'A',
                              'description' => 'Place Description Code',
                              'end' => 22,
                              'fmt' => 'L',
                              'field' => 'placedc'
                            },
               'aitsce' => {
                             'len' => 3,
                             'beg' => 50,
                             'bv' => 'Yes',
                             'fieldnum' => 16,
                             'type' => 'N',
                             'description' => 'Census American Indian Tribal Subdivision Code',
                             'end' => 52,
                             'fmt' => 'L',
                             'field' => 'aitsce'
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
               'casld' => {
                            'len' => 3,
                            'beg' => 53,
                            'bv' => 'Yes',
                            'fieldnum' => 17,
                            'type' => 'N',
                            'description' => 'Combined Statistical Area/Combined New England City and Town Area/State Legislative District (Upper and Lower Chambers) Code',
                            'end' => 55,
                            'fmt' => 'L',
                            'field' => 'casld'
                          },
               'name' => {
                           'len' => 60,
                           'beg' => 63,
                           'bv' => 'Yes',
                           'fieldnum' => 21,
                           'type' => 'A',
                           'description' => 'Name of Geographic Area',
                           'end' => 122,
                           'fmt' => 'L',
                           'field' => 'name'
                         },
               'fips' => {
                           'len' => 5,
                           'beg' => 15,
                           'bv' => 'Yes',
                           'fieldnum' => 6,
                           'type' => 'N',
                           'description' => 'FIPS PUB 55-3 Code',
                           'end' => 19,
                           'fmt' => 'L',
                           'field' => 'fips'
                         },
               'rs_c2' => {
                            'len' => 1,
                            'beg' => 62,
                            'bv' => 'Yes',
                            'fieldnum' => 20,
                            'type' => 'N',
                            'description' => 'Reserved Space C2',
                            'end' => 62,
                            'fmt' => 'L',
                            'field' => 'rs_c2'
                          },
               'uauga' => {
                            'len' => 5,
                            'beg' => 45,
                            'bv' => 'Yes',
                            'fieldnum' => 15,
                            'type' => 'N',
                            'description' => 'Urban Area Code/Urban Growth Area Code',
                            'end' => 49,
                            'fmt' => 'L',
                            'field' => 'uauga'
                          },
               'lsadc' => {
                            'len' => 2,
                            'beg' => 23,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'A',
                            'description' => 'Legal/Statistical Area Description Code',
                            'end' => 24,
                            'fmt' => 'L',
                            'field' => 'lsadc'
                          },
               'aianhh' => {
                             'len' => 4,
                             'beg' => 35,
                             'bv' => 'Yes',
                             'fieldnum' => 13,
                             'type' => 'N',
                             'description' => 'Census American Indian/Alaska Native Area/Hawaiian Home Land Code',
                             'end' => 38,
                             'fmt' => 'L',
                             'field' => 'aianhh'
                           },
               'county' => {
                             'len' => 3,
                             'beg' => 8,
                             'bv' => 'Yes',
                             'fieldnum' => 4,
                             'type' => 'N',
                             'description' => 'FIPS County Code',
                             'end' => 10,
                             'fmt' => 'L',
                             'field' => 'county'
                           },
               'sd' => {
                         'len' => 5,
                         'beg' => 30,
                         'bv' => 'Yes',
                         'fieldnum' => 12,
                         'type' => 'N',
                         'description' => 'School District Code',
                         'end' => 34,
                         'fmt' => 'L',
                         'field' => 'sd'
                       }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'state',
                 'county',
                 'datayr',
                 'fips',
                 'fipscc',
                 'placedc',
                 'lsadc',
                 'entity',
                 'ma',
                 'sd',
                 'aianhh',
                 'vtdtract',
                 'uauga',
                 'aitsce',
                 'casld',
                 'cbsanecta',
                 'commreg',
                 'rs_c2',
                 'name'
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

Geo::TigerLine::Record::C - TIGER/Line 2006 Geographic Entity Names

=head1 SYNOPSIS

  use Geo::TigerLine::Record::C;

  @records = Geo::TigerLine::Record::C->parse_file($fh);
  @records = Geo::TigerLine::Record::C->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::C->new(\%fields);

  $record->rt();
  $record->version();
  $record->state();
  $record->county();
  $record->datayr();
  $record->fips();
  $record->fipscc();
  $record->placedc();
  $record->lsadc();
  $record->entity();
  $record->ma();
  $record->sd();
  $record->aianhh();
  $record->vtdtract();
  $record->uauga();
  $record->aitsce();
  $record->casld();
  $record->cbsanecta();
  $record->commreg();
  $record->rs_c2();
  $record->name();


=head1 DESCRIPTION

This is a class representing record type C of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type C files and turn them
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


=item B<state>

    $data = $record->state();
    $record->state($data);

FIPS State Code.  

Expects numeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<county>

    $data = $record->county();
    $record->county($data);

FIPS County Code.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<datayr>

    $data = $record->datayr();
    $record->datayr($data);

FIPS Code, Name, and/or Attribute Data Applicable Year.  

Expects alphanumeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<fips>

    $data = $record->fips();
    $record->fips($data);

FIPS PUB 55-3 Code.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<fipscc>

    $data = $record->fipscc();
    $record->fipscc($data);

FIPS 55 Class Code.  

Expects alphanumeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<placedc>

    $data = $record->placedc();
    $record->placedc($data);

Place Description Code.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<lsadc>

    $data = $record->lsadc();
    $record->lsadc($data);

Legal/Statistical Area Description Code.  

Expects alphanumeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<entity>

    $data = $record->entity();
    $record->entity($data);

Entity Type Code.  

Expects alphanumeric data of no more than 1 characters.  $data cannot be blank 
and should be left justified.


=item B<ma>

    $data = $record->ma();
    $record->ma($data);

Metropolitan Area Code.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<sd>

    $data = $record->sd();
    $record->sd($data);

School District Code.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aianhh>

    $data = $record->aianhh();
    $record->aianhh($data);

Census American Indian/Alaska Native Area/Hawaiian Home Land Code.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<vtdtract>

    $data = $record->vtdtract();
    $record->vtdtract($data);

Census Voting District Code/Census Tract Code.  

Expects alphanumeric data of no more than 6 characters.  $data can be blank 
and should be right justified.


=item B<uauga>

    $data = $record->uauga();
    $record->uauga($data);

Urban Area Code/Urban Growth Area Code.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aitsce>

    $data = $record->aitsce();
    $record->aitsce($data);

Census American Indian Tribal Subdivision Code.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<casld>

    $data = $record->casld();
    $record->casld($data);

Combined Statistical Area/Combined New England City and Town Area/State Legislative District (Upper and Lower Chambers) Code.  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<cbsanecta>

    $data = $record->cbsanecta();
    $record->cbsanecta($data);

Metropolitan Statistical Area/Micropolitan Statistical Area/New England City and Town Area/Metropolitan Division/New England City and Town Area Division Code.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<commreg>

    $data = $record->commreg();
    $record->commreg($data);

Commercial Region Code, Economic Census.  

Expects numeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<rs_c2>

    $data = $record->rs_c2();
    $record->rs_c2($data);

Reserved Space C2.  

Expects numeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<name>

    $data = $record->name();
    $record->name($data);

Name of Geographic Area.  

Expects alphanumeric data of no more than 60 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type C - Geographic Entity Names
    
    Field     BV   Fmt Type Beg End Len Description
    RT        No    L   A    1    1  1  Record Type
    VERSION   No    L   N    2    5  4  Version Number
    STATE     Yes   L   N    6    7  2  FIPS State Code
    COUNTY    Yes   L   N    8   10  3  FIPS County Code
    DATAYR    Yes   L   A   11   14  4  FIPS Code, Name, and/or Attribute Data Applicable Year
    FIPS      Yes   L   N   15   19  5  FIPS PUB 55-3 Code
    FIPSCC    Yes   L   A   20   21  2  FIPS 55 Class Code
    PLACEDC   Yes   L   A   22   22  1  Place Description Code
    LSADC     Yes   L   A   23   24  2  Legal/Statistical Area Description Code
    ENTITY    No    L   A   25   25  1  Entity Type Code
    MA        Yes   L   N   26   29  4  Metropolitan Area Code
    SD        Yes   L   N   30   34  5  School District Code
    AIANHH    Yes   L   N   35   38  4  Census American Indian/Alaska Native Area/Hawaiian Home Land Code
    VTDTRACT  Yes   R   A   39   44  6  Census Voting District Code/Census Tract Code
    UAUGA     Yes   L   N   45   49  5  Urban Area Code/Urban Growth Area Code
    AITSCE     Yes  L   N   50   52  3  Census American Indian Tribal Subdivision Code
    CASLD      Yes  L   N   53   55  3  Combined Statistical Area/Combined New England City and Town Area/State Legislative District (Upper and Lower Chambers) Code
    CBSANECTA  Yes  L   N   56   60  5  Metropolitan Statistical Area/Micropolitan Statistical Area/New England City and Town Area/Metropolitan Division/New England City and Town Area Division Code
    COMMREG    Yes  L   N   61   61  1  Commercial Region Code, Economic Census
    RS-C2      Yes  L   N   62   62  1  Reserved Space C2
    NAME       Yes  L   A   63  122 60  Name of Geographic Area



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
