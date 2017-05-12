package MAB2::Record::Base;
our $VERSION = '0.03';

use Encode::MAB2;

=head1 NAME

MAB2::Record::Base - Access an MAB2 record

=head1 SYNOPSIS

 use MAB2::Record::Base;

 # Constructor
 my $mab2raw = "00296nM2.01200024      k001 1000016-1\c^002a19890418".
    "\c^004 20010812\c^028b1000016-1\c^029 HK00158537\c^030 aa1dc".
    "|m\c^036aIT\c^066 |\c^070 9002\c^070aHBZ\c^800 Accademia Na".
    "zionale di San Luca <Roma>\c^810 Accademia di San Luca <Roma, A".
    "ccademia Nazionale di San Luca>\c^850aReale Accademia di San Lu".
    "ca <Roma>\c^852a45335-3\c^\c]";
 my $mab2 = MAB2::Record::Base->new($mab2raw);
 # $mab2 now blessed into MAB2::Record::gkd because it is a gkd record

 # various representations:
 print $mab2->id;             # just the ID
 print $mab2->readable;       # quite readable
 print $mab2->as_string;      # the raw string we put into it
 print $mab2->dump;           # only useful for debugging the module itself


=head1 DESCRIPTION

C<MAB2::Record::Base> is the common base class for all classes
implementing MAB2 record types:

 MAB2::Record::gkd
 MAB2::Record::lokal
 MAB2::Record::pnd
 MAB2::Record::swd
 MAB2::Record::titel

The constructor C<new> takes a raw MAB2 record as argument and returns
an object which is blessed into one of the five above listed classes.
Some level of proficiency in dealing with MAB2 records is needed for
the user of this module for further processing of the objects. It is
recommended to use C<Data::Dumper> to get acquainted with the raw format
of the created objects.

For illustration purpose, here is the Data::Dumper output of the full
object into which the sample record from the SYNOPSIS section is
transformed:

  $VAR1 = bless( [
                   '...',
                   undef,
                   [
                     {
                       'nicht_benutzt' => [
                                            '      '
                                          ],
                       'datenanfangsadresse' => [
                                                  '00024'
                                                ],
                       'satztyp' => [
                                      'k',
                                      'Koerperschaftsnamensatz (MAB-GKD)'
                                    ],
                       'versionsangabe' => [
                                             'M2.0'
                                           ],
                       'satzstatus' => [
                                         'n',
                                         'neuer Datensatz'
                                       ],
                       'indikatorlaenge' => [
                                              '1'
                                            ],
                       'satzlaenge' => [
                                         '00296'
                                       ],
                       'teilfeldkennungslaenge' => [
                                                     '2'
                                                   ]
                     },
                     [
                       [
                         '001',
                         ' ',
                         '1000016-1',
                         'identifikationsnummer des datensatzes'
                       ],
                       [
                         '002',
                         'a',
                         '19890418',
                         'datum der ersterfassung / fremddatenuebernahme'
                       ],
                       [
                         '004',
                         ' ',
                         '20010812',
                         'erstellungsdatum des austauschsatzes'
                       ],
                       ...
                       [
                         '810',
                         ' ',
                         'Accademia di San Luca <Roma, Accademia Nazionale di San 
  Luca>',
                         '1. verweisungsform zum namen der koerperschaft'
                       ],
                       [
                         '850',
                         'a',
                         'Reale Accademia di San Luca <Roma>',
                         '1. frueherer, zeitweiser oder spaeterer name der koerper
  schaft'
                       ],
                       [
                         '852',
                         'a',
                         '45335-3',
                         'identifikationsnummer des 1. frueheren, zeitweisen oder 
  spaeteren namens'
                       ]
                     ]
                   ],
                   '...'
                 ], 'MAB2::Record::gkd' );


Please note that the object contains both the original string in its
own byte oriented encoding and all fields in Unicode. The conversion
is done by the C<Encode::MAB2> module.

The normal way of accessing MAB2 records is through the use of either
the C<Tie::MAB2::Recno> or C<Tie::MAB2::Id> class. The C<Tie::MAB2::Recno>
class binds an MAB2 file to an array and each record in the original
MAB2 file to an array element starting with element 0. The
C<Tie::MAB2::Id> class binds to a hash with the MAB2 identifier as the
key.

=head1 Overloading

The tied objects have their stringifier overloaded to the
C<as_string()> method so that

    print $tie[1234];

always prints the record as the unaltered original input record.

=head1 SEE ALSO

C<Encode::MAB2>, C<Tie::MAB2::Recno>, C<Tie::MAB2::Id>


=cut

use constant RAW => 0;
use constant INTERNALS => 1; # maybe nonsense: sometimes recno,
                             # sometimes id, whatever the *caller*
                             # wants to have there
use constant STRUCT => 2;
use constant DUMPVALUE => 3;

use strict;
use overload '""' => "as_string";

use Dumpvalue;
our $DV = Dumpvalue->new(unctrl => "quote");

our $DEBUG;
$DEBUG = 1 unless defined $DEBUG;
our $NAMESPACE = "MAB2::Record";
my $KDocs;
my $RDocs;
our(%type2pack) = qw(
                  h titel
                  y titel
                  u titel
                  v titel
                  p pnd
                  t pnd
                  k gkd
                  w gkd
                  r swd
                  s swd
                  x swd
                  l lokal
                  e lokal
                  z lokal
                 );

{
  local $/;
  my $strdocs = <DATA>;
  close DATA;
  ($KDocs, $RDocs) = __PACKAGE__->parsedoc($strdocs);
}

{
  my %seen;
  for my $pack (grep !$seen{$_}++, values %type2pack) {
    my $req = "MAB2/Record/$pack.pm";
    require $req;
  }
}

