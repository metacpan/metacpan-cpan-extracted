package Lingua::31337;

use strict;

use vars qw[%EXPORT_TAGS @EXPORT $VERSION %CONVERSIONS $LEVEL];

%EXPORT_TAGS = ( 'all' => [ qw[ text231337 ] ] );

@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

$VERSION = '0.02';

$LEVEL = 5;

%CONVERSIONS = (

  # handle the vowels
  1   => {
          mixcase => 0,
          chars => {
                    a => 4,
                    e => 3,
                    i => 1,
                    o => 0,
                   },
         },

  # Handle vowels and some consonants,
  # don't use punctuation in the translation,
  # shift case at random.
  5   => {
          mixcase => 1,
          chars => {
                    a => 4,
                    e => 3,
                    f => 'ph',
                    i => 1,
                    l => 1,
                    o => 0,
                    's$' => 'z',
                    t => 7,
                   },
         },

  # Handle vowels and most consonants,
  # use punctuation in the translation,
  # shift case at random,
  # convert some letters.
  7   => {
          mixcase => 1,
          chars => {
                    a => 4,
                    b => '|3',
                    d => '|)',
                    e => 3,
                    f => 'ph',
                    h => '|-|',
                    i => 1,
                    k => '|<',
                    l => 1,
                    'm' => '|\/|',
                    n => '|\|',
                    o => 0,
                    's$' => 'z',
                    t => '-|-',
                    v => '\/',
                    w => '\/\/',
                    x => '><',
                   },
         },

  # Handle vowels and most consonants,
  # use punctuation in the translation,
  # shift case at random,
  # convert some letters to others,
  # decide between several options.
  9   => {
          mixcase => 1,
          chars => {
                    a => [ 4, 'aw' ],
                    b => '|3',
                    ck => 'x',
                    'ck$' => 'x0rz',
                    d => '|)',
                    e => [ 3, 0, 'o' ],
                    'ed$' => 'z0r3d',
                    'er$' => '0r',
                    f => 'ph',
                    h => '|-|',
                    i => 1,
                    k => '|<',
                    l => 1,
                    'm' => '|\/|',
                    n => '|\|',
                    o => 0,
                    's' => 'z',
                    t => '-|-',
                    v => '\/',
                    w => '\/\/',
                    x => '><',
                   },
         },
);

sub text231337 {
  my @text     = @_;
  my @new_text = ();
  
  $LEVEL-- until exists $CONVERSIONS{$LEVEL};
  
  foreach my $line ( @text ) {
    foreach ( keys %{$CONVERSIONS{$LEVEL}->{chars}} ) {
      if ( ref $CONVERSIONS{$LEVEL}->{chars}->{$_} ) {
        $line =~ s/($_)/(0,1)[rand 2] ? @{$CONVERSIONS{$LEVEL}->{chars}{$_}}[rand $#{$CONVERSIONS{$LEVEL}->{chars}{$_}}] : $1/egi;
      } else {
        $line =~ s/($_)/(0,1)[rand 2] ? $CONVERSIONS{$LEVEL}->{chars}{$_} : $1/egi;
      }
    }
    $line =~ s/([A-Z])/(0,1)[rand 2] ? uc($1) : lc($1)/egi if $CONVERSIONS{$LEVEL}->{mixcase};
    push @new_text, $line;
  }
  return @new_text;
}


1;
__END__

=head1 N4M3

Lingua::31337 - P3RL M0DU1E 7O c0NVer7 7ext 7O C0o1 741k

=head1 sYnOPSIs

  use Lingua::31337;
  
  print text231337 "I am an elite hacker.";
  
  $Lingua::31337::LEVEL = 9; # 1udICRUs 1337.
  
  print text231337 "There is no one above my elite skills.";

=head1 DescrIP710n

=head2 text231337( 11s7 );

C0nv3RT tex7 70 C0Ol 7ALk.  returns 7H3 11s7 You SUpPlied, Bu7 CoO13r.

=head2 c<$Lingua::31337::LEVEL>

S3T Y0UR 13VEL 0f e1i7neSs.  tH1s WoRKs 1n a Sim1LAr fAShiOn 70 C<gz1p> COmpR3sS1on l3VE1S.
7HeY gO FRoM 1 T0 9.

=head1 au7h0r

CASEY wES7 <F<C4s3Y@g3EkNest.C0m>>

=head1 C0pYriGHT

COpyRIGH7 (c) 2002 C4S3y R. WES7 <C4SeY@g33KN3S7.c0m>.  A11
R1ghTS r3seRV3d.  7h1s progR4M 1S phREe S0FTw4RE; y0u C4n
R3Distr1bU73 1t 4ND/0r mod1PHy it UnDeR 7hE SAME t3rmS aS
PERL I7S31f.

=head1 S33 4lSo

p3r1(1).

=cut