package Langertha::Holmgang::Haystack;
# ABSTRACT: Long, deterministic operational data for long-context cases, generated from a short spec

use Moose;
use namespace::autoclean;
use utf8;
use JSON::MaybeXS ();
use Langertha::Holmgang::Error;
use Scalar::Util qw( blessed );
use Time::Local ();

our $VERSION = '0.001';


use constant CHARS_PER_TOKEN => 3.5;

my @KINDS = qw( journal syslog nginx-access postgres-log ini-config k8s-manifests runbooks );
my %LOG   = map { $_ => 1 } qw( journal syslog nginx-access postgres-log );
my %SEP   = ( 'ini-config' => "\n\n", runbooks => "\n\n", 'k8s-manifests' => "\n---\n" );
my @KEYS  = qw( kind tokens seed start hours tz host hosts units upstreams database title namespace exclude insert );

has chars_per_token => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_chars_per_token',
);
sub _build_chars_per_token { CHARS_PER_TOKEN }


has _cache => (
  is      => 'ro',
  default => sub { {} },
);

has _json => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build__json',
);
sub _build__json { JSON::MaybeXS->new( canonical => 1, convert_blessed => 1, utf8 => 1 ) }

# A refusal names the field first, then the reason.
sub _refuse {
  my ( $self, $field, $reason ) = @_;
  Langertha::Holmgang::Error->throw( $field, $reason );
}

sub kinds { @KINDS }


sub estimate_tokens {
  my ( $self, $text ) = @_;
  return 0 unless defined $text;
  my $cpt = blessed $self ? $self->chars_per_token : CHARS_PER_TOKEN;
  return int( length($text) / $cpt + 0.5 );
}


#### Random

# xorshift32: the same on every perl with 64-bit integers
sub _rng {
  my ( $self, $seed ) = @_;
  my $s = ( ( $seed * 2654435761 ) + 0x9E3779B9 ) & 0xFFFFFFFF;
  $s ||= 0x12345678;
  my $r = sub {
    $s ^= ( $s << 13 ) & 0xFFFFFFFF;
    $s ^= $s >> 17;
    $s ^= ( $s << 5 ) & 0xFFFFFFFF;
    return $s;
  };
  $r->() for 1 .. 8;
  return $r;
}

sub _int  { my ( $self, $r, $lo, $hi ) = @_; return $lo + $r->() % ( $hi - $lo + 1 ) }
sub _pick { my ( $self, $r, $l ) = @_; return $l->[ $r->() % @$l ] }
sub _hex  { my ( $self, $r, $n ) = @_; return join '', map { sprintf '%x', $r->() % 16 } 1 .. $n }

#### Vocabulary

my @UNITS  = qw( belegimport lieferschein rechnungsversand mahnlauf kundenportal-api lagerdienst );
my @DBHOST = map { 'db'.$_.'.example.invalid' } 1 .. 3;
my @QUEUE  = qw( auftraege belege rueckmeldungen versand inventur );
my @TASK   = ( 'Tagesabschluss', 'Bestandsabgleich', 'Belegarchiv', 'Preisliste', 'Mahnvorschlag', 'Lieferavis', 'Kontenabgleich' );
my @LOCK   = qw( stapel-export kunden-index belegnummern lager-reservierung );
my @MAND   = qw( nord sued west ost zentrale );
my @PFAD   = qw( auftraege belege artikel kunden lager versand status );
my @TAB    = qw( artikel bestellung bestellposition kunde lagerbestand rechnung versandauftrag );

# messages of the invented services (German); placeholders in <...>
my @APP = (
  'Auftrag <n6> verarbeitet in <ms> ms',
  'Beleg <n6> übernommen (Mandant <mand>, <n2> Positionen)',
  'Verbindung zur Datenbank <db> hergestellt (Pool <n1>/<n2>)',
  'Gesundheitsprüfung erfolgreich (<ms> ms)',
  'Zwischenspeicher bereinigt: <n4> Einträge entfernt, <n4> behalten',
  'Stapel <n5> abgeschlossen: <n3> Datensätze, <n1> übersprungen',
  'Nachricht <hex8> aus Warteschlange <queue> bestätigt',
  'Hintergrundaufgabe »<task>« gestartet',
  'Hintergrundaufgabe »<task>« beendet nach <n2> s',
  'Anfrage GET /intern/<pfad>/<n5> beantwortet: 200 in <ms> ms',
  'Sitzungsschlüssel erneuert, gültig bis <hh>:<mm>',
  'Metriken an mon1.example.invalid übertragen (<n3> Werte)',
  'Konfiguration unverändert, kein Neuladen nötig',
  'Datei /srv/archiv/<pfad>/<n6>.json.gz archiviert (<n3> KB)',
  'Export <n5> nach sftp://ablage.example.invalid/<pfad>/ übertragen',
  'Neuer Arbeitsauftrag aus <queue>: <n2> Elemente',
  'Prüfsumme für Paket <n5> stimmt',
  'Abgleich mit Lagerbestand: <n3> Artikel aktualisiert',
  'Wiederholung <n1>/5 für Nachricht <hex8> erfolgreich',
  'Speicher: <n3> MB belegt, <n3> MB frei',
  'Sperre »<lock>« erhalten nach <ms> ms',
  'Sperre »<lock>« freigegeben',
  'Planlauf »<task>« übersprungen: letzter Lauf vor <n2> min',
  'Benachrichtigung an lager-<n2>@example.invalid versendet',
  'Warteschlange <queue>: <n2> offen, <n3> erledigt in der letzten Minute',
  'Antwortzeit <db>: Median <ms> ms, 95. Perzentil <ms> ms',
  'Druckauftrag <n5> an drucker-<n2>.example.invalid übergeben',
  'Kunde <n6>: Adresse geprüft, keine Änderung',
  'Zeitplan geladen: nächster Lauf »<task>« um <hh>:<mm>',
  'Verbindung zu <db> nach Leerlauf geschlossen',
);

my @SYSTEMD = (
  'Starting <svc>.service - <desc>...',
  'Started <svc>.service - <desc>.',
  'Finished <svc>.service - <desc>.',
  '<svc>.service: Deactivated successfully.',
  '<svc>.service: Consumed <n1>.<n3>s CPU time.',
);
my %SYSUNIT = (
  logrotate                => 'Rotate log files',
  'apt-daily'              => 'Daily apt download activities',
  'man-db'                 => 'Daily man-db regeneration',
  sysstat                  => 'system activity accounting tool',
  'systemd-tmpfiles-clean' => 'Cleanup of Temporary Directories',
);

#### Time

my @MON = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

