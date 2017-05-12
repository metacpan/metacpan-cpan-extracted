package Geo::TigerLine::Record::T;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'source' => {
                             'len' => 10,
                             'beg' => 21,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'TIGER Zero-Cell Source Code (not filled)',
                             'end' => 30,
                             'fmt' => 'L',
                             'field' => 'source'
                           },
               'tzid' => {
                           'len' => 10,
                           'beg' => 11,
                           'bv' => 'No',
                           'fieldnum' => 4,
                           'type' => 'N',
                           'description' => 'TIGER Zero-Cell ID, Permanent Zero-Cell Number',
                           'end' => 20,
                           'fmt' => 'R',
                           'field' => 'tzid'
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
               'ftrp' => {
                           'len' => 17,
                           'beg' => 31,
                           'bv' => 'Yes',
                           'fieldnum' => 6,
                           'type' => 'A',
                           'description' => 'FTRP ID (AAAAA.O.XXXXXXXXX) (Authority-P-ID) FGDC Transportation ID Standard (not filled)',
                           'end' => 47,
                           'fmt' => 'L',
                           'field' => 'ftrp'
                         }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'file',
                 'tzid',
                 'source',
                 'ftrp'
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

Geo::TigerLine::Record::T - TIGER/Line 2006 TIGER Zero-Cell ID

=head1 SYNOPSIS

  use Geo::TigerLine::Record::T;

  @records = Geo::TigerLine::Record::T->parse_file($fh);
  @records = Geo::TigerLine::Record::T->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::T->new(\%fields);

  $record->rt();
  $record->version();
  $record->file();
  $record->tzid();
  $record->source();
  $record->ftrp();


=head1 DESCRIPTION

This is a class representing record type T of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type T files and turn them
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


=item B<tzid>

    $data = $record->tzid();
    $record->tzid($data);

TIGER Zero-Cell ID, Permanent Zero-Cell Number.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<source>

    $data = $record->source();
    $record->source($data);

TIGER Zero-Cell Source Code (not filled).  

Expects alphanumeric data of no more than 10 characters.  $data can be blank 
and should be left justified.


=item B<ftrp>

    $data = $record->ftrp();
    $record->ftrp($data);

FTRP ID (AAAAA.O.XXXXXXXXX) (Authority-P-ID) FGDC Transportation ID Standard (not filled).  

Expects alphanumeric data of no more than 17 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type T - TIGER Zero-Cell ID
    
    Field     BV  Fmt Type Beg End Len Description
    RT        No   L   A    1    1  1  Record Type
    VERSION   No   L   N    2    5  4  Version Number
    FILE      No   L   N    6   10  5  File Code
    TZID      No   R   N   11   20 10  TIGER Zero-Cell ID, Permanent Zero-Cell Number
    SOURCE    Yes  L   A   21   30 10  TIGER Zero-Cell Source Code (not filled)
    FTRP      Yes  L   A   31   47 17  FTRP ID (AAAAA.O.XXXXXXXXX) (Authority-P-ID) FGDC Transportation ID Standard (not filled)



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