sub parsedoc {
  my $self = shift;
  my $strdocs = shift;

  $strdocs =~ s/ ^ .*?\n (?=\d ) //sx; # remove header

  my @docs = $strdocs =~ /\G(\d.*?\n)(?=\d|$)/sgc; # split into subdocuments
  my @kennungdocs;
  my @realrecdocs;
  for my $doc (@docs) {
    $doc =~ s/\s+\z//;
    if ($doc =~ /^\d\d?\s/) {
      push @kennungdocs, [$doc];
    } elsif ($doc =~ /^\d\d\d-/) {
      next;
    } elsif ($doc =~ /^\d--/) {
      next;
    } else {
      push @realrecdocs, [$doc];
    }
  }
  my %seen = ();
  for my $k (0..$#kennungdocs) {
    my $kdoc = $kennungdocs[$k];
    my $doc = $kdoc->[0];
    my($line1,$kexplain) = $doc =~ /(^[^\n]+)(?:\n(.+))?/s;
    # print "line1: $line1\n";
    my($start,$to,$name) = $line1 =~ m{ ^ (\d+) (.{8}) \s+ (.*) }x; #
    my $length = 0;
    if ($to =~ /-\s(\d+)/) {
      $length = $1 - $start;
    }
    $length++;                  # 0->1, 4->5 :-)
    $name = lc $name;
    $name =~ s/[^a-z0-9_]/_/g;
    die if $seen{$name}++;
    # print "start: $start\n";
    # print "name: $name\n";
    # print "kexplain: $kexplain\n" if defined $kexplain;
    my %kexplain;
    if ($kexplain && length $kexplain) {
      my @code = $kexplain =~ /\G\s+([a-z])\s=\s(.*?)(?=\n\s+[a-z]\s=\s|$)/sgc;
      %kexplain = @code;
      for my $e (keys %kexplain) {
        $kexplain{$e} =~ s/^\s+//;
        $kexplain{$e} =~ s/\s+$//;
        $kexplain{$e} =~ s/\s+/ /gs;
        # print "ex $e: $kexplain{$e}\n";
      }
    }
    $kdoc->[1] = $start;
    $kdoc->[2] = $length;
    $kdoc->[3] = $name; # all uppercase hurts
    $kdoc->[4] = \%kexplain;
  }
  %seen = ();
  local $| = 1;
  for my $r (0..$#realrecdocs) {
    my $rdoc = $realrecdocs[$r];
    my $doc = $rdoc->[0];
    # print "========>\n", $doc, "\n<========";

    # very different from above, because "line1" can be more than one line
    my($line1,$rexplain) = $doc =~ /^((?:[^\n]|\n(?!\n))+)(?:\n\n(.+))?/s;
    $line1 =~ s/^\s+//;
    $line1 =~ s/\s+$//;
    $line1 =~ s/\s+/ /g;
    $line1 =~ s/^(\d+)\s+//;
    my($codenr) = $1;
    die "seeing again $codenr???" if $seen{$codenr}++;
    if ($rexplain) {
      # $rexplain =~ s/^\s+Indikator:\s+//g;
      $rexplain =~ s/^\s+//g;
    } else {
      $rexplain = "";
    }
    # print "self[$self]codenr[$codenr]rexplain[$rexplain]\n" if defined $rexplain;
    $rdoc->[1] = $codenr;
    $rdoc->[2] = undef;
    $rdoc->[3] = $line1;
    $rdoc->[4] = $rexplain;  # XXX this needs to become more useful
    # than just plain text
  }
  my $end = $#realrecdocs;
  for my $r (0..$end) {
    next unless $realrecdocs[$r][4] && $realrecdocs[$r][4] eq "...";
    my $after_yadda = $realrecdocs[$r+1][1];
    # print "Found >>...<< in $realrecdocs[$r][1], need to fill upto $after_yadda";

    # Ich will vielleicht eine Zahl in diesem Text hochzaehlen
    if (my($foundnumber) = $realrecdocs[$r][3] =~ /(\d+)/) {
      my $step = 1;
      my $rr3 = $realrecdocs[$r][3];
      if ($rr3 eq "ZUSAETZLICHE ANGABEN ZUR 2. VERWEISUNGSFORM") {
        $step = 2;
      } elsif ($rr3 eq "IDENTIFIKATIONSNUMMER DES 2. FRUEHEREN, ZEITWEISEN ODER SPAETEREN NAMENS DER KOERPERSCHAFT") {
        # gkd
        $step = 3;
      } elsif ($rr3 eq "ERLAEUTERUNGEN ZUR 2. SCHLAGWORTKETTE") {
        $step = 5;
      } elsif ($rr3 eq "KOERPERSCHAFT, BEI DER DIE 2. PERSON BESCHAEFTIGT IST") {
        $step = 4;
      } elsif ($rr3 eq "IDENTIFIKATIONSNUMMER DES KOERPERSCHAFTSNAMENSATZES DER 2. KOERPERSCHAFT") {
        $step = 2;
      } elsif ($rr3 eq "ZUSAETZE ZUM 2. PARALLELSACHTITEL") {
        $step = 4;
      } elsif ($rr3 eq "SACHTITEL DER 2. NE") {
        $step = 6;
      }
      my $before_yadda = $realrecdocs[$r][1];
      for my $offset (1..$step) {
        # warn "offset[$offset]";
        my $first = $before_yadda + $offset;
        my $blueprint = $first - $step;
        # warn "first[$first]blueprint[$blueprint]";
        my $blueprintrec;
        for my $rr (@realrecdocs) {
          # warn "DEBUG: rr1[$rr->[1]]";
          next unless $rr->[1] == $blueprint;
          $blueprintrec = $rr;
          last;
        }
        next unless $blueprintrec;
        die "Unexpected blueprintrec3[$blueprintrec->[3]]"
            unless $blueprintrec->[3] =~ /2/;
        my $sprintf = $blueprintrec->[3];
        $sprintf =~ s/2/%d/;
        my $foundnumber = 2;
        for (my $nr = $first; $nr<$after_yadda; $nr+=$step) {
          push @realrecdocs, [
                              ">>>generated<<<",
                              sprintf("%03d", $nr),
                              undef,
                              sprintf($sprintf,++$foundnumber),
                              undef
                             ];
        }
      }
    } else {
      for my $i ($realrecdocs[$r][1]+1..$after_yadda-1) { # $after_yadda (sans -1) XXX
        push @realrecdocs, [
                            ">>>same as $realrecdocs[$r][1]<<<",
                            sprintf("%03d", $i),
                            undef,
                            $realrecdocs[$r][3],
                            undef
                           ];
      }
    }
  }
  # Now realrecdocs is unsorted, but we prefer it as a hash anyway
  my %realrecdocs;
  for my $rdoc (@realrecdocs) {
    $realrecdocs{$rdoc->[1]} = $rdoc;
  }

  return(\@kennungdocs,\%realrecdocs);
}