sub _ts {
  my ( $self, $kind, $epoch, $us, $tz ) = @_;
  my ( $s, $m, $h, $d, $mo, $y ) = gmtime $epoch;
  $y += 1900;
  my $off = $tz eq 'CEST' ? '+02:00' : '+01:00';
  return sprintf '%s %02d %02d:%02d:%02d', $MON[$mo], $d, $h, $m, $s if $kind eq 'journal';
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d.%06d%s', $y, $mo + 1, $d, $h, $m, $s, $us, $off if $kind eq 'syslog';
  return sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $d, $MON[$mo], $y, $h, $m, $s, $off =~ s/://r if $kind eq 'nginx-access';
  return sprintf '%04d-%02d-%02d %02d:%02d:%02d.%03d %s', $y, $mo + 1, $d, $h, $m, $s, int( $us / 1000 ), $tz;
}

#### Filler per kind
# Every kind yields line templates with the mark \0 for the timestamp.

sub _fill_app {
  my ( $self, $r, $t ) = @_;
  my %v = (
    n1   => sub { $self->_int( $r, 1, 9 ) },
    n2   => sub { $self->_int( $r, 2, 60 ) },
    n3   => sub { $self->_int( $r, 10, 900 ) },
    n4   => sub { $self->_int( $r, 100, 9800 ) },
    n5   => sub { $self->_int( $r, 10000, 99999 ) },
    n6   => sub { $self->_int( $r, 100000, 999999 ) },
    ms   => sub { $self->_int( $r, 2, 480 ) },
    hex8 => sub { $self->_hex( $r, 8 ) },
    mand => sub { $self->_pick( $r, \@MAND ) },
    db   => sub { $self->_pick( $r, \@DBHOST ) },
    queue => sub { $self->_pick( $r, \@QUEUE ) },
    task => sub { $self->_pick( $r, \@TASK ) },
    lock => sub { $self->_pick( $r, \@LOCK ) },
    pfad => sub { $self->_pick( $r, \@PFAD ) },
    hh   => sub { sprintf '%02d', $self->_int( $r, 0, 23 ) },
    mm   => sub { sprintf '%02d', $self->_int( $r, 0, 59 ) },
  );
  $t =~ s/<(\w+)>/$v{$1} ? $v{$1}->() : '<'.$1.'>'/ge;
  return $t;
}

# system line (English, as Debian writes it): ( prog, pid, text )
sub _sys_line {
  my ( $self, $r, $host ) = @_;
  my $x = $r->() % 10;
  if ( $x < 4 ) {
    my $svc = $self->_pick( $r, [ sort keys %SYSUNIT ] );
    my $t = $self->_pick( $r, \@SYSTEMD );
    $t =~ s/<svc>/$svc/g;
    $t =~ s/<desc>/$SYSUNIT{$svc}/g;
    $t =~ s/<n1>/$self->_int( $r, 0, 3 )/ge;
    $t =~ s/<n3>/sprintf '%03d', $self->_int( $r, 0, 999 )/ge;
    return ( 'systemd', 1, $t );
  }
  if ( $x < 7 ) {
    return ( 'CRON', $self->_int( $r, 20000, 60000 ), $self->_pick( $r, [
      'pam_unix(cron:session): session opened for user root(uid=0) by (uid=0)',
      '(root) CMD (command -v debian-sa1 > /dev/null && debian-sa1 1 1)',
      'pam_unix(cron:session): session closed for user root',
    ] ) );
  }
  if ( $x < 9 ) {
    my $ip = '10.20.0.'.$self->_int( $r, 5, 9 );
    return ( 'sshd', $self->_int( $r, 20000, 60000 ), $self->_pick( $r, [
      'Accepted publickey for deploy from '.$ip.' port '.$self->_int( $r, 32768, 60999 ).' ssh2: ED25519 SHA256:'.$self->_hex( $r, 16 ),
      'pam_unix(sshd:session): session opened for user deploy(uid=1100) by (uid=0)',
      'pam_unix(sshd:session): session closed for user deploy',
    ] ) );
  }
  return ( 'systemd-timesyncd', $self->_int( $r, 400, 900 ), 'Initial synchronization to time server 10.20.0.1:123 (ntp1.example.invalid).' )
    if $r->() % 2;
  return ( 'kernel', undef, 'nft-drop: IN=eth0 OUT= SRC=192.0.2.'.$self->_int( $r, 2, 250 ).' DST=10.20.0.'.$self->_int( $r, 10, 90 )
    .' PROTO=TCP SPT='.$self->_int( $r, 1024, 65000 ).' DPT='.$self->_pick( $r, [ 23, 445, 3389, 5900 ] ) );
}

# PID per host and service, fixed for the whole text
sub _pids {
  my ( $self, $r, $hosts, $units ) = @_;
  my %p;
  for my $h (@$hosts) { $p{ $h.'/'.$_ } = $self->_int( $r, 900, 4800 ) for @$units }
  return \%p;
}

sub _log_line {
  my ( $self, $r, $o, $host ) = @_;
  my ( $prog, $pid, $text );
  if ( $r->() % 100 < 82 ) {
    $prog = $self->_pick( $r, $o->{units} );
    $pid  = $o->{_pids}{ $host.'/'.$prog };
    $text = $self->_fill_app( $r, $self->_pick( $r, \@APP ) );
  }
  else { ( $prog, $pid, $text ) = $self->_sys_line( $r, $host ) }
  return "\0 ".$host.' '.( defined $pid ? $prog.'['.$pid.']' : $prog ).': '.$text;
}

my @UA = (
  'Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
  'lagerscanner/4.2 (Android 14)',
  'kassensystem/2.8.1',
);
my @SUCHE = qw( schrauben duebel winkel kabelbinder spannband palette regal kiste etikett klebeband );

