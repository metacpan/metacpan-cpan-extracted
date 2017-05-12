package Geo::TigerLine::Record::H;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'source' => {
                             'len' => 1,
                             'beg' => 22,
                             'bv' => 'Yes',
                             'fieldnum' => 6,
                             'type' => 'A',
                             'description' => 'Source or First Source Code to Update',
                             'end' => 22,
                             'fmt' => 'L',
                             'field' => 'source'
                           },
               'tlidto1' => {
                              'len' => 10,
                              'beg' => 43,
                              'bv' => 'Yes',
                              'fieldnum' => 9,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Became Number 1',
                              'end' => 52,
                              'fmt' => 'R',
                              'field' => 'tlidto1'
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
               'tlidfr2' => {
                              'len' => 10,
                              'beg' => 33,
                              'bv' => 'Yes',
                              'fieldnum' => 8,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Created From Number 2',
                              'end' => 42,
                              'fmt' => 'R',
                              'field' => 'tlidfr2'
                            },
               'hist' => {
                           'len' => 1,
                           'beg' => 21,
                           'bv' => 'Yes',
                           'fieldnum' => 5,
                           'type' => 'A',
                           'description' => 'History or Last Source Code to Update',
                           'end' => 21,
                           'fmt' => 'L',
                           'field' => 'hist'
                         },
               'tlidto2' => {
                              'len' => 10,
                              'beg' => 53,
                              'bv' => 'Yes',
                              'fieldnum' => 10,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Became Number 2',
                              'end' => 62,
                              'fmt' => 'R',
                              'field' => 'tlidto2'
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
               'tlidfr1' => {
                              'len' => 10,
                              'beg' => 23,
                              'bv' => 'Yes',
                              'fieldnum' => 7,
                              'type' => 'N',
                              'description' => 'TIGER/Line ID, Created From Number 1',
                              'end' => 32,
                              'fmt' => 'R',
                              'field' => 'tlidfr1'
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
                 'tlid',
                 'hist',
                 'source',
                 'tlidfr1',
                 'tlidfr2',
                 'tlidto1',
                 'tlidto2'
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

Geo::TigerLine::Record::H - TIGER/Line 2006 TIGER/Line ID History

=head1 SYNOPSIS

  use Geo::TigerLine::Record::H;

  @records = Geo::TigerLine::Record::H->parse_file($fh);
  @records = Geo::TigerLine::Record::H->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::H->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->tlid();
  $record->hist();
  $record->source();
  $record->tlidfr1();
  $record->tlidfr2();
  $record->tlidto1();
  $record->tlidto2();


=head1 DESCRIPTION

This is a class representing record type H of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type H files and turn them
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


=item B<hist>

    $data = $record->hist();
    $record->hist($data);

History or Last Source Code to Update.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<source>

    $data = $record->source();
    $record->source($data);

Source or First Source Code to Update.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<tlidfr1>

    $data = $record->tlidfr1();
    $record->tlidfr1($data);

TIGER/Line ID, Created From Number 1.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidfr2>

    $data = $record->tlidfr2();
    $record->tlidfr2($data);

TIGER/Line ID, Created From Number 2.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidto1>

    $data = $record->tlidto1();
    $record->tlidto1($data);

TIGER/Line ID, Became Number 1.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.


=item B<tlidto2>

    $data = $record->tlidto2();
    $record->tlidto2($data);

TIGER/Line ID, Became Number 2.  

Expects numeric data of no more than 10 characters.  $data can be blank 
and should be right justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type H - TIGER/Line ID History
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L   A    1    1  1  Record Type
    VERSION No   L   N    2    5  4  Version Number
    FILE    No   L   N    6   10  5  File Code
    TLID    No   R   N   11   20 10  TIGER/Line ID, Permanent 1-Cell Number
    HIST    Yes  L   A   21   21  1  History or Last Source Code to Update
    SOURCE  Yes  L   A   22   22  1  Source or First Source Code to Update
    TLIDFR1 Yes  R   N   23   32 10  TIGER/Line ID, Created From Number 1
    TLIDFR2 Yes  R   N   33   42 10  TIGER/Line ID, Created From Number 2
    TLIDTO1 Yes  R   N   43   52 10  TIGER/Line ID, Became Number 1
    TLIDTO2 Yes  R   N   53   62 10  TIGER/Line ID, Became Number 2
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