sub new {
  my($me,$raw,$key) = @_;
  my $self = bless [$raw,$key], ref $me || $me;
  if ( my $pack = $self->_class() ) { # was $struct->[0]{satztyp}[0]
    bless $self, "MAB2::Record::$pack";
  } else {
    die "Couldn't determine class.";
  }
  $self;
}

sub as_string {
  my($self) = @_;
  $self->[RAW];
}

sub readable {
  my($self) = @_;
  $self->_struct;
  my @m;
  my $base = $self->[STRUCT][0];
  my $cont = $self->[STRUCT][1];
  for my $k (sort keys %$base) {
    my $v;
    if (@{$base->{$k}}>1) {
      $v = sprintf "%s (%s)", @{$base->{$k}};
    } else {
      $v = $base->{$k}[0];
    }
    push @m, sprintf "%-25s: %s", $k, $v;
  }
  for my $sr (@$cont) {
    my $print = sprintf "%3s %1s %s [%s]", map { Dumpvalue::unctrl($_); } @$sr;
    if (0 && $print =~ /[^\040-\177]/) {
      $print .= sprintf("\n=%s\n=%s",
                        Encode::encode("ascii",$sr->[2],Encode::FB_XMLCREF()),
                        $sr->[2],
                       );
    }
    push @m, $print;
  }
  join "\n", @m;
}

sub dump {
  my($self) = @_;
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
  $self->_struct;
  my $x = Data::Dumper::Dumper($self);
  $x =~ s/\[\n\s+/[/g;
  $x =~ s/\n\s+\]/]/g;
  $x =~ s/',\n\s+'/', '/g;
  $x;
}

sub _class {
  my $self = shift;
  my $type = substr($self->[RAW],23,1);
  warn "ALERT: type[$type]" unless exists $type2pack{$type};
  $type2pack{$type};
}

sub id {
  my $self = shift;
  my $id;
  if (0) { # 228 secunden fuer Datei 12 (Keywords) ohne debug
    # my $struct = $self->_struct;
    # $id = $struct->[1][0][0] eq "001" ? $struct->[1][0][2] : die;
  } else { # 67 secs fuer gleiche Arbeit, 852 secs fuer 01
    my $raw = $self->as_string;
    ($id) = substr($raw,28) =~ m/([^\c^\c]]+)/;
  }
  # warn "id[$id]";
  # die Dumpvalue::unctrl("id1[$id1]id2[$id2]") unless $id1 eq $id2;
  $id;
}

sub _struct {
  my $self = shift;
  return $self->[STRUCT] if $self->[STRUCT];
  my $struct;
  if ($DEBUG) {
    $self->[DUMPVALUE] = $DV->stringify($self->[RAW]);
  }
  my $derec = Encode::decode("MAB2",$self->[RAW]);
  pos $derec = 0;
  for my $k (@$KDocs) {
    my $re = "."x$k->[2];
    $struct->[0]{$k->[3]}[0] = $1 if $derec =~ /\G($re)/gc;
    ##########^  0=base/kennungsdocs
    if ($DEBUG) {
      $struct->[0]{$k->[3]}[1] = $k->[4]{$1} if %{$k->[4]};
    }
  }
  warn "ALERT: Datenanfangsadresse nicht 24!" unless
      (my $daa = $struct->[0]{datenanfangsadresse}[0]) == 24;
  #    ^^^^^^^^^

  # avoid using stringdata in numeric context, because it turns on IOK
  # or something and the next print prints "24" instead of "00024"

  # strp = structpart of the record
  my(@strp) = $derec =~ / \G (\d\d\d) (.) ([^\c^]+) (?: \c] | \c^ )/xgc; #
  my(@str);
  while (@strp) {
    die "Invalid strp" unless @strp >=3;
    my $str = [ splice @strp, 0, 3 ];
    if ($DEBUG) {
      # die Bezeichnung des Feldes im "real" Record. Da dort alles
      # Uppercase ist, muessen wir lc nehmen, sonst erschlaegt uns das
      $str->[3] = $str->[0] ? lc $self->segmentname($str->[0]) : "UNDEF";
    }
    push @str, $str;
  }
  $struct->[1] = \@str;
  $self->[STRUCT] = $struct;
}

sub segmentname {
  my $self = shift;
  my $rec = shift;
  $RDocs->{$rec}[3];
}

sub subrecords {
  my($self) = shift;
  $self->_struct;
  @{$self->[STRUCT][1]};
}

sub subrecords_ref {
  my($self) = shift;
  $self->_struct;
  $self->[STRUCT][1];
}

sub date_004 {
  my($self) = @_;
  my $sr = $self->subrecords_ref;
  for my $i (0..$#$sr) {
    next unless $sr->[$i][0] eq "004";
    return $sr->[$i][2];
  }
}

1;

# segm000.txt
__DATA__
                                MAB2-Format
                         Satzkennung und Segmente 0--
                       (gueltig fuer alle MAB2-Dateien)

                        Online-Kurzreferenz-Version
                           Stand: November 2001




SATZKENNUNG

0 - 4          Satzlaenge
5              Satzstatus
               c = korrigierter Datensatz (corrected)
               d = geloeschter Datensatz (deleted)
               n = neuer Datensatz
               p = provisorischer Datensatz
               u = umgelenkter Datensatz
               v = unveraenderter Datensatz
6 - 9          Versionsangabe
10             Indikatorlaenge
11             Teilfeldkennungslaenge
12 - 16        Datenanfangsadresse
17 - 22        nicht benutzt
23             Satztyp
               h = Hauptsatz fuer Titeldaten (MAB-TITEL)
               y = Untersatz fuer die Auffuehrung von Abteilungen
                   (MAB-TITEL)
               u = Untersatz fuer die Bandauffuehrung (MAB-TITEL)
               v = Pauschalverweisungssatz oder Siehe-auch-Hinweis
                   (MAB-TITEL)

               p = Personennamensatz (MAB-PND)
               t = Pauschalverweisungssatz oder Siehe-auch-Hinweis
                   (MAB-PND)

               k = Koerperschaftsnamensatz (MAB-GKD)
               w = Pauschalverweisungssatz oder Siehe-auch-Hinweis
                   (MAB-GKD)

               r = Schlagwortkettensatz (MAB-SWD)
               s = Schlagwortsatz (MAB-SWD)
               x = Pauschalverweisungssatz oder Siehe-auch-Hinweis
                   (MAB-SWD)

               q = Notationssatz (MAB-NOTAT)
                     Provisorischer Notationsdatensatz fuer die Angabe
                     von Notationen

               l = Hauptsatz fuer Lokaldaten, die fuer alle Exemplare
                   gueltig sind (MAB-LOKAL)
               e = Untersatz fuer Exemplardaten, die fuer ein oder
                   mehrere Exemplare gueltig sind (MAB-LOKAL)

               m = Adressdatensatz (MAB-ADRESS)
                     Provisorischer Adressdatensatz fuer die Angabe
                     von Adressdaten

               c = Redaktionssatz