sub _nginx_line {
  my ( $self, $r, $o ) = @_;
  my $ip = $r->() % 3
    ? '10.20.'.$self->_int( $r, 4, 7 ).'.'.$self->_int( $r, 2, 254 )
    : $self->_pick( $r, [ '192.0.2.', '198.51.100.', '203.0.113.' ] ).$self->_int( $r, 2, 254 );
  my $x = $r->() % 100;
  my ( $req, $up, $st, $bytes, $ref );
  if ( $x < 22 ) {
    $req = 'GET /static/'.$self->_pick( $r, [
      'css/haupt.'.$self->_hex( $r, 8 ).'.css',
      'js/app.'.$self->_hex( $r, 8 ).'.js',
      'img/logo.svg',
      'img/artikel/'.$self->_int( $r, 1000, 9999 ).'.webp',
    ] );
    ( $up, $st ) = ( '-', $r->() % 4 ? 200 : 304 );
    $bytes = $st == 304 ? 0 : $self->_int( $r, 800, 90000 );
  }
  else {
    my $m = $r->() % 6 ? 'GET' : 'POST';
    my $p = $m eq 'POST'
      ? $self->_pick( $r, [ '/api/warenkorb', '/api/bestellung', '/konto/anmelden', '/api/lager/reservierung' ] )
      : $self->_pick( $r, [
        '/',
        '/artikel/'.$self->_int( $r, 10000, 99999 ),
        '/api/artikel/'.$self->_int( $r, 10000, 99999 ),
        '/suche?q='.$self->_pick( $r, \@SUCHE ),
        '/konto/bestellungen',
        '/api/lager/'.$self->_int( $r, 100, 999 ).'/bestand',
        '/kategorie/'.$self->_pick( $r, \@SUCHE ),
      ] );
    $req = $m.' '.$p;
    my $y = $r->() % 1000;
    $st = $y < 900 ? 200 : $y < 940 ? ( $m eq 'POST' ? 201 : 304 ) : $y < 975 ? 404 : $y < 990 ? 301 : $y < 997 ? 499 : 403;
    $up = $self->_pick( $r, $o->{upstreams} );
    $bytes = $st == 304 || $st == 499 ? 0 : $self->_int( $r, 180, 48000 );
  }
  $ref = $r->() % 3 ? '"https://shop.example.invalid/"' : '"-"';
  my $rt = sprintf '%.3f', $self->_int( $r, 1, 900 ) / 1000;
  my $us = $up eq '-' ? '-' : $st;
  return $ip.' - - ['."\0".'] "'.$req.' HTTP/1.1" '.$st.' '.$bytes.' '.$ref.' "'.$self->_pick( $r, \@UA )
    .'" rt='.$rt.' ua="'.$up.'" us="'.$us.'"';
}

my @PGUSER = qw( shop bericht lager replikator );

sub _pg_line {
  my ( $self, $r, $o ) = @_;
  my $pid  = $self->_int( $r, 10000, 99999 );
  my $u    = $self->_pick( $r, \@PGUSER );
  my $db   = $o->{database};
  my $ip   = '10.20.1.'.$self->_int( $r, 10, 60 );
  my $port = $self->_int( $r, 32768, 60999 );
  my $x    = $r->() % 100;
  my $pre  = "\0 [".$pid.'] ';
  my $who  = $u.'@'.$db;
  return $pre.'LOG:  Verbindung empfangen: Host='.$ip.' Port='.$port if $x < 18;
  return $pre.$who.' LOG:  Verbindung autorisiert: Benutzer='.$u.' Datenbank='.$db.' Anwendungsname='
    .$self->_pick( $r, [ 'shop-web', 'lagerdienst', 'berichte', 'psql' ] ) if $x < 36;
  return $pre.$who.' LOG:  Verbindungsende: Sitzungszeit: 0:00:'.sprintf( '%02d.%03d', $self->_int( $r, 0, 59 ), $self->_int( $r, 0, 999 ) )
    .' Benutzer='.$u.' Datenbank='.$db.' Host='.$ip.' Port='.$port if $x < 52;
  my $tab = $self->_pick( $r, \@TAB );
  if ( $x < 76 ) {
    my $q = $self->_pick( $r, [
      'SELECT * FROM '.$tab.' WHERE id = '.$self->_int( $r, 1000, 999999 ),
      'SELECT count(*) FROM '.$tab." WHERE erstellt_am > now() - interval '1 day'",
      'UPDATE '.$tab.' SET geaendert_am = now() WHERE id = '.$self->_int( $r, 1000, 999999 ),
      'SELECT a.id, a.bezeichnung, l.menge FROM artikel a JOIN lagerbestand l ON l.artikel_id = a.id WHERE l.lager = '.$self->_int( $r, 1, 12 ),
    ] );
    return $pre.$who.' LOG:  Dauer: '.$self->_int( $r, 250, 4800 ).'.'.sprintf( '%03d', $self->_int( $r, 0, 999 ) ).' ms  Anweisung: '.$q;
  }
  return $pre.'LOG:  Checkpoint beginnt: time' if $x < 82;
  return $pre.'LOG:  Checkpoint komplett: '.$self->_int( $r, 100, 9000 ).' Puffer geschrieben ('.$self->_int( $r, 0, 9 ).','.$self->_int( $r, 0, 9 )
    .'%); 0 WAL-Datei(en) hinzugefügt, 0 entfernt, '.$self->_int( $r, 1, 9 ).' wiederverwendet; Schreiben='.$self->_int( $r, 10, 269 ).','.$self->_int( $r, 100, 999 )
    .' s, Sync=0,0'.$self->_int( $r, 10, 99 ).' s, gesamt='.$self->_int( $r, 10, 270 ).','.$self->_int( $r, 100, 999 ).' s' if $x < 88;
  return $pre.'LOG:  automatisches Vacuum der Tabelle »'.$db.'.public.'.$tab.'«: Index-Scans: 1' if $x < 93;
  return $pre.'LOG:  automatisches Analyze der Tabelle »'.$db.'.public.'.$tab.'«' if $x < 97;
  return $pre.$who.' LOG:  temporäre Datei: Pfad »base/pgsql_tmp/pgsql_tmp'.$pid.'.'.$self->_int( $r, 0, 40 ).'«, Größe '.$self->_int( $r, 100000, 90000000 );
}

