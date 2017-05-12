package Geo::TigerLine::Record::R;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'tzhighid' => {
                               'len' => 10,
                               'beg' => 66,
                               'bv' => 'No',
                               'fieldnum' => 10,
                               'type' => 'N',
                               'description' => 'Current High TIGER Zero-Cell ID for Census File Identification Code',
                               'end' => 75,
                               'fmt' => 'R',
                               'field' => 'tzhighid'
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
               'tlminid' => {
                              'len' => 10,
                              'beg' => 26,
                              'bv' => 'No',
                              'fieldnum' => 6,
                              'type' => 'N',
                              'description' => 'Lowest Possible TIGER/Line ID in range for Census File Identification Code',
                              'end' => 35,
                              'fmt' => 'R',
                              'field' => 'tlminid'
                            },
               'tzmaxid' => {
                              'len' => 10,
                              'beg' => 46,
                              'bv' => 'No',
                              'fieldnum' => 8,
                              'type' => 'N',
                              'description' => 'Highest Possible TIGER Zero-Cell ID in range for Census File Identification Code',
                              'end' => 55,
                              'fmt' => 'R',
                              'field' => 'tzmaxid'
                            },
               'tlmaxid' => {
                              'len' => 10,
                              'beg' => 16,
                              'bv' => 'No',
                              'fieldnum' => 5,
                              'type' => 'N',
                              'description' => 'Highest Possible TIGER/Line ID in range for Census File Identification Code',
                              'end' => 25,
                              'fmt' => 'R',
                              'field' => 'tlmaxid'
                            },
               'tlihghid' => {
                               'len' => 10,
                               'beg' => 36,
                               'bv' => 'No',
                               'fieldnum' => 7,
                               'type' => 'N',
                               'description' => 'Current High TIGER/Line ID for Census File Identification Code',
                               'end' => 45,
                               'fmt' => 'R',
                               'field' => 'tlihghid'
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
               'filler' => {
                             'len' => 1,
                             'beg' => 76,
                             'bv' => 'Yes',
                             'fieldnum' => 11,
                             'type' => 'A',
                             'description' => 'Filler (to make even character count)',
                             'end' => 76,
                             'fmt' => 'L',
                             'field' => 'filler'
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
               'tzminid' => {
                              'len' => 10,
                              'beg' => 56,
                              'bv' => 'No',
                              'fieldnum' => 9,
                              'type' => 'N',
                              'description' => 'Lowest Possible TIGER Zero-Cell ID in range for Census File Identification Code',
                              'end' => 65,
                              'fmt' => 'R',
                              'field' => 'tzminid'
                            }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'cenid',
                 'tlmaxid',
                 'tlminid',
                 'tlihghid',
                 'tzmaxid',
                 'tzminid',
                 'tzhighid',
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

Geo::TigerLine::Record::R - TIGER/Line 2006 TIGER/Line ID Record Number Range

=head1 SYNOPSIS

  use Geo::TigerLine::Record::R;

  @records = Geo::TigerLine::Record::R->parse_file($fh);
  @records = Geo::TigerLine::Record::R->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::R->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->cenid();
  $record->tlmaxid();
  $record->tlminid();
  $record->tlihghid();
  $record->tzmaxid();
  $record->tzminid();
  $record->tzhighid();
  $record->filler();


=head1 DESCRIPTION

This is a class representing record type R of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type R files and turn them
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


=item B<tlmaxid>

    $data = $record->tlmaxid();
    $record->tlmaxid($data);

Highest Possible TIGER/Line ID in range for Census File Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tlminid>

    $data = $record->tlminid();
    $record->tlminid($data);

Lowest Possible TIGER/Line ID in range for Census File Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tlihghid>

    $data = $record->tlihghid();
    $record->tlihghid($data);

Current High TIGER/Line ID for Census File Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tzmaxid>

    $data = $record->tzmaxid();
    $record->tzmaxid($data);

Highest Possible TIGER Zero-Cell ID in range for Census File Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tzminid>

    $data = $record->tzminid();
    $record->tzminid($data);

Lowest Possible TIGER Zero-Cell ID in range for Census File Identification Code.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tzhighid>

    $data = $record->tzhighid();
    $record->tzhighid($data);

Current High TIGER Zero-Cell ID for Census File Identification Code.  

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

    Record Type R - TIGER/Line ID Record Number Range
    
    Field    BV  Fmt Type Beg End Len Description
    RT       No   L   A    1    1  1  Record Type
    VERSION  No   L   N    2    5  4  Version Number
    FILE     No   L   N    6   10  5  File Code
    CENID    No   L   A   11   15  5  Census File Identification Code
    TLMAXID  No   R   N   16   25 10  Highest Possible TIGER/Line ID in range for Census File Identification Code
    TLMINID  No   R   N   26   35 10  Lowest Possible TIGER/Line ID in range for Census File Identification Code
    TLIHGHID No   R   N   36   45 10  Current High TIGER/Line ID for Census File Identification Code
    TZMAXID  No   R   N   46   55 10  Highest Possible TIGER Zero-Cell ID in range for Census File Identification Code
    TZMINID  No   R   N   56   65 10  Lowest Possible TIGER Zero-Cell ID in range for Census File Identification Code
    TZHIGHID No   R   N   66   75 10  Current High TIGER Zero-Cell ID for Census File Identification Code
    FILLER   Yes  L   A   76   76  1  Filler (to make even character count)



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