001-029   SEGMENT IDENTIFIKATIONSNUMMERN, DATUMS- UND VERSIONS-
          ANGABEN

001       IDENTIFIKATIONSNUMMER DES DATENSATZES

          Indikator:
          Blank = nicht definiert


002       DATUM DER ERSTERFASSUNG / FREMDDATENUEBERNAHME

          Indikator:
          a = Datum der Ersterfassung
          b = Datum der Fremddatenuebernahme


003       DATUM DER LETZTEN KORREKTUR

          Indikator:
          Blank = nicht definiert


004       ERSTELLUNGSDATUM DES AUSTAUSCHSATZES

          Indikator:
          Blank = nicht definiert


005       TRANSAKTIONSDATUM

          Indikator:
          n = letzte Transaktion
          v = vorletzte Transaktion


006       VERSIONSNUMMER

          Indikator:
          n = letzte Transaktion
          v = vorletzte Transaktion


010       IDENTIFIKATIONSNUMMER DES DIREKT UEBERGEORDNETEN
          DATENSATZES

          Indikator:
          blank = nicht definiert


011       IDENTIFIKATIONSNUMMER DER VERKNUEPFTEN SAETZE FUER
          PAUSCHALVERWEISUNGEN UND SIEHE-AUCH-HINWEISE

          Indikator:
          blank = nicht definiert


012       IDENTIFIKATIONSNUMMER DES TITELDATENSATZES (MAB-LOKAL)

          Indikator:
          blank = nicht definiert


015       IDENTIFIKATIONSNUMMER DES ZIELSATZES

          Indikator:
          Blank = nicht definiert


016       IDENTIFIKATIONSNUMMER DES UMGELENKTEN SATZES

          Indikator:
          Blank = nicht definiert


020       IDENTIFIKATIONSNUMMER EINES GELIEFERTEN DATENSATZES

          Indikator:
          blank = nicht spezifiziert
          a     = Ueberregionale Identifikationsnummer
          b     = Regionale Identifikationsnummer
          c     = Lokale Identifikationsnummer


021       IDENTIFIKATIONSNUMMER DER PRIMAERFORM

          Indikator:
          blank = nicht spezifiziert
          a     = Ueberregionale Identifikationsnummer
          b     = Regionale Identifikationsnummer
          c     = Lokale Identifikationsnummer


022       IDENTIFIKATIONSNUMMER DER SEKUNDAERFORM

          Indikator:
          blank = nicht spezifiziert
          a     = Ueberregionale Identifikationsnummer
          b     = Regionale Identifikationsnummer
          c     = Lokale Identifikationsnummer


023       IDENTIFIKATIONSNUMMER DES ZU KORRIGIERENDEN SATZES

          Indikator:
          blank = nicht spezifiziert
          a     = MAB-TITEL
          b     = MAB-PND
          c     = MAB-GKD
          d     = MAB-SWD
          e     = MAB-NOTAT
          f     = MAB-ADRESS

          Unterfelder:
          $a    = Identifikationsnummer des zu korrigierenden Datensatzes


025       UEBERREGIONALE IDENTIFIKATIONSNUMMER

          Indikator:
          blank = nicht spezifiziert
          a     = DDB
          b     = BNB
          c     = Casalini libri
          e     = ekz
          f     = BNF
          g     = ZKA
          l     = LoC
          o     = OCLC
          z     = ZDB


026       REGIONALE IDENTIFIKATIONSNUMMER

          Indikator:
          blank = nicht spezifiziert
          a     = Bibliotheksverbund Berlin-Brandenburg
          b     = Norddeutscher Bibliotheksverbund (bis 1996)
          c     = Bibliotheksverbund Niedersachsen/Sachsen-Anhalt
                  (bis 1996)
          d     = Nordrhein-Westfaelischer Bibliotheksverbund
          e     = Hessisches Bibliotheksinformationssystem
          f     = Suedwestdeutscher Bibliotheksverbund
          g     = Bibliotheksverbund Bayern
          h     = Gemeinsamer Bibliotheksverbund der Laender Bremen,
                  Hamburg, Mecklenburg-Vorpommern, Niedersachsen,
                  Sachsen-Anhalt, Schleswig-Holstein, Thueringen
                  (ab 1996)


027       LOKALE IDENTIFIKATIONSNUMMER

          Indikator:
          blank = nicht spezifiziert
          a     = gepruefte Identifikationsnummer
          b     = ungepruefte Identifikationsnummer


028       IDENTIFIKATIONSNUMMER VON NORMDATEN

          Indikator:
          blank = nicht spezifiziert
          a     = Identifikationsnummer der PND
          b     = Identifikationsnummer der GKD
          c     = Identifikationsnummer der SWD


029       SONSTIGE IDENTIFIKATIONSNUMMER DES VORLIEGENDEN
          DATENSATZES

          Indikator:
          blank = nicht spezifiziert




030-035   SEGMENT ALLGEMEINE VERARBEITUNGSTECHNISCHE ANGABEN

