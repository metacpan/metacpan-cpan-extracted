package Geo::TigerLine::Record::1;

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
                             'beg' => 70,
                             'bv' => 'Yes',
                             'fieldnum' => 12,
                             'type' => 'A',
                             'description' => 'End Address, Left',
                             'end' => 80,
                             'fmt' => 'R',
                             'field' => 'toaddl'
                           },
               'zipr' => {
                           'len' => 5,
                           'beg' => 112,
                           'bv' => 'Yes',
                           'fieldnum' => 20,
                           'type' => 'N',
                           'description' => 'ZIP Code, Right',
                           'end' => 116,
                           'fmt' => 'L',
                           'field' => 'zipr'
                         },
               'fetype' => {
                             'len' => 4,
                             'beg' => 50,
                             'bv' => 'Yes',
                             'fieldnum' => 8,
                             'type' => 'A',
                             'description' => 'Feature Type',
                             'end' => 53,
                             'fmt' => 'L',
                             'field' => 'fetype'
                           },
               'tractr' => {
                             'len' => 6,
                             'beg' => 177,
                             'bv' => 'Yes',
                             'fieldnum' => 38,
                             'type' => 'N',
                             'description' => 'Census Tract, 2000 Right',
                             'end' => 182,
                             'fmt' => 'L',
                             'field' => 'tractr'
                           },
               'cousubl' => {
                              'len' => 5,
                              'beg' => 141,
                              'bv' => 'Yes',
                              'fieldnum' => 31,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (County Subdivision), 2000 Left',
                              'end' => 145,
                              'fmt' => 'L',
                              'field' => 'cousubl'
                            },
               'toiaddr' => {
                              'len' => 1,
                              'beg' => 106,
                              'bv' => 'Yes',
                              'fieldnum' => 18,
                              'type' => 'A',
                              'description' => 'End Imputed Address Flag, Right',
                              'end' => 106,
                              'fmt' => 'L',
                              'field' => 'toiaddr'
                            },
               'fename' => {
                             'len' => 30,
                             'beg' => 20,
                             'bv' => 'Yes',
                             'fieldnum' => 7,
                             'type' => 'A',
                             'description' => 'Feature Name',
                             'end' => 49,
                             'fmt' => 'L',
                             'field' => 'fename'
                           },
               'frlat' => {
                            'len' => 9,
                            'beg' => 201,
                            'bv' => 'No',
                            'fieldnum' => 42,
                            'type' => 'N',
                            'description' => 'Start Latitude',
                            'end' => 209,
                            'fmt' => 'R',
                            'field' => 'frlat'
                          },
               'friaddr' => {
                              'len' => 1,
                              'beg' => 105,
                              'bv' => 'Yes',
                              'fieldnum' => 17,
                              'type' => 'A',
                              'description' => 'Start Imputed Address Flag, Right',
                              'end' => 105,
                              'fmt' => 'L',
                              'field' => 'friaddr'
                            },
               'submcdr' => {
                              'len' => 5,
                              'beg' => 156,
                              'bv' => 'Yes',
                              'fieldnum' => 34,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (Subbarrio), 2000 Right',
                              'end' => 160,
                              'fmt' => 'L',
                              'field' => 'submcdr'
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
               'tolat' => {
                            'len' => 9,
                            'beg' => 220,
                            'bv' => 'No',
                            'fieldnum' => 44,
                            'type' => 'N',
                            'description' => 'End Latitude',
                            'end' => 228,
                            'fmt' => 'R',
                            'field' => 'tolat'
                          },
               'fedirp' => {
                             'len' => 2,
                             'beg' => 18,
                             'bv' => 'Yes',
                             'fieldnum' => 6,
                             'type' => 'A',
                             'description' => 'Feature Direction, Prefix',
                             'end' => 19,
                             'fmt' => 'L',
                             'field' => 'fedirp'
                           },
               'side1' => {
                            'len' => 1,
                            'beg' => 16,
                            'bv' => 'Yes',
                            'fieldnum' => 4,
                            'type' => 'N',
                            'description' => 'Single-Side Source Code',
                            'end' => 16,
                            'fmt' => 'R',
                            'field' => 'side1'
                          },
               'census1' => {
                              'len' => 1,
                              'beg' => 129,
                              'bv' => 'Yes',
                              'fieldnum' => 25,
                              'type' => 'A',
                              'description' => 'Census Use 1',
                              'end' => 129,
                              'fmt' => 'L',
                              'field' => 'census1'
                            },
               'tractl' => {
                             'len' => 6,
                             'beg' => 171,
                             'bv' => 'Yes',
                             'fieldnum' => 37,
                             'type' => 'N',
                             'description' => 'Census Tract, 2000 Left',
                             'end' => 176,
                             'fmt' => 'L',
                             'field' => 'tractl'
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
               'tolong' => {
                             'len' => 10,
                             'beg' => 210,
                             'bv' => 'No',
                             'fieldnum' => 43,
                             'type' => 'N',
                             'description' => 'End Longitude',
                             'end' => 219,
                             'fmt' => 'R',
                             'field' => 'tolong'
                           },
               'toiaddl' => {
                              'len' => 1,
                              'beg' => 104,
                              'bv' => 'Yes',
                              'fieldnum' => 16,
                              'type' => 'A',
                              'description' => 'End Imputed Address Flag, Left',
                              'end' => 104,
                              'fmt' => 'L',
                              'field' => 'toiaddl'
                            },
               'frlong' => {
                             'len' => 10,
                             'beg' => 191,
                             'bv' => 'No',
                             'fieldnum' => 41,
                             'type' => 'N',
                             'description' => 'Start Longitude',
                             'end' => 200,
                             'fmt' => 'R',
                             'field' => 'frlong'
                           },
               'source' => {
                             'len' => 1,
                             'beg' => 17,
                             'bv' => 'Yes',
                             'fieldnum' => 5,
                             'type' => 'A',
                             'description' => 'Linear Segment Source Code',
                             'end' => 17,
                             'fmt' => 'L',
                             'field' => 'source'
                           },
               'countyr' => {
                              'len' => 3,
                              'beg' => 138,
                              'bv' => 'Yes',
                              'fieldnum' => 30,
                              'type' => 'N',
                              'description' => 'FIPS County Code, 2000 Right (always filled both sides, except at U.S. boundaries)',
                              'end' => 140,
                              'fmt' => 'L',
                              'field' => 'countyr'
                            },
               'friaddl' => {
                              'len' => 1,
                              'beg' => 103,
                              'bv' => 'Yes',
                              'fieldnum' => 15,
                              'type' => 'A',
                              'description' => 'Start Imputed Address Flag, Left',
                              'end' => 103,
                              'fmt' => 'L',
                              'field' => 'friaddl'
                            },
               'countyl' => {
                              'len' => 3,
                              'beg' => 135,
                              'bv' => 'Yes',
                              'fieldnum' => 29,
                              'type' => 'N',
                              'description' => 'FIPS County Code, 2000 Left (always filled both sides, except at U.S. boundaries)',
                              'end' => 137,
                              'fmt' => 'L',
                              'field' => 'countyl'
                            },
               'stater' => {
                             'len' => 2,
                             'beg' => 133,
                             'bv' => 'Yes',
                             'fieldnum' => 28,
                             'type' => 'N',
                             'description' => 'FIPS State Code, 2000 Right (always filled both sides, except at U.S. boundaries)',
                             'end' => 134,
                             'fmt' => 'L',
                             'field' => 'stater'
                           },
               'aihhtlil' => {
                               'len' => 1,
                               'beg' => 127,
                               'bv' => 'Yes',
                               'fieldnum' => 23,
                               'type' => 'A',
                               'description' => 'American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Left',
                               'end' => 127,
                               'fmt' => 'L',
                               'field' => 'aihhtlil'
                             },
               'cfcc' => {
                           'len' => 3,
                           'beg' => 56,
                           'bv' => 'No',
                           'fieldnum' => 10,
                           'type' => 'A',
                           'description' => 'Census Feature Class Code',
                           'end' => 58,
                           'fmt' => 'L',
                           'field' => 'cfcc'
                         },
               'placel' => {
                             'len' => 5,
                             'beg' => 161,
                             'bv' => 'Yes',
                             'fieldnum' => 35,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (Place/CDP), 2000 Left',
                             'end' => 165,
                             'fmt' => 'L',
                             'field' => 'placel'
                           },
               'aianhhfpr' => {
                                'len' => 5,
                                'beg' => 122,
                                'bv' => 'Yes',
                                'fieldnum' => 22,
                                'type' => 'N',
                                'description' => 'FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Right',
                                'end' => 126,
                                'fmt' => 'L',
                                'field' => 'aianhhfpr'
                              },
               'blockl' => {
                             'len' => 4,
                             'beg' => 183,
                             'bv' => 'Yes',
                             'fieldnum' => 39,
                             'type' => 'N',
                             'description' => 'Census Block Number, 2000 Left',
                             'end' => 186,
                             'fmt' => 'L',
                             'field' => 'blockl'
                           },
               'zipl' => {
                           'len' => 5,
                           'beg' => 107,
                           'bv' => 'Yes',
                           'fieldnum' => 19,
                           'type' => 'N',
                           'description' => 'ZIP Code, Left',
                           'end' => 111,
                           'fmt' => 'L',
                           'field' => 'zipl'
                         },
               'aianhhfpl' => {
                                'len' => 5,
                                'beg' => 117,
                                'bv' => 'Yes',
                                'fieldnum' => 21,
                                'type' => 'N',
                                'description' => 'FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Left',
                                'end' => 121,
                                'fmt' => 'L',
                                'field' => 'aianhhfpl'
                              },
               'cousubr' => {
                              'len' => 5,
                              'beg' => 146,
                              'bv' => 'Yes',
                              'fieldnum' => 32,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (County Subdivision), 2000 Right',
                              'end' => 150,
                              'fmt' => 'L',
                              'field' => 'cousubr'
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
               'blockr' => {
                             'len' => 4,
                             'beg' => 187,
                             'bv' => 'Yes',
                             'fieldnum' => 40,
                             'type' => 'N',
                             'description' => 'Census Block Number, 2000 Right',
                             'end' => 190,
                             'fmt' => 'L',
                             'field' => 'blockr'
                           },
               'toaddr' => {
                             'len' => 11,
                             'beg' => 92,
                             'bv' => 'Yes',
                             'fieldnum' => 14,
                             'type' => 'A',
                             'description' => 'End Address, Right',
                             'end' => 102,
                             'fmt' => 'R',
                             'field' => 'toaddr'
                           },
               'submcdl' => {
                              'len' => 5,
                              'beg' => 151,
                              'bv' => 'Yes',
                              'fieldnum' => 33,
                              'type' => 'N',
                              'description' => 'FIPS 55 Code (Subbarrio), 2000 Left',
                              'end' => 155,
                              'fmt' => 'L',
                              'field' => 'submcdl'
                            },
               'aihhtlir' => {
                               'len' => 1,
                               'beg' => 128,
                               'bv' => 'Yes',
                               'fieldnum' => 24,
                               'type' => 'A',
                               'description' => 'American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Right',
                               'end' => 128,
                               'fmt' => 'L',
                               'field' => 'aihhtlir'
                             },
               'placer' => {
                             'len' => 5,
                             'beg' => 166,
                             'bv' => 'Yes',
                             'fieldnum' => 36,
                             'type' => 'N',
                             'description' => 'FIPS 55 Code (Place/CDP), 2000 Right',
                             'end' => 170,
                             'fmt' => 'L',
                             'field' => 'placer'
                           },
               'fraddl' => {
                             'len' => 11,
                             'beg' => 59,
                             'bv' => 'Yes',
                             'fieldnum' => 11,
                             'type' => 'A',
                             'description' => 'Start Address, Left',
                             'end' => 69,
                             'fmt' => 'R',
                             'field' => 'fraddl'
                           },
               'fedirs' => {
                             'len' => 2,
                             'beg' => 54,
                             'bv' => 'Yes',
                             'fieldnum' => 9,
                             'type' => 'A',
                             'description' => 'Feature Direction, Suffix',
                             'end' => 55,
                             'fmt' => 'L',
                             'field' => 'fedirs'
                           },
               'fraddr' => {
                             'len' => 11,
                             'beg' => 81,
                             'bv' => 'Yes',
                             'fieldnum' => 13,
                             'type' => 'A',
                             'description' => 'Start Address, Right',
                             'end' => 91,
                             'fmt' => 'R',
                             'field' => 'fraddr'
                           },
               'statel' => {
                             'len' => 2,
                             'beg' => 131,
                             'bv' => 'Yes',
                             'fieldnum' => 27,
                             'type' => 'N',
                             'description' => 'FIPS State Code, 2000 Left (always filled both sides, except at U.S. boundaries)',
                             'end' => 132,
                             'fmt' => 'L',
                             'field' => 'statel'
                           },
               'census2' => {
                              'len' => 1,
                              'beg' => 130,
                              'bv' => 'Yes',
                              'fieldnum' => 26,
                              'type' => 'A',
                              'description' => 'Census Use 2',
                              'end' => 130,
                              'fmt' => 'L',
                              'field' => 'census2'
                            }
             );


my @Data_Fields = (
                 'rt',
                 'version',
                 'tlid',
                 'side1',
                 'source',
                 'fedirp',
                 'fename',
                 'fetype',
                 'fedirs',
                 'cfcc',
                 'fraddl',
                 'toaddl',
                 'fraddr',
                 'toaddr',
                 'friaddl',
                 'toiaddl',
                 'friaddr',
                 'toiaddr',
                 'zipl',
                 'zipr',
                 'aianhhfpl',
                 'aianhhfpr',
                 'aihhtlil',
                 'aihhtlir',
                 'census1',
                 'census2',
                 'statel',
                 'stater',
                 'countyl',
                 'countyr',
                 'cousubl',
                 'cousubr',
                 'submcdl',
                 'submcdr',
                 'placel',
                 'placer',
                 'tractl',
                 'tractr',
                 'blockl',
                 'blockr',
                 'frlong',
                 'frlat',
                 'tolong',
                 'tolat'
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

Geo::TigerLine::Record::1 - TIGER/Line 2006 Complete Chain Basic Data Record

=head1 SYNOPSIS

  use Geo::TigerLine::Record::1;

  @records = Geo::TigerLine::Record::1->parse_file($fh);
  @records = Geo::TigerLine::Record::1->parse_file($fh, \&callback);

  $record = Geo::TigerLine::Record::1->new(\%fields);

  $record->rt();
  $record->version();
  $record->tlid();
  $record->side1();
  $record->source();
  $record->fedirp();
  $record->fename();
  $record->fetype();
  $record->fedirs();
  $record->cfcc();
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
  $record->aianhhfpl();
  $record->aianhhfpr();
  $record->aihhtlil();
  $record->aihhtlir();
  $record->census1();
  $record->census2();
  $record->statel();
  $record->stater();
  $record->countyl();
  $record->countyr();
  $record->cousubl();
  $record->cousubr();
  $record->submcdl();
  $record->submcdr();
  $record->placel();
  $record->placer();
  $record->tractl();
  $record->tractr();
  $record->blockl();
  $record->blockr();
  $record->frlong();
  $record->frlat();
  $record->tolong();
  $record->tolat();


=head1 DESCRIPTION

This is a class representing record type 1 of the TIGER/Line 2006
census geographic database.  Each object is one record.  It also
contains methods to parse TIGER/Line record type 1 files and turn them
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


=item B<side1>

    $data = $record->side1();
    $record->side1($data);

Single-Side Source Code.  

Expects numeric data of no more than 1 characters.  $data can be blank 
and should be right justified.


=item B<source>

    $data = $record->source();
    $record->source($data);

Linear Segment Source Code.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


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


=item B<cfcc>

    $data = $record->cfcc();
    $record->cfcc($data);

Census Feature Class Code.  

Expects alphanumeric data of no more than 3 characters.  $data cannot be blank 
and should be left justified.


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


=item B<aianhhfpl>

    $data = $record->aianhhfpl();
    $record->aianhhfpl($data);

FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Left.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aianhhfpr>

    $data = $record->aianhhfpr();
    $record->aianhhfpr($data);

FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Right.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<aihhtlil>

    $data = $record->aihhtlil();
    $record->aihhtlil($data);

American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Left.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<aihhtlir>

    $data = $record->aihhtlir();
    $record->aihhtlir($data);

American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Right.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<census1>

    $data = $record->census1();
    $record->census1($data);

Census Use 1.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<census2>

    $data = $record->census2();
    $record->census2($data);

Census Use 2.  

Expects alphanumeric data of no more than 1 characters.  $data can be blank 
and should be left justified.


=item B<statel>

    $data = $record->statel();
    $record->statel($data);

FIPS State Code, 2000 Left (always filled both sides, except at U.S. boundaries).  

Expects numeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<stater>

    $data = $record->stater();
    $record->stater($data);

FIPS State Code, 2000 Right (always filled both sides, except at U.S. boundaries).  

Expects numeric data of no more than 2 characters.  $data can be blank 
and should be left justified.


=item B<countyl>

    $data = $record->countyl();
    $record->countyl($data);

FIPS County Code, 2000 Left (always filled both sides, except at U.S. boundaries).  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<countyr>

    $data = $record->countyr();
    $record->countyr($data);

FIPS County Code, 2000 Right (always filled both sides, except at U.S. boundaries).  

Expects numeric data of no more than 3 characters.  $data can be blank 
and should be left justified.


=item B<cousubl>

    $data = $record->cousubl();
    $record->cousubl($data);

FIPS 55 Code (County Subdivision), 2000 Left.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<cousubr>

    $data = $record->cousubr();
    $record->cousubr($data);

FIPS 55 Code (County Subdivision), 2000 Right.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<submcdl>

    $data = $record->submcdl();
    $record->submcdl($data);

FIPS 55 Code (Subbarrio), 2000 Left.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<submcdr>

    $data = $record->submcdr();
    $record->submcdr($data);

FIPS 55 Code (Subbarrio), 2000 Right.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<placel>

    $data = $record->placel();
    $record->placel($data);

FIPS 55 Code (Place/CDP), 2000 Left.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<placer>

    $data = $record->placer();
    $record->placer($data);

FIPS 55 Code (Place/CDP), 2000 Right.  

Expects numeric data of no more than 5 characters.  $data can be blank 
and should be left justified.


=item B<tractl>

    $data = $record->tractl();
    $record->tractl($data);

Census Tract, 2000 Left.  

Expects numeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<tractr>

    $data = $record->tractr();
    $record->tractr($data);

Census Tract, 2000 Right.  

Expects numeric data of no more than 6 characters.  $data can be blank 
and should be left justified.


=item B<blockl>

    $data = $record->blockl();
    $record->blockl($data);

Census Block Number, 2000 Left.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<blockr>

    $data = $record->blockr();
    $record->blockr($data);

Census Block Number, 2000 Right.  

Expects numeric data of no more than 4 characters.  $data can be blank 
and should be left justified.


=item B<frlong>

    $data = $record->frlong();
    $record->frlong($data);

Start Longitude.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<frlat>

    $data = $record->frlat();
    $record->frlat($data);

Start Latitude.  

Expects numeric data of no more than 9 characters.  $data cannot be blank 
and should be right justified.


=item B<tolong>

    $data = $record->tolong();
    $record->tolong($data);

End Longitude.  

Expects numeric data of no more than 10 characters.  $data cannot be blank 
and should be right justified.


=item B<tolat>

    $data = $record->tolat();
    $record->tolat($data);

End Latitude.  

Expects numeric data of no more than 9 characters.  $data cannot be blank 
and should be right justified.



=back


=head2 Data dictionary

This is the original TIGER/Line 2006 data dictionary from which this
class was generated.

    Record Type 1 - Complete Chain Basic Data Record
    
    Field     BV Fmt Type Beg End Len  Description
    RT        No   L   A    1    1  1  Record Type
    VERSION   No   L   N    2    5  4  Version Number
    TLID      No   R   N    6   15 10  TIGER/Line ID, Permanent 1-Cell Number
    SIDE1     Yes  R   N   16   16  1  Single-Side Source Code
    SOURCE    Yes  L   A   17   17  1  Linear Segment Source Code
    FEDIRP    Yes  L   A   18   19  2  Feature Direction, Prefix
    FENAME    Yes  L   A   20   49 30  Feature Name
    FETYPE    Yes  L   A   50   53  4  Feature Type
    FEDIRS    Yes  L   A   54   55  2  Feature Direction, Suffix
    CFCC      No   L   A   56   58  3  Census Feature Class Code
    FRADDL    Yes  R   A   59   69 11  Start Address, Left
    TOADDL    Yes  R   A   70   80 11  End Address, Left
    FRADDR    Yes  R   A   81   91 11  Start Address, Right
    TOADDR    Yes  R   A   92  102 11  End Address, Right
    FRIADDL   Yes  L   A  103  103  1  Start Imputed Address Flag, Left
    TOIADDL   Yes  L   A  104  104  1  End Imputed Address Flag, Left
    FRIADDR   Yes  L   A  105  105  1  Start Imputed Address Flag, Right
    TOIADDR   Yes  L   A  106  106  1  End Imputed Address Flag, Right
    ZIPL      Yes  L   N  107  111  5  ZIP Code, Left
    ZIPR      Yes  L   N  112  116  5  ZIP Code, Right
    AIANHHFPR Yes  L   N  122  126  5  FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Right
    AIANHHFPL Yes  L   N  117  121  5  FIPS 55 Code (American Indian/Alaska Native Area/Hawaiian Home Land), 2000 Left
    AIHHTLIL Yes  L   A   127  127   1 American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Left
    AIHHTLIR Yes  L   A   128  128   1 American Indian/Hawaiian Home Land Trust Land Indicator, 2000 Right
    CENSUS1  Yes  L   A   129  129   1 Census Use 1
    CENSUS2  Yes  L   A   130  130   1 Census Use 2
    STATEL   Yes  L   N   131  132   2 FIPS State Code, 2000 Left (always filled both sides, except at U.S. boundaries)
    STATER   Yes  L   N   133  134   2 FIPS State Code, 2000 Right (always filled both sides, except at U.S. boundaries)
    COUNTYL  Yes  L   N   135  137   3 FIPS County Code, 2000 Left (always filled both sides, except at U.S. boundaries)
    COUNTYR  Yes  L   N   138  140   3 FIPS County Code, 2000 Right (always filled both sides, except at U.S. boundaries)
    COUSUBL  Yes  L   N   141  145   5 FIPS 55 Code (County Subdivision), 2000 Left
    COUSUBR  Yes  L   N   146  150   5 FIPS 55 Code (County Subdivision), 2000 Right
    SUBMCDL  Yes  L   N   151  155   5 FIPS 55 Code (Subbarrio), 2000 Left
    SUBMCDR  Yes  L   N   156  160   5 FIPS 55 Code (Subbarrio), 2000 Right
    PLACEL   Yes  L   N   161  165   5 FIPS 55 Code (Place/CDP), 2000 Left
    PLACER   Yes  L   N   166  170   5 FIPS 55 Code (Place/CDP), 2000 Right
    TRACTL   Yes  L   N   171  176   6 Census Tract, 2000 Left
    TRACTR   Yes  L   N   177  182   6 Census Tract, 2000 Right
    BLOCKL   Yes  L   N   183  186   4 Census Block Number, 2000 Left
    BLOCKR   Yes  L   N   187  190   4 Census Block Number, 2000 Right
    FRLONG   No   R   N   191  200  10 Start Longitude
    FRLAT    No   R   N   201  209   9 Start Latitude
    TOLONG   No   R   N   210  219  10 End Longitude
    TOLAT    No   R   N   220  228   9 End Latitude
    



=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>, L<mk_parsers>

=cut


return 'Honey flash!';
