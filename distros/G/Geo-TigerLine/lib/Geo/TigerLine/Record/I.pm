package Geo::TigerLine::Record::I;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'polyidr' => {
                              'len' => 10,
                              'beg' => 61,
                              'bv' => 'Yes',
                              'fieldnum' => 10,
                              'type' => 'N',
                              'description' => 'Polygon Identification Code, Right',
                              'end' => 70,
                              'fmt' => 'R',
                              'field' => 'polyidr'
                            },
               'tzide' => {
                            'len' => 10,
                            'beg' => 31,
                            'bv' => 'No',
                            'fieldnum' => 6,
                            'type' => 'N',
                            'description' => 'TIGER ID, End, Permanent Zero-Cell Number',
                            'end' => 40,
                            'fmt' => 'R',
                            'field' => 'tzide'
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
               'cenidr' => {
                             'len' => 5,
                             'beg' => 56,
                             'bv' => 'Yes',
                             'fieldnum' => 9,
                             'type' => 'A',
                             'description' => 'Census File Identification Code, Right',
                             'end' => 60,
                             'fmt' => 'L',
                             'field' => 'cenidr'
                           },
               'rs_i1' => {
                            'len' => 10,
                            'beg' => 98,
                            'bv' => 'Yes',
                            'fieldnum' => 13,
                            'type' => 'A',
                            'description' => 'Reserved Space I1',
                            'end' => 107,
                            'fmt' => 'L',
                            'field' => 'rs_i1'
                          },
               'cenidl' => {
                             'len' => 5,
                             'beg' => 41,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Census File Identification Code, Left',
                             'end' => 45,
                             'fmt' => 'L',
                             'field' => 'cenidl'
                           },
               'ftseg' => {
                            'len' => 17,
                            'beg' => 81,
                            'bv' => 'Yes',
                            'fieldnum' => 12,
                            'type' => 'A',
                            'description' => 'FTSeg ID (AAAAA.O.XXXXXXXXX) (Authority-S-ID) FGDC Transportation ID Standard (not filled)',
                            'end' => 97,
                            'fmt' => 'L',
                            'field' => 'ftseg'
                          },
               'tlid' => {
                           'len' => 10,
                           'beg' => 11,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'TIGER/Line ID, Permanent 1-Cell Number',
                           'end' => 20,
                           'fmt' => 'R',
                           'field' => 'tlid'
                         },
               'rs_i3' => {
                            'len' => 10,
                            'beg' => 118,
                            'bv' => 'Yes',
                            'fieldnum' => 15,
                            'type' => 'A',
                            'description' => 'Reserved Space I3',
                            'end' => 127,
                            'fmt' => 'L',
                            'field' => 'rs_i3'
                          },
               'rs_i2' => {
                            'len' => 10,
                            'beg' => 108,
                            'bv' => 'Yes',
                            'fieldnum' => 14,
                            'type' => 'A',
                            'description' => 'Reserved Space I2',
                            'end' => 117,
                            'fmt' => 'L',
                            'field' => 'rs_i2'
                          },
               'rs_i4' => {
                            'len' => 10,
                            'beg' => 71,
                            'bv' => 'Yes',
                            'fieldnum' => 11,
                            'type' => 'A',
                            'description' => 'Reserved Space I-4',
                            'end' => 80,
                            'fmt' => 'L',
                            'field' => 'rs_i4'
                          },
               'tzids' => {
                            'len' => 10,
                            'beg' => 21,
                            'bv' => 'No',
                            'fieldnum' => 5,
                            'type' => 'N',
                            'description' => 'TIGER ID, Start, Permanent Zero-Cell Number',
                            'end' => 30,
                            'fmt' => 'R',
                            'field' => 'tzids'
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
               'polyidl' => {
                              'len' => 10,
                              'beg' => 46,
                              'bv' => 'Yes',
                              'fieldnum' => 8,
                              'type' => 'N',
                              'description' => 'Polygon Identification Code, Left',
                              'end' => 55,
                              'fmt' => 'R',
                              'field' => 'polyidl'
                            }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'tlid',
                 'tzids',
                 'tzide',
                 'cenidl',
                 'polyidl',
                 'cenidr',
                 'polyidr',
                 'rs_i4',
                 'ftseg',
                 'rs_i1',
                 'rs_i2',
                 'rs_i3'
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

Geo::TigerLine::Record::I - TIGER/Line 2006 Link Between Complete Chains and Polygons

=head1 SYNOPSIS

  use Geo::TigerLine::Record::I;

  @records = Geo::TigerLine::Record::I->parse_file($fh);
  @records = Geo::TigerLine::Record::I->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::I->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->tlid();
  $record->tzids();
  $record->tzide();
  $record->cenidl();
  $record->polyidl();
  $record->cenidr();
  $record->polyidr();
  $record->rs_i4();
  $record->ftseg();
  $record->rs_i1();
  $record->rs_i2();
  $record->rs_i3();


=head1 DESCRIPTION

This is a class representing record type I of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type I files and turn them
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


=item B<tlid>

    $data = $record->tlid();
    $record->tlid($data);

TIGER/Line ID, Permanent 1-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tzids>

    $data = $record->tzids();
    $record->tzids($data);

TIGER ID, Start, Permanent Zero-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tzide>

    $data = $record->tzide();
    $record->tzide($data);

TIGER ID, End, Permanent Zero-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<cenidl>

    $data = $record->cenidl();
    $record->cenidl($data);

Census File Identification Code, Left.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<polyidl>

    $data = $record->polyidl();
    $record->polyidl($data);

Polygon Identification Code, Left.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<cenidr>

    $data = $record->cenidr();
    $record->cenidr($data);

Census File Identification Code, Right.  

Expects alphanumeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<polyidr>

    $data = $record->polyidr();
    $record->polyidr($data);

Polygon Identification Code, Right.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<rs_i4>

    $data = $record->rs_i4();
    $record->rs_i4($data);

Reserved Space I-4.  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.


=item B<ftseg>

    $data = $record->ftseg();
    $record->ftseg($data);

FTSeg ID (AAAAA.O.XXXXXXXXX) (Authority-S-ID) FGDC Transportation ID Standard (not filled).  

Expects alphanumeric data of no more than 17 characters.  $data can be blank 
and should be left justified.


=item B<rs_i1>

    $data = $record->rs_i1();
    $record->rs_i1($data);

Reserved Space I1.  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.


=item B<rs_i2>

    $data = $record->rs_i2();
    $record->rs_i2($data);

Reserved Space I2.  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.


=item B<rs_i3>

    $data = $record->rs_i3();
    $record->rs_i3($data);

Reserved Space I3.  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type I - Link Between Complete Chains and Polygons
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L   A     1   1  1  Record Type
    VERSION No   L   N     2   5  4  Version Number
    FILE    No   L   N     6  10  5  File Code
    TLID    No   R   N    11  20 10  TIGER/Line ID, Permanent 1-Cell Number
    TZIDS   No   R   N    21  30 10  TIGER ID, Start, Permanent Zero-Cell Number
    TZIDE   No   R   N    31  40 10  TIGER ID, End, Permanent Zero-Cell Number
    CENIDL  Yes  L   A    41  45  5  Census File Identification Code, Left
    POLYIDL Yes  R   N    46  55 10  Polygon Identification Code, Left
    CENIDR  Yes  L   A    56  60  5  Census File Identification Code, Right
    POLYIDR Yes  R   N    61  70 10  Polygon Identification Code, Right
    RS-I4   Yes  L   A    71  80 10  Reserved Space I-4
    FTSEG   Yes  L   A    81  97 17  FTSeg ID (AAAAA.O.XXXXXXXXX) (Authority-S-ID) FGDC Transportation ID Standard (not filled)
    RS-I1   Yes  L   A    98 107 10  Reserved Space I1
    RS-I2   Yes  L   A   108 117 10  Reserved Space I2
    RS-I3   Yes  L   A   118 127 10  Reserved Space I3



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