030       CODIERTE ANGABEN ZUM DATENSATZ

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Bearbeitungsstatus
               a = Autopsie
               b = teilweise Autopsie
               c = Uebernahme aus Nationalbibliographie
               d = Uebernahme aus anderen Quellen
               e = konvertierte Altdaten
               f = CIP-Aufnahme
               g = vervollstaendigte CIP-Aufnahme
               h = ohne Autopsie
               u = maschinelle Umsetzung einer Titelaufnahme,
                   die nicht nach RAK erstellt ist
               z = keine Angabe

            1  Ansetzungsstatus (Normdateien)
               a = ueberregional autorisierte Ansetzungsform
               b = regional autorisierte Ansetzungsform
               c = lokal autorisierte Ansetzungsform
               d = nicht autorisierte Ansetzungsform
               e = maschinell ermittelte Ansetzungsform
               f = vorlaeufige Ansetzung
               z = keine Angabe

            2  Zeichenvorrat
               1 = MAB-Zeichenvorrat
               3 = DIN 31628, Stufe 1
               5 = DIN 31628, Stufe 2
               7 = DIN 31628, Stufe 3
               z = Sonstiger Zeichenvorrat

            3  Zeichencode
               a = DIN 66003-DRV
               b = DIN 66003-IRV
               c = DIN 66003 + DIN 31624
                   Die DIN-Normen entsprechen dem Zeichenvorrat
                   von DIN 31628, Stufe 2.
               d = ISO 646 (IRV) + ISO 5426
                   Im MAB-Zeichensatz sind die Zeichen in
                   ISO 646 (IRV) und ISO 5426 (in der vorlaeufigen
                   deutschen Version) definiert.
               i = Industriestandard  (=  festgelegte
                   Zeichensatztabellen IBM-kompatibler PC's
                   fuer MS-DOS-Anwendungen)
               u = Unicode / ISO 10646 (UTF 8)
               z = Sonstiger Zeichencode

            4  Regeln fuer die Formalerschliessung
               a = RAK-Anwendung der Deutschen Bibliothek
               b = RAK-OEB mit alternativen Ansetzungsformen
               c = RAK-WB
               d = Sonstige RAK-Anwendung
               e = DIN 1505
               f = PI - Instruktionen fuer die alphabetischen
                   Kataloge der preussischen Bibliotheken
               g = RNA - Regeln fuer Nachlaesse und Autographen
               h = Formalerschliessung nach dem Verzeichnis der
                   Drucke des 16. Jahrhunderts (VD 16)
               i = Formalerschliessung nach dem Verzeichnis der
                   Drucke des 17. Jahrhunderts (VD 17)
               k = maschinelle Umsetzung aus AACR
               z = Sonstiges Regelwerk

            5  Regeln fuer die Sacherschliessung
               r = RSWK
               s = RSWK-Alternativregeln
               z = Sonstiges Regelwerk

            6  Regeln fuer die Normdatenansetzung
               g = RNA - Regeln fuer Nachlaesse und Autographen
               h = Ansetzung nach dem Verzeichnis der Drucke des
                   16. Jahrhunderts (VD 16)
               i = Ansetzung nach dem Verzeichnis der Drucke des
                   17. Jahrhunderts (VD 17)
               k = LOC Name Authority
               l = PND-Ansetzungsform
               m = GKD-Ansetzungsform
               n = SWD-Ansetzungsform
               r = RSWK
               s = RSWK-Alternativregeln
               z = Sonstiges Regelwerk

            7   Transliteration/Transkription
                a = Transliteration
                b = Transkription
                z = keine Angabe

            8   Stichwortkennung
                a = Stichwortanfang- und Stichwortendezeichen
                b = Stichwortanfangszeichen
                c = eigene Stichwortfelder

         9-10   Faecherstatistik
                Die Faecherstatistik erfolgt nach der Deutschen
                Bibliotheksstatistik (DBS).

            11  Haupteintragungstyp
                1 = Verfasserwerk
                2 = Urheberwerk
                3 = Sachtitelwerk

            12  Ordnungssachtitel
                4 = Ordnungssachtitel ist der Inhalt des
                    Feldes 304
                5 = Ordnungssachtitel ist der Inhalt des
                    Feldes 310
                7 = Ordnungssachtitel ist der Inhalt des
                    Feldes 331


031       ANGABEN ZUM REDAKTIONSSATZ

          Indikator:
          blank = nicht definiert

          Unterfelder:
          $a    = Art des Redaktionssatzes
          $b    = Stand der redaktionellen Bearbeitung
          $c    = Weitere Angaben zum Redaktionssatz
          $d    = Inhalt des neuen (korrigierten) Feldes
          $e    = Grund des Redaktionssatzes



036-049   SEGMENT ALLGEMEINE CODIERTE ANGABEN

036       LAENDERCODE

          Indikator:
          blank = nicht spezifiziert
          a     = zweibuchstabiger Laendercode nach DIN EN 23166
          b     = dreibuchstabiger Laendercode nach DIN EN 23166
          c     = Laendercode der SWD
          z     = sonstiger Laendercode


037       SPRACHENCODE

          Indikator:
          blank = nicht spezifiziert
          a     = Sprachencode nach DIN 2335
          b     = Sprachencode nach ISO 639
          c     = Sprachencode nach Z39.53 (USMARC, UNIMARC)
          z     = Sonstiger Sprachencode


038       CODE FUER HERKUNFTSSPRACHE / SPRACHE DES ORIGINALS

          Indikator:
          blank = nicht spezifiziert
          a     = Sprachencode nach DIN 2335
          b     = Sprachencode nach ISO 639
          c     = Sprachencode nach Z39.53 (USMARC, UNIMARC)
          z     = Sonstiger Sprachencode


039       ZEITCODE

          Indikator:
          blank = nicht spezifiziert
          a     = Zeitcode der Universalen Dezimal-
                  Klassifikation (UDK-Zeitcode)
          b     = Time Period Code der Library of Congress
          c     = Zeitcode nach Jahreszahlen
          z     = Sonstiger Zeitcode


040       NOTATION FUER NORMDATEN

          Indikator:
          blank = nicht spezifiziert


041       NOTATIONSSPEZIFISCHE CODIERUNGEN

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0   Art der Notation
                blank = Systematik der katalogisierenden Institution
                a     = UDC     (Universal Decimal Classification)
                b     = DDC     (Dewey Decimal Classification)
                c     = LC      (Library of Congress Classification)
                d     = DNB     (Systematik der Deutschen Nationalbibliographie)
                e     = Methode Eppelsheimer
                g     = Regensburger Verbundklassifikation
                h     = Gesamthochschulbibliothekssystematik (GHBS)
                l     = RPB     (Rheinland-Pfaelzische Bibliographie)
                m     = MSC     (Mathematics Subject Classification)
                n     = NWBib   (Nordrhein-Westfaelische Bibliographie)
                o     = ASB     (Allgemeine Systematik für Bibliotheken)
                p     = SSD     (Systematik der Stadtbibliothek Duisburg)
                q     = SfB     (Systematik für Bibliotheken)
                r     = KAB     (Klassifikation für Allgemeinbibliotheken)
                s     = Systematiken der ekz
                t     = Systematik der TUB Muenchen
                u     = DOPAED der UB Erlangen
                v     = IFZ-Systematik
                w     = Systematik der Bayerischen Bibliographie
                z     = ZDB-Systematik

            1   Art der Notation bei Anwendung der Methode Eppelsheimer
                a     = Notation des systematischen Katalogs
                b     = Notation des Laenderkatalogs
                c     = Notation des biographischen Katalogs
                d     = Notation des Ortskatalogs



