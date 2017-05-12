package Geo::TigerLine::Record::M;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'rs_m3' => {
                            'len' => 23,
                            'beg' => 68,
                            'bv' => 'Yes',
                            'fieldnum' => 10,
                            'type' => 'N',
                            'description' => 'Reserved Space M3',
                            'end' => 90,
                            'fmt' => 'L',
                            'field' => 'rs_m3'
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
               'idflag' => {
                             'len' => 1,
                             'beg' => 47,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Identification Code Flag',
                             'end' => 47,
                             'fmt' => 'R',
                             'field' => 'idflag'
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
               'sourceid' => {
                               'len' => 10,
                               'beg' => 19,
                               'bv' => 'Yes',
                               'fieldnum' => 5,
                               'type' => 'A',
                               'description' => 'TIGER 1-Cell Source Code',
                               'end' => 28,
                               'fmt' => 'L',
                               'field' => 'sourceid'
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
               'rs_m1' => {
                            'len' => 18,
                            'beg' => 48,
                            'bv' => 'Yes',
                            'fieldnum' => 8,
                            'type' => 'N',
                            'description' => 'Reserved Space M1',
                            'end' => 65,
                            'fmt' => 'L',
                            'field' => 'rs_m1'
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
               'id' => {
                         'len' => 18,
                         'beg' => 29,
                         'bv' => 'Yes',
                         'fieldnum' => 6,
                         'type' => 'A',
                         'description' => 'Identification Code',
                         'end' => 46,
                         'fmt' => 'L',
                         'field' => 'id'
                       },
               'rs_m2' => {
                            'len' => 2,
                            'beg' => 66,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'A',
                            'description' => 'Reserved Space M2',
                            'end' => 67,
                            'fmt' => 'L',
                            'field' => 'rs_m2'
                          }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'tlid',
                 'rtsq',
                 'sourceid',
                 'id',
                 'idflag',
                 'rs_m1',
                 'rs_m2',
                 'rs_m3'
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

Geo::TigerLine::Record::M - TIGER/Line 2006 Feature Spatial Metadata Record

=head1 SYNOPSIS

  use Geo::TigerLine::Record::M;

  @records = Geo::TigerLine::Record::M->parse_file($fh);
  @records = Geo::TigerLine::Record::M->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::M->new(\%fields);

  $record->rt();
  $record->version();
  $record->tlid();
  $record->rtsq();
  $record->sourceid();
  $record->id();
  $record->idflag();
  $record->rs_m1();
  $record->rs_m2();
  $record->rs_m3();


=head1 DESCRIPTION

This is a class representing record type M of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type M files and turn them
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


=item B<sourceid>

    $data = $record->sourceid();
    $record->sourceid($data);

TIGER 1-Cell Source Code.  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.


=item B<id>

    $data = $record->id();
    $record->id($data);

Identification Code.  

Expects alphanumeric data of no more than 18 characters.  $data can be blank 
and should be left justified.


=item B<idflag>

    $data = $record->idflag();
    $record->idflag($data);

Identification Code Flag.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be right justified.


=item B<rs_m1>

    $data = $record->rs_m1();
    $record->rs_m1($data);

Reserved Space M1.  

Expects numeric data of no more than 18 characters.  $data can be blank 
and should be left justified.


=item B<rs_m2>

    $data = $record->rs_m2();
    $record->rs_m2($data);

Reserved Space M2.  

Expects alphanumeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<rs_m3>

    $data = $record->rs_m3();
    $record->rs_m3($data);

Reserved Space M3.  

Expects numeric data of no more than 23 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type M - Feature Spatial Metadata Record
    
    Field      BV  Fmt Type  Beg End Len Description
    RT         No   L    A    1    1  1  Record Type 
    VERSION    No   L   N     2    5  4  Version Number 
    TLID       No   R   N     6   15 10  TIGER/Line ID, Permanent 1-Cell Number 
    RTSQ       No   R   N    16   18  3  Record Sequence Number 
    SOURCEID   Yes  L    A   19   28 10  TIGER 1-Cell Source Code 
    ID         Yes  L    A   29   46 18  Identification Code 
    IDFLAG     Yes  R    A   47   47  1  Identification Code Flag 
    RS-M1      Yes  L   N    48   65 18  Reserved Space M1 
    RS-M2      Yes  L    A   66   67  2  Reserved Space M2 
    RS-M3      Yes  L   N    68   90 23  Reserved Space M3 



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
