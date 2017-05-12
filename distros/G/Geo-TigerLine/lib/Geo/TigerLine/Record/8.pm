package Geo::TigerLine::Record::8;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'land' => {
                           'len' => 10,
                           'beg' => 26,
                           'bv' => 'No',
                           'fieldnum' => 6,
                           'type' => 'N',
                           'description' => 'Landmark Identification Number',
                           'end' => 35,
                           'fmt' => 'R',
                           'field' => 'land'
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
               'filler' => {
                             'len' => 1,
                             'beg' => 36,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Filler (to make even character count)',
                             'end' => 36,
                             'fmt' => 'L',
                             'field' => 'filler'
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
                       }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'polyid',
                 'land',
                 'filler'
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

Geo::TigerLine::Record::8 - TIGER/Line 2006 Polygons Linked to Area Landmarks

=head1 SYNOPSIS

  use Geo::TigerLine::Record::8;

  @records = Geo::TigerLine::Record::8->parse_file($fh);
  @records = Geo::TigerLine::Record::8->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::8->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->polyid();
  $record->land();
  $record->filler();


=head1 DESCRIPTION

This is a class representing record type 8 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 8 files and turn them
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


=item B<land>

    $data = $record->land();
    $record->land($data);

Landmark Identification Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<filler>

    $data = $record->filler();
    $record->filler($data);

Filler (to make even character count).  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 8 - Polygons Linked to Area Landmarks
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L    A   1    1  1  Record Type
    VERSION No   L    N   2    5  4  Version Number
    FILE    No   L    N   6   10  5  File Code
    CENID   No   L    A  11   15  5  Census File Identification Code
    POLYID  No   R    N  16   25 10  Polygon Identification Code
    LAND    No   R    N  26   35 10  Landmark Identification Number
    FILLER  Yes  L    A  36   36  1  Filler (to make even character count)



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