050-064   SEGMENT  VEROEFFENTLICHUNGS- UND MATERIALSPEZIFISCHE
          ANGABEN

050       DATENTRAEGER

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Druckschrift
               a = nicht spezifiziert

            1  Handschrift
               a = nicht spezifiziert

            2  Papierzustand
               a = nicht spezifiziert
               b = saeurefreies, alterungsbestaendiges Papier
               c = kein saeurefreies, kein alterungsbestaendiges
                   Papier
               d = entsaeuertes Papier
               e = Pergament
               z = sonstiges Material

            3  Mikroform
               a = nicht spezifiziert
               b = Mikroform-Master
               c = Sekundaerform

            4  Blindenschrifttraeger
               a = nicht spezifiziert

          5-6  Audiovisuelles Medium / Bildliche Darstellung

               Tontraeger:
               aa = CD-DA (Compact Disc Digital Audio, Single
                    Compact Disc)
               ab = CD-Bildplatte
               ac = Tonband
               ad = Compact-Cassette
               ae = Micro-Cassette (Diktier- oder Stenocassette)
               af = Digital Audio Tape (DAT-Cassette)
               ag = Digital Compact Cassette (DCC-Cassette)
               ah = Cartridge (8-Track Cartridge)
               ai = Drahtton (Stahlband)
               aj = Schallplatte
               ak = Walze (Zylinder)
               al = Klavierrolle (Mechanisches Klavier)
               am = Filmtonspur
               an = Tonbildreihe

               Film, visuelle Projektion:
               ba = Filmspulen
               bb = Film-Cartridge
               bc = Film-Cassette
               bd = Anderes Filmmedium
               be = Filmstreifen
               bf = Filmstreifen-Cartridge
               bg = Filmstreifen-Rolle
               bh = Anderer Filmstreifentyp
               bi = Diapositiv, Diaset, Stereograph
               bj = Arbeitstransparent
               bk = Arbeitstransparentstreifen

               Videoaufnahme:
               ca = Videobandcassette
               cb = Videobandcartridge
               cc = Videobandspulen
               cd = Bildplatte (Videodisc)
               ce = Anderer Videotyp

               Bildliche Darstellung:
               da = Foto
               db = Kunstblatt (Originalgraphik, Nachdruck)
               dc = Plakat

               Sonstige Angaben:
               uu = unbekannt
               yy = nicht spezifiziert
               zz = sonstige audiovisuelle Medien

            7  Medienkombination
               a = nicht spezifiziert

            8  Computerdatei
               a = nicht spezifiziert
               b = Diskette(n)
               c = Magnetbandkassette(n)
               d = Optische Speicherplatte(n)
                   (z.B. CD-ROM, CD-I, Photo-CD, WORM, DVD)
               e = Einsteckmodul(e)
               f = Magnetband, Magnetbaender
               g = Computerdatei(en) im Fernzugriff
               z = sonstige Computerdatei(en)

            9  Spiele
               a = nicht spezifiziert

           10  Landkarten
               a = nicht spezifiziert

        11-13  Anzahl der physischen Einheiten


051     VEROEFFENTLICHUNGSSPEZIFISCHE ANGABEN ZU BEGRENZTEN
        WERKEN

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Erscheinungsform
               a = unselbstaendig erschienenes Werk
               f = Fortsetzung
               m = einbaendiges Werk - nicht Teil eines
                   Gesamtwerks
               n = mehrbaendiges begrenztes Werk - nicht Teil
                   eines Gesamtwerks
               s = einbaendiges Werk  u n d  Teil (mit
                   Stuecktitel) eines Gesamtwerks
               t = mehrbaendiges begrenztes Werk  u n d
                   Teil (mit Stuecktitel) eines Gesamtwerks

          1-3  Veroeffentlichungsart und Inhalt
               a = Abstract (Referat)
               b = Bibliographie
               c = Katalog
               d = Woerterbuch
               e = Enzyklopaedie
               f = Festschrift
               g = Datenbank
               h = Biographie
               i = Registerwerk
               j = Fortschrittsbericht
               k = Konferenzschrift
               l = Gesetz
               m = Musikalia
               n = Normschrift
               o = Loseblattausgabe
               p = Patentdokument
               q = Lieferungswerk
               r = Report
               s = Statistik
               t = Aufsatz
               u = Universitaetsschrift
               v = Sonderdruck
               x = Schulbuch
               z = sonstige Veroeffentlichungsart/-inhalt

            4  Literaturtyp
               f = Fachbuch
               k = Kinderbuch, Jugendbuch, Schulbuch
               l = Lehrbuch
               p = populaerwissenschaftliche Literatur
               s = Belletristik
               t = Trivialliteratur
               w = wissenschaftliche Literatur
               z = Sonstiges

            5  Reprint-Kennzeichen
               r = Reprint

            6  Kennzeichnung Amtlicher Druckschriften
               b = Regierungsbezirksebene
               f = nationalstaatliche Ebene
               i = internationale Ebene (multinational)
               k = Kreis
               l = lokale Ebene (Stadt, Gemeinde)
               m = mehrere amtliche Koerperschaften innerhalb
                   eines Staates sind beteiligt
               o = Koerperschaft des oeffentlichen Rechts
               r = Region
               s = Land (Provinz)
               u = sonstige amtliche Druckschrift


