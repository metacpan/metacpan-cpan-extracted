package Geo::TigerLine::Record::6;

use strict;

use Carp::Assert;
use base qw(Geo::TigerLine::Record::Parser Geo::TigerLine::Record::Accessor
            Geo::TigerLine::Record Class::Data::Inheritable);

use vars qw($VERSION);
$VERSION = '0.03';


# Auto-generated data dictionary.
my %Data_Dict = (
               'toaddl' => {
                             'len' => 11,
                             'beg' => 30,
                             'bv' => 'Yes',
                             'fieldnum' => 6,
                             'type' => 'A',
                             'description' => 'End Address, Left',
                             'end' => 40,
                             'fmt' => 'R',
                             'field' => 'toaddl'
                           },
               'zipl' => {
                           'len' => 5,
                           'beg' => 67,
                           'bv' => 'Yes',
                           'fieldnum' => 13,
                           'type' => 'N',
                           'description' => 'ZIP Code, Left',
                           'end' => 71,
                           'fmt' => 'L',
                           'field' => 'zipl'
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
               'zipr' => {
                           'len' => 5,
                           'beg' => 72,
                           'bv' => 'Yes',
                           'fieldnum' => 14,
                           'type' => 'N',
                           'description' => 'ZIP Code, Right',
                           'end' => 76,
                           'fmt' => 'L',
                           'field' => 'zipr'
                         },
               'friaddl' => {
                              'len' => 1,
                              'beg' => 63,
                              'bv' => 'Yes',
                              'fieldnum' => 9,
                              'type' => 'A',
                              'description' => 'Start Imputed Address Flag, Left',
                              'end' => 63,
                              'fmt' => 'L',
                              'field' => 'friaddl'
                            },
               'toaddr' => {
                             'len' => 11,
                             'beg' => 52,
                             'bv' => 'Yes',
                             'fieldnum' => 8,
                             'type' => 'A',
                             'description' => 'End Address, Right',
                             'end' => 62,
                             'fmt' => 'R',
                             'field' => 'toaddr'
                           },
               'toiaddr' => {
                              'len' => 1,
                              'beg' => 66,
                              'bv' => 'Yes',
                              'fieldnum' => 12,
                              'type' => 'A',
                              'description' => 'End Imputed Address Flag, Right',
                              'end' => 66,
                              'fmt' => 'L',
                              'field' => 'toiaddr'
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
               'fraddl' => {
                             'len' => 11,
                             'beg' => 19,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'Start Address, Left',
                             'end' => 29,
                             'fmt' => 'R',
                             'field' => 'fraddl'
                           },
               'friaddr' => {
                              'len' => 1,
                              'beg' => 65,
                              'bv' => 'Yes',
                              'fieldnum' => 11,
                              'type' => 'A',
                              'description' => 'Start Imputed Address Flag, Right',
                              'end' => 65,
                              'fmt' => 'L',
                              'field' => 'friaddr'
                            },
               'toiaddl' => {
                              'len' => 1,
                              'beg' => 64,
                              'bv' => 'Yes',
                              'fieldnum' => 10,
                              'type' => 'A',
                              'description' => 'End Imputed Address Flag, Left',
                              'end' => 64,
                              'fmt' => 'L',
                              'field' => 'toiaddl'
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
               'fraddr' => {
                             'len' => 11,
                             'beg' => 41,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Start Address, Right',
                             'end' => 51,
                             'fmt' => 'R',
                             'field' => 'fraddr'
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
                 'tlid',
                 'rtsq',
                 'fraddl',
                 'toaddl',
                 'fraddr',
                 'toaddr',
                 'friaddl',
                 'toiaddl',
                 'friaddr',
                 'toiaddr',
                 'zipl',
                 'zipr'
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

Geo::TigerLine::Record::6 - TIGER/Line 2006 Additional Address Range and ZIP Code Data

=head1 SYNOPSIS

  use Geo::TigerLine::Record::6;

  @records = Geo::TigerLine::Record::6->parse_file($fh);
  @records = Geo::TigerLine::Record::6->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::6->new(\%fields);

  $record->rt();
  $record->version();
  $record->tlid();
  $record->rtsq();
  $record->fraddl();
  $record->toaddl();
  $record->fraddr();
  $record->toaddr();
  $record->friaddl();
  $record->toiaddl();
  $record->friaddr();
  $record->toiaddr();
  $record->zipl();
  $record->zipr();


=head1 DESCRIPTION

This is a class representing record type 6 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 6 files and turn them
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


=item B<fraddl>

    $data = $record->fraddl();
    $record->fraddl($data);

Start Address, Left.  

Expects alphanumeric data of no more than 11 characters.  $data can be blank 
and should be right justified.


=item B<toaddl>

    $data = $record->toaddl();
    $record->toaddl($data);

End Address, Left.  

Expects alphanumeric data of no more than 11 characters.  $data can be blank 
and should be right justified.


=item B<fraddr>

    $data = $record->fraddr();
    $record->fraddr($data);

Start Address, Right.  

Expects alphanumeric data of no more than 11 characters.  $data can be blank 
and should be right justified.


=item B<toaddr>

    $data = $record->toaddr();
    $record->toaddr($data);

End Address, Right.  

Expects alphanumeric data of no more than 11 characters.  $data can be blank 
and should be right justified.


=item B<friaddl>

    $data = $record->friaddl();
    $record->friaddl($data);

Start Imputed Address Flag, Left.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<toiaddl>

    $data = $record->toiaddl();
    $record->toiaddl($data);

End Imputed Address Flag, Left.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<friaddr>

    $data = $record->friaddr();
    $record->friaddr($data);

Start Imputed Address Flag, Right.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<toiaddr>

    $data = $record->toiaddr();
    $record->toiaddr($data);

End Imputed Address Flag, Right.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<zipl>

    $data = $record->zipl();
    $record->zipl($data);

ZIP Code, Left.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<zipr>

    $data = $record->zipr();
    $record->zipr($data);

ZIP Code, Right.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 6 - Additional Address Range and ZIP Code Data
    
    Field   BV  Fmt Type Beg End Len Description
    RT      No   L   A    1   1   1  Record Type
    VERSION No   L   N    2   5   4  Version Number
    TLID    No   R   N    6  15  10  TIGER/Line ID, Permanent 1-Cell Number
    RTSQ    No   R   N   16  18   3  Record Sequence Number
    FRADDL  Yes  R   A   19  29  11  Start Address, Left
    TOADDL  Yes  R   A   30  40  11  End Address, Left
    FRADDR  Yes  R   A   41  51  11  Start Address, Right
    TOADDR  Yes  R   A   52  62  11  End Address, Right
    FRIADDL Yes  L   A   63  63   1  Start Imputed Address Flag, Left
    TOIADDL Yes  L   A   64  64   1  End Imputed Address Flag, Left
    FRIADDR Yes  L   A   65  65   1  Start Imputed Address Flag, Right
    TOIADDR Yes  L   A   66  66   1  End Imputed Address Flag, Right
    ZIPL    Yes  L   N   67  71   5  ZIP Code, Left
    ZIPR    Yes  L   N   72  76   5  ZIP Code, Right



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
