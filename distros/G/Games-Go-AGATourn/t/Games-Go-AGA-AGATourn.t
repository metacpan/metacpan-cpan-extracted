#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-AGATourn.t'

#########################

use strict;
use IO::File;
use Test::More tests => 41;

BEGIN {
    use_ok('Games::Go::AGATourn')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $agaTourn;

##
## create agaTourn object.  don't read register.tde, or Round files
##
eval { $agaTourn = Games::Go::AGATourn->new(register_tde => undef, Round => 0); };
is( $@, '',                     'return from new ATourn object'  );
ok( defined $agaTourn,          'created AGATourn object'  );
ok( $agaTourn->isa('Games::Go::AGATourn'),
                                '   and it\'s the right class'  );

##
## make sure the data base is empty
##
is( $agaTourn->Tourney, 
    'Unknown tournament',               'TOURNEY directive empty');
is_deeply($agaTourn->Directive,
          { ROUNDS => [ 1 ],
           TOURNEY => [ 'Unknown tournament' ]
           },                           'directives initialized');
is ( $agaTourn->Rounds, 1,           '1 round by default');
is ( $agaTourn->Round, 0,            'current round is 0');
is_deeply($agaTourn->Name, {},      'names hash is empty');
is ( $agaTourn->NameLength, 0,       'nameLength is 0');
is_deeply($agaTourn->Rating, {},    'ratings hash is empty');
is_deeply($agaTourn->Comment, {},   'comments hash is empty');
is ( $agaTourn->Error, 0,            'no errors yet');
is_deeply($agaTourn->GamesList, [],  'games list array is empty');
is ( $agaTourn->WhichBandIs('4k'), 0,   'bands not set');
is ( $agaTourn->BandName(0), '99D 99K', 'default band');
is ( $agaTourn->BandName(1), undef,  'bands out of range');

##
## create a new agaTourn object.  this time, read register.tde
##
eval { $agaTourn = Games::Go::AGATourn->new(register_tde => 't/register.tde',
                                                 Round => 0); };
is( $@, '',                     'return from new ATourn object'  );
ok( defined $agaTourn,          'created AGATourn object'  );
ok( $agaTourn->isa('Games::Go::AGATourn'),
                                '   and it\'s the right class'  );

##
## make sure the data base is empty
##
is( $agaTourn->Tourney,
    '1st Annual Test Tournament, Handicap section  Jan 3-4, 2004',
                                        'TOURNEY directive empty');
is_deeply($agaTourn->Directive,
          { ROUNDS    => [ 5 ],
            TOURNEY   => [ '1st Annual Test Tournament, Handicap section  Jan 3-4, 2004',],
            RULES     => [ 'ING', ],
            ROUNDS    => [ '5', ],
            HANDICAPS => [ 'MAX', ],
            BAND      => [
                           '6d 3d',
                           '2d 1d',
                           '1k 3k',
                           '4k 10k',
                           '11k 50k',
                         ],
            },                          'directives initialized');
is ( $agaTourn->Rounds, 5,           '1 round by default');
is ( $agaTourn->Round, 0,            'current round is 0');
is_deeply($agaTourn->Name,
          { USA31742 => 'Player, Strong A.',
            USA31718 => 'Schwei, Samuel',
            USA31749 => 'Tsai, Ralph E.',
            TMP31705 => 'Chien, Mark',
           },                           'names hash is OK');
is ( $agaTourn->NameLength, 17,      'nameLength is 17');
is_deeply($agaTourn->Rating,
          { USA31742 => '6.5',
            USA31718 => '2.5',
            USA31749 => '-1.6',
            TMP31705 => '-5.5',
           },                           'ratings hash is good');

is_deeply($agaTourn->Comment,
          { USA31742 => '12/31/2004 CA',
            USA31718 => '03/02/2004 CA',
            USA31749 => '01/13/2004',
            TMP31705 => '',
           },                           'comments hash is good');
is ( $agaTourn->Error, 0,            'no errors yet');
is_deeply($agaTourn->GamesList, [],  'games list array is emtpy');
is ( $agaTourn->WhichBandIs('4k'), 3,   '4k band is set');
is ( $agaTourn->BandName(0), '6d 3d', 'band 0 name');
is ( $agaTourn->BandName(2), '1k 3k', 'band 2 name');

##
## try the parsing commands
##

is_deeply($agaTourn->ParseTdListLine(
    'Player, B.  3456  Limit 2.3 05/28/1991 PALO CA'),
    { agaRank => undef,
      agaNum => 3456,
      agaRating => 2.3,
      name => 'Player, B.',
      country => 'USA',
      club => 'PALO',
      memType => 'Limit',
      expire => '05/28/1991',
      state => 'CA',
      },                                'parse TDLIST line');

is_deeply($agaTourn->ParseRegisterLine(
    'TMP10 Player, A.    2.3 CLUB=Club    # comment'),
    { agaRank => undef,
      agaNum => 10,
      comment => 'comment',
      flags => '',
      agaRating => 2.3,
      name => 'Player, A.',
      country => 'TMP',
      club => 'Club',
     },                                 'parse register line');

##
## try some rank conversions
##
is( $agaTourn->RankToRating('15k'), -15.5,      'convert 15k to rating');
is( $agaTourn->RankToRating('2d'),    2.5,      'convert 2d to rating');
is( $agaTourn->RankToRating(-12.3), -12.3,      'convert -12.3 to rating');
is( $agaTourn->RankToRating(6.8),     6.8,      'convert -12.3 to rating');

is( $agaTourn->ReadRoundFile('t/1.tde'), 1,       'read 1.tde');
is_deeply($agaTourn->GamesList,
          ['USA31742,USA31749,b,5,-5,1',
           'USA31718,TMP31705,?,5,-5,1'
          ],  'games list array is good');

##
## end of tests
##

__END__