052       VEROEFFENTLICHUNGSSPEZIFISCHE ANGABEN ZU FORTLAUFENDEN
          SAMMELWERKEN

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Erscheinungsform
               a = unselbstaendig erschienenes Werk
               f = Fortsetzung
               j = zeitschriftenartige Reihe
               p = Zeitschrift
               r = Schriftenreihe (Serie)
               z = Zeitung

          1-6  Veroeffentlichungsart und Inhalt
               ab = Abstract (Referat)
               aa = Amtsblatt
               am = Amts- und Gesetzblatt
               az = Anzeigenblatt
               au = Aufsatz
               bi = Bibliographie
               kt = Bibliothekskatalog
               da = Datenbank
               di = Directory
               es = Entscheidungssammlung
               ft = Fachzeitung
               fz = Firmenzeitschrift/-zeitung
               fb = Fortschrittsbericht
               ag = Gesetz(und Verordnungs-)blatt
               ha = Haushaltsplan
               il = Illustrierte
               in = Index
               ko = Konferenzschrift / Kongressbericht
               mg = Magazin
               me = Messeblatt
               pa = Parlamentaria
               rf = Referateorgan
               re = Report-Serie
               sc = Schul- / Universitaetsschrift
               se = Serie
               so = Sonderdruck
               xj = Sonstige Periodika, juristische
               st = Statistik
               ub = Uebersetzungszeitschrift
               bg = Biographie
               ez = Enzyklopaedie
               li = Lieferungswerk
               lo = Loseblattausgabe
               mu = Musikalia
               no = Normschrift
               pt = Patentdokument
               rg = Registerwerk
               uu = sonstige Veroeffentlichungsart/-inhalt

               ao = Zeitung fuer die allgemeine Oeffentlichkeit
               eo = Zeitung fuer eine eingeschraenkte
                    Oeffentlichkeit
               up = Ueberregionale Zeitung
               rp = Regionale Zeitung
               lp = Lokale Zeitung

            7  Publikationsstatus
               a = fortlaufende Publikation ohne geplanten
                   Abschluss
               f = Titelaenderung
               t = eingestelltes Erscheinen
               z = keine Angabe moeglich

         8-10  Erscheinungsweise
               d = taeglich
               t = drei- bis fuenfmal woechentlich
               c = zweimal woechentlich
               w = woechentlich
               e = vierzehntaegig
               s = halbmonatlich
               m = monatlich
               b = alle zwei Monate
               q = vierteljaehrlich
               f = halbjaehrlich
               a = jaehrlich
               g = alle zwei Jahre
               h = alle drei Jahre
               z = unregelmaessig oder sonstige Erscheinungsweise

           11  Reprint-Kennzeichen
               r = Reprint

           12  Kennzeichnung Amtlicher Druckschriften
               b = Regierungsbezirksebene
               f = nationalstaatliche Ebene
               i = internationale Ebene (multinational)
               k = Kreis
               l = lokale Ebene (Stadt, Gemeinde)
               m = mehrere amtliche Koerperschaften innerhalb
                   eines Staates sind beteiligt
               o = Koerperschaft des oeffentlichen Rechts
               r = Region
               s = Land (Provinz)
               u = sonstige amtliche Druckschrift

        13-14  Erscheinungsform
               a = unselbstaendig erschienenes Werk
               f = Fortsetzung
               j = zeitschriftenartige Reihe
               p = Zeitschrift
               r = Schriftenreihe (Serie)
               z = Zeitung


053       NACHLAESSE UND AUTOGRAPHEN

          Indikator:
          blank = nicht definiert

057       MATERIALSPEZIFISCHE CODES FUER MIKROFORMEN

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Materialart
               a = Mikrofilm-Lochkarte
               b = Mikrofilm-Cartridge
               c = Mikrofilm-Cassette
               d = Mikrofilmspule
               e = Mikrofiche (Mikroplanfilm)
               f = Mikrofiche-Kassette
               g = Mikro-opaque (Microcard usw.)
               h = Mikrofilmstreifen
               j = Mikrofilm-Jacket
               u = Unbekannt
               z = Andere

            1  Polaritaet
               a = Positiv
               b = Negativ
               d = Gemischte Polaritaet
               u = Unbekannt

            2  Format der Mikroform
               a =   8 mm                         (Mikrofilm)
               d =  16 mm                         (Mikrofilm)
               f =  35 mm                         (Mikrofilm)
               g =  70 mm                         (Mikrofilm)
               h = 105 mm                         (Mikrofilm)
               l = 76,2x127 mm (3x5 in.)
                   (Mikrofiche oder Mikro-opaque)
               m = 101,6x152,4 mm (4x6 in., d.h. 105x148mm)
                   (Mikrofiche oder Mikro-opaque)
               o = 152,4x228,6 mm (6x9 in.)
                   (Mikrofiche oder Mikro-opaque)
               p = 82,55x187,325 mm (3 1/4 x 7 3/8 in.)
                   (Mikrofilm-Lochkarte)
               u = Unbekanntes Format
               z = Andere Formate

            3  Verkleinerungsrate
               a = Niedrige Verkleinerung
               b = Standardverkleinerung (16x - 30x)
               c = Hohe Verkleinerung (31x - 60x)
               d = Sehr hohe Verkleinerung (61x - 90x)
               e = Extrem hohe Verkleinerung (91x -  )
               u = Unbekannte Verkleinerung
               v = Verschiedene Verkleinerungen

          4-6  Spezifische Verkleinerungsrate

            7  Farbe
               a = Monochrom
               b = Farbig
               u = Unbekannt
               v = Variiert

            8  Emulsion des Filmes
               a = Silberhalogenid
               b = Diazo
               c = Vesikularfilm
               u = Unbekannte Emulsion
               v = Verschiedene Emulsionen
               x = Nicht anwendbar
               z = Andere Emulsion

            9  Generation
               a = Erste Generation (Mutterfilm, Master)
               b = Zweite Generation: Dupliziervorlage
                   (Printing-Master)
               c = Gebrauchskopie
               u = Unbekannt
               v = Verschiedene Generationen

           10  Traegermaterial
               a = Sicherheitstraegermaterial: Polyester,
                   Polyethylenerephtalat
               b = Sicherheitstraegermaterial: Acetatmaterial
                   (Triacetat)
               c = Kein Sicherheitstraegermaterial (z.B.
                   Cellulosenitrat)
               u = Unbekanntes Traegermaterial
               v = Verschiedene Traegermaterialien
               x = Nicht anwendbar




065-069   SEGMENT NORMDATENSPEZIFISCHE ANGABEN

