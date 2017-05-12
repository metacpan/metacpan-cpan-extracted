package Geo::TigerLine::Record::5;

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
               'fetype' => {
                             'len' => 4,
                             'beg' => 51,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Feature Type',
                             'end' => 54,
                             'fmt' => 'L',
                             'field' => 'fetype'
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
               'fename' => {
                             'len' => 30,
                             'beg' => 21,
                             'bv' => 'Yes',
                             'fieldnum' => 6,
                             'type' => 'A',
                             'description' => 'Feature Name',
                             'end' => 50,
                             'fmt' => 'L',
                             'field' => 'fename'
                           },
               'feat' => {
                           'len' => 8,
                           'beg' => 11,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'Line Name Identification Number',
                           'end' => 18,
                           'fmt' => 'R',
                           'field' => 'feat'
                         },
               'fedirs' => {
                             'len' => 2,
                             'beg' => 55,
                             'bv' => 'Yes',
                             'fieldnum' => 8,
                             'type' => 'A',
                             'description' => 'Feature Direction, Suffix',
                             'end' => 56,
                             'fmt' => 'L',
                             'field' => 'fedirs'
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
               'fedirp' => {
                             'len' => 2,
                             'beg' => 19,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'Feature Direction, Prefix',
                             'end' => 20,
                             'fmt' => 'L',
                             'field' => 'fedirp'
                           }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'feat',
                 'fedirp',
                 'fename',
                 'fetype',
                 'fedirs'
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

Geo::TigerLine::Record::5 - TIGER/Line 2006 Complete Chain Feature Identifiers

=head1 SYNOPSIS

  use Geo::TigerLine::Record::5;

  @records = Geo::TigerLine::Record::5->parse_file($fh);
  @records = Geo::TigerLine::Record::5->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::5->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->feat();
  $record->fedirp();
  $record->fename();
  $record->fetype();
  $record->fedirs();


=head1 DESCRIPTION

This is a class representing record type 5 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 5 files and turn them
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


=item B<feat>

    $data = $record->feat();
    $record->feat($data);

Line Name Identification Number.  

Expects numeric data of no more than 8 characters.  $data cannot be blank 
and should be right justified.


=item B<fedirp>

    $data = $record->fedirp();
    $record->fedirp($data);

Feature Direction, Prefix.  

Expects alphanumeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<fename>

    $data = $record->fename();
    $record->fename($data);

Feature Name.  

Expects alphanumeric data of no more than 30 characters.  $data can be blank 
and should be left justified.


=item B<fetype>

    $data = $record->fetype();
    $record->fetype($data);

Feature Type.  

Expects alphanumeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<fedirs>

    $data = $record->fedirs();
    $record->fedirs($data);

Feature Direction, Suffix.  

Expects alphanumeric data of no more than 2 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 5 - Complete Chain Feature Identifiers
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L   A    1   1   1  Record Type
    VERSION No   L   N    2   5   4  Version Number
    FILE    No   L   N    6  10   5  File Code
    FEAT    No   R   N   11  18   8  Line Name Identification Number
    FEDIRP  Yes  L   A   19  20   2  Feature Direction, Prefix
    FENAME  Yes  L   A   21  50  30  Feature Name
    FETYPE  Yes  L   A   51  54   4  Feature Type
    FEDIRS  Yes  L   A   55  56   2  Feature Direction, Suffix



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