my @INI_SEC = ( 'zone_lager', 'export_kanal', 'drucker', 'schnittstelle_erp', 'scanner_station', 'versandart', 'mandant', 'etikett_vorlage' );
my @INI_COMMENT = (
  '# Zone <n2>: Hochregallager, Gang <n1> bis <n2>',
  '# geändert für die Inventur — nicht ohne Rücksprache mit der Logistik zurücksetzen',
  '# Wert in Sekunden',
  '# Ansprechpartner: Team Lager (lager-<n2>@example.invalid)',
  '# gilt nur für den Standort <mand>',
  '# Übergangsweise bis zur Umstellung auf das neue Etikettenformat',
  '# Grenzwerte abgestimmt mit der Fachabteilung',
  '# leer lassen = Vorgabe des Programms',
);
# [ key, value ], the value drawn by $value->( $self, $r )
my @INI_KEY = (
  [ aktiv           => sub { $_[0]->_pick( $_[1], [qw( ja ja ja nein )] ) } ],
  [ intervall_s     => sub { $_[0]->_pick( $_[1], [ 15, 30, 60, 120, 300, 900 ] ) } ],
  [ ziel            => sub { 'sftp://ablage.example.invalid/'.$_[0]->_pick( $_[1], \@PFAD ).'/' } ],
  [ wiederholungen  => sub { $_[0]->_int( $_[1], 1, 8 ) } ],
  [ protokoll_stufe => sub { $_[0]->_pick( $_[1], [qw( info info warnung fehler )] ) } ],
  [ zeitzone        => sub { 'Europe/Berlin' } ],
  [ zeichensatz     => sub { $_[0]->_pick( $_[1], [qw( UTF-8 UTF-8 ISO-8859-15 )] ) } ],
  [ puffer_kb       => sub { $_[0]->_pick( $_[1], [ 64, 128, 256, 512 ] ) } ],
  [ beschreibung    => sub { $_[0]->_pick( $_[1], [
    'Wareneingang Halle '.$_[0]->_int( $_[1], 1, 6 ),
    'Kommissionierung Süd',
    'Rückläufer und Retouren',
    'Versand Paketdienst',
    'Sperrlager (Qualitätsprüfung)',
    'Kühlbereich Tor '.$_[0]->_int( $_[1], 1, 9 ),
  ] ) } ],
  [ freigabe_gruppe => sub { $_[0]->_pick( $_[1], [qw( lager-leitung schichtfuehrung versand qs )] ) } ],
  [ drucker         => sub { 'drucker-'.$_[0]->_int( $_[1], 2, 60 ).'.example.invalid' } ],
  [ format          => sub { $_[0]->_pick( $_[1], [qw( csv json edifact xml )] ) } ],
  [ max_positionen  => sub { $_[0]->_pick( $_[1], [ 50, 100, 250, 999 ] ) } ],
  [ sperrzeit_min   => sub { $_[0]->_int( $_[1], 1, 90 ) } ],
  [ standort        => sub { $_[0]->_pick( $_[1], \@MAND ) } ],
);

sub _ini_block {
  my ( $self, $r, $o, $n ) = @_;
  my @l;
  push @l, $self->_fill_app( $r, $self->_pick( $r, \@INI_COMMENT ) ) if $r->() % 3 == 0;
  push @l, '['.$self->_pick( $r, \@INI_SEC ).'_'.$n.']';
  my %seen;
  for ( 1 .. $self->_int( $r, 3, 8 ) ) {
    my $k = $self->_pick( $r, \@INI_KEY );
    next if $seen{ $k->[0] }++;
    push @l, $self->_fill_app( $r, $self->_pick( $r, \@INI_COMMENT ) ) if $r->() % 7 == 0;
    push @l, $k->[0].' = '.$k->[1]->( $self, $r );
  }
  return join "\n", @l;
}

#### Kubernetes manifests

my @K8S_A = qw( artikel auftrag bestand beleg druck etikett faktura inventur kasse katalog kunden lager liefer
  mahn pack preis rabatt reklamation scan schicht spedition tarif touren versand waren zoll );
my @K8S_B = qw( api dienst export gateway import index planer portal pruefer rechner sammler sync worker abgleich );
my @K8S_TEAM = qw( lager versand kasse einkauf plattform finanzen );
my @K8S_ENV = (
  [ PROTOKOLL_STUFE => sub { $_[0]->_pick( $_[1], [qw( info info warnung )] ) } ],
  [ DB_POOL_MAX     => sub { $_[0]->_pick( $_[1], [ 10, 20, 40 ] ) } ],
  [ WARTESCHLANGE   => sub { 'amqp://mq'.$_[0]->_int( $_[1], 1, 3 ).'.example.invalid:5672/'.$_[0]->_pick( $_[1], \@QUEUE ) } ],
  [ ZEITZONE        => sub { 'Europe/Berlin' } ],
  [ CACHE_TTL_S     => sub { $_[0]->_pick( $_[1], [ 30, 60, 300 ] ) } ],
);

sub _k8s_block {
  my ( $self, $r, $o, $n ) = @_;
  my $name;
  for ( 1 .. 50 ) {
    $name = $self->_pick( $r, \@K8S_A ).'-'.$self->_pick( $r, \@K8S_B );
    last unless $o->{_names}{$name};
  }
  $name .= '-'.$n if $o->{_names}{$name};
  $o->{_names}{$name} = 1;
  my $ns    = $o->{namespace};
  my $team  = $self->_pick( $r, \@K8S_TEAM );
  my $port  = $self->_pick( $r, [ 8080, 8080, 8000, 8081, 9000, 3000 ] );
  my $named = $r->() % 3 == 0;
  my $ver   = join '.', $self->_int( $r, 1, 4 ), $self->_int( $r, 0, 19 ), $self->_int( $r, 0, 30 );
  my @env   = grep { $r->() % 2 } @K8S_ENV;
  my @docs;
  push @docs, join "\n", '# Quelle: apps/'.$name.'/configmap.yaml', 'apiVersion: v1', 'kind: ConfigMap', 'metadata:',
    '  name: '.$name.'-einstellungen', '  namespace: '.$ns, 'data:',
    map { '  '.$_->[0].': "'.$_->[1]->( $self, $r ).'"' } grep { $r->() % 2 } @K8S_ENV
    if $r->() % 4 == 0;
  push @docs, join "\n", '# Quelle: apps/'.$name.'/deployment.yaml', 'apiVersion: apps/v1', 'kind: Deployment', 'metadata:',
    '  name: '.$name, '  namespace: '.$ns, '  labels:', '    app: '.$name, '    team: '.$team, 'spec:',
    '  replicas: '.$self->_int( $r, 1, 6 ), '  selector:', '    matchLabels:', '      app: '.$name, '  template:', '    metadata:',
    '      labels:', '        app: '.$name, '        team: '.$team, '    spec:', '      containers:', '        - name: '.$name,
    '          image: registry.example.invalid/'.$team.'/'.$name.':'.$ver, '          ports:', '            - name: http',
    '              containerPort: '.$port,
    ( @env ? ( '          env:', map { ( '            - name: '.$_->[0], '              value: "'.$_->[1]->( $self, $r ).'"' ) } @env ) : () ),
    '          resources:', '            requests:', '              cpu: '.$self->_pick( $r, [qw( 50m 100m 250m 500m )] ),
    '              memory: '.$self->_pick( $r, [qw( 128Mi 256Mi 512Mi )] ), '            limits:',
    '              memory: '.$self->_pick( $r, [qw( 512Mi 1Gi )] ), '          readinessProbe:', '            httpGet:',
    '              path: /bereit', '              port: http';
  push @docs, join "\n", '# Quelle: apps/'.$name.'/service.yaml', 'apiVersion: v1', 'kind: Service', 'metadata:',
    '  name: '.$name, '  namespace: '.$ns, 'spec:', '  selector:', '    app: '.$name, '  ports:', '    - name: http',
    '      port: 80', '      targetPort: '.( $named ? 'http' : $port );
  return join "\n---\n", @docs;
}