065       NORMDATENSPEZIFISCHE ANGABEN ZUR PND

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Individualisierungskennzeichen
               a = Individualisierter Personennamensatz
               b = Nicht-Individualisierter Personennamensatz

            1  Geschlecht
               m = maennlich
               w = weiblich

            2  Namenstyp
               a = Pseudonym
               b = Verlagspseudonym
               c = Sammelpseudonym
               d = fiktive Person (z.B. literarische Gestalt)
               e = Familien- oder Geschlechtername
               f = Person, stellvertretend fuer ihre Familie
               g = Person, stellvertretend fuer eine ihr
                   zugeordnete Einrichtung (keine Koerperschaft)

            3  Personentyp
               a = Person mit modernem Namen in einer
                   europaeischen Sprache
               b = Person mit modernem Namen in einer nicht-
                   europaeischen Sprache
               c = Person mit biblischem Namen
               d = Person mit altgriechischem Namen
               e = Person mit altroemischem Namen
               f = Person mit sonstigem Namen des Altertums
               g = Person mit mittelalterlichem Namen
                   in einer europaeischen Sprache
               h = Person mit mittelalterlichem Namen in einer
                   nicht-europaeischen Sprache
               i = Person mit byzantinischem Namen
               j = Person mit Fuerstennamen
               k = Person mit Namen eines geistlichen
                   Wuerdentraegers


066       NORMDATENSPEZIFISCHE ANGABEN ZUR GKD

          Indikator:
          blank = nicht defininiert

          Datenelemente:
            0  Typ der Koerperschaft
               blank = nicht spezifizierte Koerperschaft
               c     = Kongress (pauschal)
               d     = Kongress (einzeln)
               f     = Firma
               g     = Gebietskoerperschaft
               k     = kirchliche Koerperschaft
               m     = musikalische Koerperschaft
               u     = Un-Koerperschaft

            1  Stufe der Koerperschaft
               blank = oberste Stufe
               a     = nachgeordnete Stufe


067       NORMDATENSPEZIFISCHE ANGABEN ZUR SWD

          Indikator:
          blank = nicht definiert

          Datenelemente:
            0  Schlagwortkategorie
               p = Personenschlagwort
               k = Koerperschaftsschlagwort (fuer Koerperschaften,
                   die unter ihrem Individualnamen angesetzt werden)
               c = Koerperschaftsschlagwort (fuer Koerperschaften,
                   die unter einem Geographikum angesetzt werden)
               g = geographisches/ethnographisches Schlagwort
               t = Sachtitel eines Werkes
               s = Sachschlagwort
               f = Formschlagwort
               z = Zeitschlagwort

            1  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               1 = konstanter Wert

            2  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               0 = Feld 801 wird nicht permutiert
               1 = Feld 801 wird permutiert

            3  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               0 = Feld 802 wird nicht permutiert

            4  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               0 = Feld 803 wird nicht permutiert

            5  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               0 = Feld 804 wird nicht permutiert

            6  Permutationskennung fuer Hauptschlagwort bzw.
               Schlagwortansetzung
               0 = Feld 805 wird nicht permutiert

            7  Hinweissatz
               a = Hinweissatz zur Benutzung in der SWD


068       NORMDATENSPEZIFISCHE CODIERUNGEN

          Indikator:
          blank = nicht spezifiziert
          a     = Teilbestandskennzeichen
          b     = Autorisierungskennzeichen
          c     = Verwendungskennzeichen
          d     = Herkunftskennzeichen
          e     = Nutzungskennzeichen
          z     = sonstige Codierung




070-075   SEGMENT ANWENDERSPEZIFISCHE DATEN UND CODES

070       IDENTIFIZIERUNGSMERKMALE DER BEARBEITENDEN INSTITUTION

          Indikator:
          blank = Kennzeichen der katalogisierenden Institution
          a     = Kennzeichen der liefernden Institution
          b     = Kennzeichen der korrigierenden Institution


071       IDENTIFIZIERUNGSMERKMALE DER BESITZENDEN INSTITUTION

          Indikator:
          blank = Kennzeichen der besitzenden Institution
                  (Bibliothekssigel)
          a     = Bibliothekskennzeichnung der besitzenden
                  Bibliothek (= BIK)
          b     = Identifikationsnummer der Deutschen
                  Bibliotheksstatistik (DBS)
          c     = Regionales Bibliothekskennzeichen


072       CODIERTE ANGABEN ZUR BESITZENDEN INSTITUTION

          Indikator:
          blank = nicht definiert

          Datenelemente:
          0-2  Leihverkehrsregion
               BAW = Baden-Wuerttemberg, Saarland und Teile von
                     Rheinland-Pfalz
               BAY = Bayern
               BER = Berlin und Brandenburg
               HAM = Hamburg, Bremen und Schleswig-Holstein
               HES = Hessen und Teile von Rheinland-Pfalz
               MEC = Mecklenburg-Vorpommern
               NIE = Niedersachsen
               NRW = Nordrhein-Westfalen und Teile von Rheinland-
                     Pfalz
               SAA = Sachsen-Anhalt
               SAX = Sachsen
               THU = Thueringen
               WEU = Europaeisches Ausland
               WWW = regional und national uebergreifende Bestaende

            3  Leihverkehrsrelevanz der besitzenden Bibliothek
               l = leihverkehrsrelevante Bibliothek
               n = nicht leihverkehrsrelevante Bibliothek
               u = unbekannt bzw. nicht definiert

            4  Benutzungsbeschraenkungen / Ausleihindikator

            5  Geschaeftsgangstatus


073       SONDERSAMMELGEBIETSNUMMER

          Indikator:
          blank = nicht definiert


074       SONDERSAMMELGEBIETSNOTATION

          Indikator:
          blank = nicht definiert


075       ZDB-PRIORITAETSZAHL

          Indikator:
          blank = nicht definiert




076-088   SEGMENT ANWENDERSPEZIFISCHE ANGABEN

076       FREI DEFINIERBARE ANWENDERSPEZIFISCHE ANGABEN,
          KENNZEICHEN UND CODES

...

079       FREI DEFINIERBARE ANWENDERSPEZIFISCHE ANGABEN,
          KENNZEICHEN UND CODES

080       ZUGRIFFS- UND UPDATE-ANWEISUNGEN

081       FREI DEFINIERBARE ANWENDERSPEZIFISCHE ANGABEN,
          KENNZEICHEN UND CODES

...

088       FREI DEFINIERBARE ANWENDERSPEZIFISCHE ANGABEN,
          KENNZEICHEN UND CODES
