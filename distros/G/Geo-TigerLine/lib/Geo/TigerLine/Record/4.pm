package Geo::TigerLine::Record::4;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'feat1' => {
                            'len' => 8,
                            'beg' => 19,
                            'bv' => 'No',
                            'fieldnum' => 5,
                            'type' => 'N',
                            'description' => 'Line Additional Name Identification Number, First',
                            'end' => 26,
                            'fmt' => 'R',
                            'field' => 'feat1'
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
               'feat3' => {
                            'len' => 8,
                            'beg' => 35,
                            'bv' => 'Yes',
                            'fieldnum' => 7,
                            'type' => 'N',
                            'description' => 'Line Additional Name Identification Number, Third',
                            'end' => 42,
                            'fmt' => 'R',
                            'field' => 'feat3'
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
               'feat4' => {
                            'len' => 8,
                            'beg' => 43,
                            'bv' => 'Yes',
                            'fieldnum' => 8,
                            'type' => 'N',
                            'description' => 'Line Additional Name Identification Number, Fourth',
                            'end' => 50,
                            'fmt' => 'R',
                            'field' => 'feat4'
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
               'feat5' => {
                            'len' => 8,
                            'beg' => 51,
                            'bv' => 'Yes',
                            'fieldnum' => 9,
                            'type' => 'N',
                            'description' => 'Line Additional Name Identification Number, Fifth',
                            'end' => 58,
                            'fmt' => 'R',
                            'field' => 'feat5'
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
               'feat2' => {
                            'len' => 8,
                            'beg' => 27,
                            'bv' => 'Yes',
                            'fieldnum' => 6,
                            'type' => 'N',
                            'description' => 'Line Additional Name Identification Number, Second',
                            'end' => 34,
                            'fmt' => 'R',
                            'field' => 'feat2'
                          }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'tlid',
                 'rtsq',
                 'feat1',
                 'feat2',
                 'feat3',
                 'feat4',
                 'feat5'
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

Geo::TigerLine::Record::4 - TIGER/Line 2006 Index to Alternative Feature Identifiers

=head1 SYNOPSIS

  use Geo::TigerLine::Record::4;

  @records = Geo::TigerLine::Record::4->parse_file($fh);
  @records = Geo::TigerLine::Record::4->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::4->new(\%fields);

  $record->rt();
  $record->version();
  $record->tlid();
  $record->rtsq();
  $record->feat1();
  $record->feat2();
  $record->feat3();
  $record->feat4();
  $record->feat5();


=head1 DESCRIPTION

This is a class representing record type 4 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 4 files and turn them
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


=item B<feat1>

    $data = $record->feat1();
    $record->feat1($data);

Line Additional Name Identification Number, First.  

Expects numeric data of no more than 8 characters.  $data cannot be blank 
and should be right justified.


=item B<feat2>

    $data = $record->feat2();
    $record->feat2($data);

Line Additional Name Identification Number, Second.  

Expects numeric data of no more than 8 characters.  $data can be blank 
and should be right justified.


=item B<feat3>

    $data = $record->feat3();
    $record->feat3($data);

Line Additional Name Identification Number, Third.  

Expects numeric data of no more than 8 characters.  $data can be blank 
and should be right justified.


=item B<feat4>

    $data = $record->feat4();
    $record->feat4($data);

Line Additional Name Identification Number, Fourth.  

Expects numeric data of no more than 8 characters.  $data can be blank 
and should be right justified.


=item B<feat5>

    $data = $record->feat5();
    $record->feat5($data);

Line Additional Name Identification Number, Fifth.  

Expects numeric data of no more than 8 characters.  $data can be blank 
and should be right justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 4 - Index to Alternative Feature Identifiers
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L   A    1    1   1 Record Type
    VERSION No   L   N    2    5   4 Version Number
    TLID    No   R   N    6   15  10 TIGER/Line ID, Permanent 1-Cell Number
    RTSQ    No   R   N   16   18   3 Record Sequence Number
    FEAT1   No   R   N   19   26   8 Line Additional Name Identification Number, First
    FEAT2   Yes  R   N   27   34   8 Line Additional Name Identification Number, Second
    FEAT3   Yes  R   N   35   42   8 Line Additional Name Identification Number, Third
    FEAT4   Yes  R   N   43   50   8 Line Additional Name Identification Number, Fourth
    FEAT5   Yes  R   N   51   58   8 Line Additional Name Identification Number, Fifth



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