#### Runbooks

my @RB_SVC = qw( lagerdienst belegimport lieferschein rechnungsversand mahnlauf kundenportal-api versand-gateway
  etikettendruck scanner-hub preisdienst );
my @RB_HOST = qw( app3 app5 app7 lb2 mq1 mq2 db2 db3 druck1 ftp2 );
my @RB_TOPIC = (
  'Dienst nach Wartung wieder anfahren', 'Warteschlange leeren', 'Zertifikat erneuern', 'Platte erweitern',
  'Replikat neu aufsetzen', 'Protokollstufe vorübergehend erhöhen', 'Verbindungspool anpassen', 'Sicherung prüfen',
  'Benutzerkonto sperren', 'Logrotation anpassen', 'Zeitplan verschieben', 'Drucker-Warteschlange zurücksetzen',
);
my @RB_ANLASS = (
  'Der Dienst meldet nach dem nächtlichen Wartungsfenster keine Gesundheitsprüfung.',
  'Die Überwachung meldet einen Rückstau von mehr als <n4> Nachrichten.',
  'Das Zertifikat läuft in weniger als <n2> Tagen ab.',
  'Die Fachabteilung braucht für <n2> Tage ausführlichere Protokolle.',
  'Der Verbindungspool ist zu Lastspitzen erschöpft.',
  'Planmäßige Prüfung, einmal im Monat.',
  'Ein Mitarbeiter hat das Unternehmen verlassen.',
);
my @RB_STEP = (
  'Auf <host> mit `systemctl status <svc>` prüfen, ob der Dienst läuft.',
  'Mit `journalctl -u <svc> -n 200` die letzten Meldungen ansehen.',
  'In /etc/<svc>/<svc>.conf den Wert `<key> = <val>` setzen.',
  'Danach `systemctl reload <svc>` — der Dienst liest die Datei neu, laufende Aufträge bleiben.',
  'Danach `systemctl restart <svc>` (nur außerhalb der Kernzeit, 07:00–19:00).',
  'Im Ticket vermerken, wer was wann geändert hat.',
  'Mit `curl -s http://127.0.0.1:<port>/bereit` die Bereitschaft prüfen; erwartet wird `ok`.',
  'Wenn der Rückstau nach <n2> Minuten nicht sinkt: Bereitschaft Team <team> anrufen.',
  'Die Änderung nach <n2> Tagen wieder zurücknehmen (Erinnerung im Kalender anlegen).',
  'Freien Platz mit `df -h /srv` prüfen; unter <n2> % frei nicht fortfahren.',
);
my @RB_NOTE = (
  'Ältere Fassungen dieser Seite gelten nicht mehr; maßgeblich ist das Stand-Datum.',
  'Bei Unklarheiten nicht raten, sondern die Bereitschaft fragen.',
  'Änderungen an Konfigurationen gehen danach als Merge-Request ins Konfigurations-Repository.',
  'Gilt sinngemäß auch für die Testumgebung.',
);
my @RB_KEY = (
  [ protokoll_stufe  => sub { $_[0]->_pick( $_[1], [qw( info debug warnung )] ) } ],
  [ max_verbindungen => sub { $_[0]->_pick( $_[1], [ 16, 32, 64, 128 ] ) } ],
  [ wiederholungen   => sub { $_[0]->_int( $_[1], 1, 8 ) } ],
  [ zeitfenster      => sub { sprintf '%02d:00-%02d:00', $_[0]->_int( $_[1], 0, 5 ), $_[0]->_int( $_[1], 6, 9 ) } ],
  [ puffer_kb        => sub { $_[0]->_pick( $_[1], [ 128, 256, 512 ] ) } ],
);

sub _runbook_block {
  my ( $self, $r, $o, $n ) = @_;
  my $svc   = $self->_pick( $r, \@RB_SVC );
  my $host  = $self->_pick( $r, \@RB_HOST );
  my $team  = $self->_pick( $r, \@K8S_TEAM );
  my $date  = sprintf '%04d-%02d-%02d', $self->_int( $r, 2023, 2026 ), $self->_int( $r, 1, 12 ), $self->_int( $r, 1, 28 );
  my $topic = $self->_pick( $r, \@RB_TOPIC );
  my $fill  = sub {
    my ($t) = @_;
    my $k = $self->_pick( $r, \@RB_KEY );
    $t =~ s/<svc>/$svc/g;
    $t =~ s/<host>/$host/g;
    $t =~ s/<team>/$team/g;
    $t =~ s/<key>/$k->[0]/g;
    $t =~ s/<val>/$k->[1]->( $self, $r )/ge;
    $t =~ s/<port>/$self->_pick( $r, [ 8080, 8081, 9000 ] )/ge;
    return $self->_fill_app( $r, $t );
  };
  # sequence: check, maybe change and apply, check again, record (no duplicates)
  my @steps = ( $fill->( $RB_STEP[ $self->_int( $r, 0, 1 ) ] ) );
  if ( $r->() % 4 ) {
    push @steps, $fill->( $RB_STEP[2] ), $fill->( $RB_STEP[ 3 + $r->() % 2 ] );
  }
  my %seen = map { $_ => 1 } @steps;
  for my $x ( map { $RB_STEP[$_] } grep { $r->() % 3 == 0 } 6 .. $#RB_STEP ) {
    my $t = $fill->($x);
    push @steps, $t unless $seen{$t}++;
  }
  push @steps, $fill->( $RB_STEP[5] );
  my $i = 0;
  return join "\n", '## Runbook: '.$svc.' — '.$topic, '',
    'Seite '.$n.' · Stand: '.$date.' · Verantwortlich: Team '.$team.' · Gilt für: '.$host, '',
    'Anlass: '.$self->_fill_app( $r, $self->_pick( $r, \@RB_ANLASS ) ), '',
    ( map { ++$i.'. '.$_ } @steps ),
    ( $r->() % 3 == 0 ? ( '', 'Hinweis: '.$self->_pick( $r, \@RB_NOTE ) ) : () );
}

#### Checking the spec

sub _check {
  my ( $self, $s, $f ) = @_;
  $self->_refuse( $f, 'spec (hash) expected' ) unless ref $s eq 'HASH';
  my %ok = map { $_ => 1 } @KEYS;
  $ok{$_} or $self->_refuse( $f.'.'.$_, 'unknown key ('.join( ', ', @KEYS ).')' ) for sort keys %$s;
  my $kind = $s->{kind} // '';
  $self->_refuse( $f.'.kind', 'kind must be one of '.join( ', ', @KINDS ) ) unless !ref $kind && grep { $kind eq $_ } @KINDS;
  my $num = sub {
    my ( $k, $min, $max, $def ) = @_;
    my $v = $s->{$k} // $def;
    $self->_refuse( $f.'.'.$k, 'number '.$min.'..'.$max )
      if !defined $v || ref $v || $v !~ /\A\d+(?:\.\d+)?\z/ || $v < $min || $v > $max;
    return 0 + $v;
  };
  my %o = ( kind => $kind );
  $o{tokens} = int $num->( 'tokens', 1000, 200_000 );
  $o{seed}   = int $num->( 'seed', 0, 2**31, 1 );
  $o{hours}  = $num->( 'hours', 0.5, 72, 8 );
  my $start = $s->{start} // '2026-10-28 22:00:00';
  my @t = !ref $start ? $start =~ /\A(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d):(\d\d)\z/ : ();
  $self->_refuse( $f.'.start', 'time like "2026-10-28 22:00:00"' ) unless @t;
  $o{start} = eval { Time::Local::timegm( $t[5], $t[4], $t[3], $t[2], $t[1] - 1, $t[0] ) }
    // $self->_refuse( $f.'.start', 'not a valid time' );
  $o{tz} = $s->{tz} // 'CET';
  $self->_refuse( $f.'.tz', 'CET or CEST' ) unless !ref $o{tz} && $o{tz} =~ /\ACES?T\z/;
  my $names = sub {
    my ( $k, $def, $re ) = @_;
    my $v = $s->{$k} // $def;
    $self->_refuse( $f.'.'.$k, 'list of names' ) unless ref $v eq 'ARRAY' && @$v && !grep { !defined || ref || !/$re/ } @$v;
    return [ map { "$_" } @$v ];
  };
  my $name = qr/\A[a-z0-9][a-z0-9.@-]{0,62}\z/;
  my $title = $kind eq 'k8s-manifests' ? 'release' : $kind eq 'runbooks' ? 'Betriebshandbuch' : 'lager.ini';
  my %one = (
    host      => [ 'srv1', $name ],
    database  => [ 'shop', $name ],
    namespace => [ 'shop', $name ],
    title     => [ $title, qr/\A[^\n]{1,80}\z/ ],
  );
  for my $k ( sort keys %one ) {
    my $v = $s->{$k} // $one{$k}[0];
    $self->_refuse( $f.'.'.$k, 'name' ) if ref $v || $v !~ $one{$k}[1];
    $o{$k} = "$v";
  }
  $o{hosts}     = $names->( 'hosts', [qw( web1 web2 web3 )], $name );
  $o{units}     = $names->( 'units', \@UNITS, $name );
  $o{upstreams} = $names->( 'upstreams', [ map { '10.20.2.'.$_.':8080' } 11 .. 14 ], qr/\A[a-z0-9.:-]+\z/ );

  my $ex = $s->{exclude} // [];
  $self->_refuse( $f.'.exclude', 'list of patterns' ) unless ref $ex eq 'ARRAY';
  $o{exclude} = [ map {
    my $x = $ex->[$_];
    $self->_refuse( $f.'.exclude['.$_.']', 'pattern (text)' ) if !defined $x || ref $x || !length $x;
    my $re = eval { qr/$x/m } or $self->_refuse( $f.'.exclude['.$_.']', 'invalid regular expression' );
    $re;
  } 0 .. $#$ex ];

  my $in = $s->{insert} // [];
  $self->_refuse( $f.'.insert', 'list' ) unless ref $in eq 'ARRAY';
  $self->_refuse( $f.'.exclude', 'inserts need exclude (the needle patterns the filler must never contain)' )
    if @$in && !@$ex;
  my @ins;
  for my $i ( 0 .. $#$in ) {
    my ( $x, $xf ) = ( $in->[$i], $f.'.insert['.$i.']' );
    $self->_refuse( $xf, 'hash expected' ) unless ref $x eq 'HASH';
    my %k = map { $_ => 1 } exists $x->{at} ? qw( at text ) : qw( from to count text );
    $k{$_} or $self->_refuse( $xf.'.'.$_, 'unknown key (at, text or from, to, count, text)' ) for sort keys %$x;
    $self->_refuse( $xf.'.text', 'text missing' ) if !defined $x->{text} || ref $x->{text} || !length $x->{text};
    my $frac = sub {
      my ($k) = @_;
      my $v = $x->{$k};
      $self->_refuse( $xf.'.'.$k, 'number 0..1' ) if !defined $v || ref $v || $v !~ /\A\d*\.?\d+\z/ || $v > 1;
      return 0 + $v;
    };
    if ( exists $x->{at} ) { push @ins, { at => $frac->('at'), text => "$x->{text}", n => $i } }
    else {
      my ( $from, $to ) = ( $frac->('from'), $frac->('to') );
      $self->_refuse( $xf.'.to', 'must lie after from' ) unless $to > $from;
      my $c = $x->{count};
      $self->_refuse( $xf.'.count', 'integer 1..500' ) if !defined $c || ref $c || $c !~ /\A\d+\z/ || $c < 1 || $c > 500;
      push @ins, map { { at => $from + ( $to - $from ) * ( $_ + 0.5 ) / $c, text => "$x->{text}", n => $i } } 0 .. $c - 1;
    }
  }
  $o{insert} = \@ins;
  return \%o;
}

#### Generating

sub generate {
  my ( $self, $spec, $f ) = @_;
  $f //= 'generate';
  my $key = eval { $self->_json->encode($spec) };
  my $cache = $self->_cache;
  return $cache->{$key} if defined $key && exists $cache->{$key};
  my $text = $self->_build( $self->_check( $spec, $f ), $f );
  $cache->{$key} = $text if defined $key;
  return $text;
}


sub _build {
  my ( $self, $o, $f ) = @_;
  my $r      = $self->_rng( $o->{seed} );
  my $kind   = $o->{kind};
  my $target = $o->{tokens} * $self->chars_per_token;
  my @hosts  = $kind eq 'journal' ? ( $o->{host} ) : @{ $o->{hosts} };
  $o->{_pids} = $self->_pids( $r, [ @hosts, $o->{host} ], $o->{units} );
  my $tslen = $LOG{$kind} ? length $self->_ts( $kind, $o->{start}, 0, $o->{tz} ) : 0;

  # filler: templates (line or block) up to the target size, excluded ones drawn again
  my ( @fill, $len );
  my $head = '';
  if ( $kind eq 'ini-config' ) {
    $head = '# '.$o->{title}." — Hauptkonfiguration\n# Verwaltet im Konfigurations-Repository; Änderungen nur mit Ticket.\n"
      .'# Abschnitte dürfen mehrfach vorkommen; bei doppeltem Schlüssel gilt die letzte Zuweisung.';
  }
  elsif ( $kind eq 'k8s-manifests' ) {
    $head = '# Gerendertes Bündel '.$o->{title}.' (Namespace '.$o->{namespace}."), erzeugt von der CI aus apps/*/\n"
      .'# Reihenfolge wie im Repository; kommt ein Objekt mehrfach vor, gilt das letzte (wie bei kubectl apply).';
  }
  elsif ( $kind eq 'runbooks' ) {
    $head = '# '.$o->{title}." — Export aus dem Wiki (Bereich Betrieb)\n\n"
      .'Jedes Runbook trägt sein Stand-Datum. Der Export ist nach Seiten-ID sortiert, nicht nach Datum.';
  }
  my $sep = $SEP{$kind} // "\n";
  $len = length $head;
  my $n = 0;
  while ( $len < $target ) {
    my $t;
    for my $try ( 1 .. 200 ) {
      $t = $kind eq 'journal'         ? $self->_log_line( $r, $o, $o->{host} )
        : $kind eq 'syslog'           ? $self->_log_line( $r, $o, $self->_pick( $r, \@hosts ) )
        : $kind eq 'nginx-access'     ? $self->_nginx_line( $r, $o )
        : $kind eq 'postgres-log'     ? $self->_pg_line( $r, $o )
        : $kind eq 'k8s-manifests'    ? $self->_k8s_block( $r, $o, ++$n )
        : $kind eq 'runbooks'         ? $self->_runbook_block( $r, $o, ++$n )
        :                               $self->_ini_block( $r, $o, ++$n );
      last unless grep { ( $t =~ s/\0//r ) =~ $_ } @{ $o->{exclude} };
      $t = undef;
    }
    $self->_refuse( $f.'.exclude', 'excludes almost all of the filler' ) unless defined $t;
    push @fill, [ $t, $r->() % 1_000_000 ];
    $len += length($t) + ( $t =~ /\0/ ? $tslen - 1 : 0 ) + length $sep;
  }
  # large blocks (manifests, runbooks): drop the last one when the size without it is closer to the target
  if ( $kind eq 'k8s-manifests' || $kind eq 'runbooks' ) {
    my $last = length( $fill[-1][0] ) + length $sep;
    if ( @fill > 1 && $len - $target > $target - ( $len - $last ) ) {
      pop @fill;
      $len -= $last;
    }
  }

  # time: even over hours, monotonic
  my $span = $o->{hours} * 3600;
  my $N = @fill;
  my @ts;
  for my $i ( 0 .. $N - 1 ) {
    my $u = ( $r->() % 1000 ) / 1000;
    push @ts, [ $o->{start} + int( $span * ( $i + $u ) / $N ), $fill[$i][1] ];
  }
  my $stamp = sub {
    my ($i) = @_;
    $i = $N - 1 if $i >= $N;
    return $LOG{$kind} ? $self->_ts( $kind, @{ $ts[$i] }, $o->{tz} ) : '';
  };
  my @out = map { $fill[$_][0] =~ s/\0/$stamp->($_)/er } 0 .. $N - 1;

  # the filler gives nothing away — not through its timestamps either
  my $plain = join $sep, ( length $head ? $head : () ), @out;
  for my $j ( 0 .. $#{ $o->{exclude} } ) {
    $self->_refuse( $f.'.exclude['.$j.']', 'matches the filler (its timestamps, say) — make the pattern tighter' )
      if $plain =~ $o->{exclude}[$j];
  }
  return $plain."\n" unless @{ $o->{insert} };

  # inserts go before the line at their position, with its timestamp
  my $ri = $self->_rng( $o->{seed} + 7919 );
  my %at;
  for my $x ( @{ $o->{insert} } ) {
    my $i = int( $x->{at} * $N + 0.5 );
    my $t = $x->{text};
    $t =~ s/\n+\z//;
    my $ts = $stamp->($i);
    my $ph = sub {
      my ( $w, $unit ) = @_;
      return $ts if $w eq 'ts';
      return $o->{host} if $w eq 'host';
      return $self->_int( $ri, 1000, 99999 ) if $w eq 'num';
      return '10.20.'.$self->_int( $ri, 4, 7 ).'.'.$self->_int( $ri, 2, 254 ) if $w eq 'ip';
      return $self->_int( $ri, 3, 900 ) if $w eq 'ms';
      return $self->_int( $ri, 32768, 60999 ) if $w eq 'port';
      my $k = $unit =~ m{/} ? $unit : $o->{host}.'/'.$unit;
      return $o->{_pids}{$k}
        // $self->_refuse( $f.'.insert['.$x->{n}.'].text', '{pid:'.$unit.'}: no service of that name (units, host/hosts)' );
    };
    $t =~ s/\{(ts|host|num|ip|ms|port|pid:([^\}]+))\}/my ( $w, $u ) = ( $1, $2 ); $ph->( $w =~ s{:.*}{}sr, $u )/ge;
    push @{ $at{$i} }, $t;
  }
  for my $j ( 0 .. $#{ $o->{exclude} } ) {
    my $re = $o->{exclude}[$j];
    $self->_refuse( $f.'.exclude['.$j.']', 'matches no insert — the needle would not stand where the case puts it' )
      unless grep { $_ =~ $re } map { @{ $at{$_} } } sort { $a <=> $b } keys %at;
  }
  my @all;
  for my $i ( 0 .. $N ) {
    push @all, @{ $at{$i} } if $at{$i};
    push @all, $out[$i] if $i < $N;
  }
  return join( $sep, ( length $head ? $head : () ), @all )."\n";
}

sub resolve {
  my ( $self, $v, $f ) = @_;
  if ( ref $v eq 'HASH' ) {
    $self->_refuse( $f, 'only generate: { ... } (or text, or a list of parts)' ) unless exists $v->{generate} && keys %$v == 1;
    return $self->generate( $v->{generate}, $f.'.generate' );
  }
  return $v unless ref $v eq 'ARRAY';
  $self->_refuse( $f, 'empty list' ) unless @$v;
  return join '', map {
    my $p = $v->[$_];
    ref $p eq 'HASH' ? $self->resolve( $p, $f.'['.$_.']' )
      : !defined $p || ref $p ? $self->_refuse( $f.'['.$_.']', 'part: text or generate: { ... }' )
      : "$p";
  } 0 .. $#$v;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Haystack - Long, deterministic operational data for long-context cases, generated from a short spec

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Langertha::Holmgang::Haystack;

  my $haystack = Langertha::Holmgang::Haystack->new;

  my $log = $haystack->generate( {
    kind    => 'journal',            # journal syslog nginx-access postgres-log ini-config k8s-manifests runbooks
    tokens  => 64000,                # size of the filler (estimated)
    seed    => 7,
    host    => 'app7',
    units   => [qw( belegimport lieferschein )],
    exclude => [ 'Zu viele offene Dateien' ],   # never occurs in the filler
    insert  => [
      { at => 0.73, text => '{ts} {host} belegimport[{pid:belegimport}]: FEHLER: Zu viele offene Dateien' },
      { from => 0.5, to => 0.625, count => 6, text => '...' },
    ],
  } );

  # in the loader: a message or file content made of parts
  my $text = $haystack->resolve(
    [ "Hier der Auszug:\n", { generate => { ... } }, "\nBitte ..." ],
    'cases/x.yaml: messages[0].content',
  );

  $haystack->estimate_tokens($text);                          # characters / 3.5
  Langertha::Holmgang::Haystack->estimate_tokens($text);      # same, as a class method

=head1 DESCRIPTION

Long-context cases need excerpts of 16k to 160k tokens; as YAML in a suite
that would be megabytes. Instead a case carries a short spec
C<< { generate => { ... } } >> in a message content or in a file content of
the state, and this module turns it into text.

B<Deterministic:> the same spec gives the same text, byte for byte, on every
perl with 64-bit integers and independent of C<PERL_HASH_SEED> (its own
xorshift32 random source, never C<rand>). The algorithm and its vocabulary
are those of cai-platform's C<CAI::Platform::Eval::Haystack>, and the text is
the same as there, so a case measures the same input on both. When the
generator changes, the text changes — the loader therefore puts the generated
text into the suite digest.

B<Content:> plausible German operational data — messages of invented
services in German, comments in configurations in German, plus the usual
English lines of systemd, cron and sshd. Host and service names are invented,
addresses come from C<10.20.0.0/16> and the documentation networks, names lie
under C<example.invalid>. Time runs evenly from C<start> over C<hours> hours
(line position maps to time of day): an insert at C<at: 0.5> with start 22:00
and 8 hours stands at 02:xx.

B<Size:> estimated with L</chars_per_token> (3.5 characters per token, an
assumption for German log text with numbers and timestamps under common BPE
tokenizers). C<tokens> is the size of the filler; inserts come on top (they
are small), so the filler does not depend on them.

B<The filler gives nothing away:> every line (or block) of the filler that a
pattern from C<exclude> matches is dropped and drawn again; at the end the
whole filler text (with timestamps) is checked once more. With inserts, every
pattern must match at least one of them — so the needle is exactly where the
case puts it.

Results are cached per instance.

=head1 THE SPEC

  kind:      journal | syslog | nginx-access | postgres-log | ini-config
             | k8s-manifests | runbooks   (required)
  tokens:    1000 .. 200000  (required; size of the filler, estimated)
  seed:      integer 0 .. 2**31 (default 1)
  start:     "2026-10-28 22:00:00" (local time, default)   hours: 0.5 .. 72 (default 8)
  tz:        CET | CEST (default CET)
  host:      host of the journal (default srv1)
  hosts:     hosts of a central syslog (default [web1, web2, web3])
  units:     services in journal/syslog (default: six invented ones)
  upstreams: upstream addresses in the nginx log (default 10.20.2.11..14:8080)
  database:  database in the PostgreSQL log (default shop)
  title:     name in the header (ini-config: configuration, k8s-manifests:
             release, runbooks: handbook)
  namespace: namespace of the manifests (k8s-manifests, default shop)
  exclude:   [ regular expression, ... ]  (multi-line, ^/$ per line)
  insert:    [ { at: 0..1, text }, { from, to, count, text }, ... ]

Placeholders in C<text>: C<{ts}> (timestamp in the kind's format at that
position), C<{host}>, C<{pid:service}> or C<{pid:host/service}> (the same PID
as in the filler), C<{num}>, C<{ip}>, C<{ms}>, C<{port}> (random values).
C<from>/C<to>/C<count> spreads C<count> inserts evenly over the range. In
configurations (blocks instead of lines) each insert is a block of its own
between two sections.

B<Blocks:> C<k8s-manifests> is a rendered bundle of Kubernetes manifests (YAML
documents separated by C<--->): per application a Deployment and a Service,
sometimes a ConfigMap — consistent in the filler (selector = labels,
C<targetPort> hits a C<containerPort> or its name), names unique. C<runbooks>
is an export of operations runbooks (Markdown) with title, C<Stand:> date,
occasion and steps for invented services. Inserts are whole documents or
sections.

=head2 chars_per_token

Characters per token for L</estimate_tokens> and the size of the filler.
Default 3.5. A different value gives a different text for the same spec.

=head2 kinds

  my @kinds = Langertha::Holmgang::Haystack->kinds;

The known kinds: C<journal>, C<syslog>, C<nginx-access>, C<postgres-log>,
C<ini-config>, C<k8s-manifests>, C<runbooks>.

=head2 estimate_tokens

  my $n = $haystack->estimate_tokens($text);
  my $n = Langertha::Holmgang::Haystack->estimate_tokens($text);

Estimated tokens of a text: characters divided by L</chars_per_token>,
rounded. As a class method it uses the default 3.5. Undefined text is 0.

=head2 generate

  my $text = $haystack->generate( \%spec, $field );

Returns the text for the spec (see L</THE SPEC>): a character string ending
in a newline. C<$field> (default C<generate>) is the field path a refusal
starts with. Throws a L<Langertha::Holmgang::Error> (as a string
C<< <field>: <reason> >>) when the spec does not hold — unknown key, size outside 1000..200000, an insert without C<exclude>,
a pattern that matches no insert, one that matches the filler (its
timestamps, say), a C<{pid:...}> of a service that does not exist. Cached
per instance.

=head2 resolve

  my $text = $haystack->resolve( $value, $field );

Resolves a content as the loader finds it: a hash C<< { generate => \%spec } >>
becomes the generated text (L</generate>), a list of parts (text or such a
hash) the joined text. Any other value comes back unchanged. Throws a
L<Langertha::Holmgang::Error> (as a string C<< <field>: <reason> >>); the field
of a spec is C<< <field>.generate >>, of a part C<< <field>[<i>] >>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
