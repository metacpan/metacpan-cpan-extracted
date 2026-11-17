package Langertha::Holmgang::Sim::Schichtfehler;
# ABSTRACT: The answer world schichtfehler — a web application from recorded pages: sources, fetches, console, reported findings

use Moose;
use namespace::autoclean;
use utf8;

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.001';


our $MAX_SPAN = 30;

our @SCHICHTEN = qw( php html js json sql http );

our @KATEGORIEN = qw(
  quoting script_ende interpolation ausgabe_vor_json ausgabe_vor_header zahlformat
  doppelt_maskiert doppelte_id ladereihenfolge sql_bindung sql_platzhalter url_kodierung sonstiges
);

# Die Werkzeuge dieser Welt mit ihren Pflichtparametern (fuer den Lader).
our %TOOLS = (
  dateien_auflisten  => [],
  datei_lesen        => ['pfad'],
  seite_abrufen      => ['pfad'],
  browser_konsole    => ['pfad'],
  befund_melden      => [qw( datei zeile_von zeile_bis ursache_schicht symptom_schicht kategorie )],
  kein_fehler_melden => [],
);

#### Plugin contract

sub device_type { 'schichtfehler' }


sub tools { return \%TOOLS }


sub tool {
  my ( $self, $dev, $name, $args, $ctx ) = @_;
  $name //= '';
  my $code = $TOOLS{$name} && $self->can( '_t_'.$name )
    or return ( "Fehler: unbekanntes Werkzeug '".$name."'", 0 );
  return $self->$code( $dev, $args || {} );
}


#### Pfade und Queries (reine Funktionen)

sub norm_path {
  my ( $p ) = @_;
  $p = '' unless defined $p && !ref $p;
  $p =~ s/\A\s+|\s+\z//g;
  my $q = '';
  $q = $1 if $p =~ s/\?(.*)\z//s;
  $p =~ s{\A(?:\./|/)+}{};
  $p =~ s{/\./}{/}g;
  return wantarray ? ( $p, $q ) : $p;
}


sub norm_query {
  my ( $q ) = @_;
  $q = '' unless defined $q && !ref $q;
  $q =~ s/\A\s*\??//;
  $q =~ s/\s+\z//;
  my @pairs;
  for my $part ( split /&/, $q ) {
    next unless length $part;
    my ( $k, $v ) = split /=/, $part, 2;
    $v //= '';
    ( $k, $v ) = map { _unescape($_) } $k, $v;
    push @pairs, [ $k, $v ];
  }
  return join '&', map { _escape( $_->[0] ).'='._escape( $_->[1] ) }
    sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @pairs;
}


sub _unescape {
  my ( $s ) = @_;
  $s =~ tr/+/ /;
  $s =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  utf8::decode($s);
  return $s;
}

sub _escape {
  my ( $s ) = @_;
  my $b = $s;
  utf8::encode($b);
  $b =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge;
  return $b;
}

sub _lines {
  my ( $text ) = @_;
  my @l = split /\n/, $text, -1;
  pop @l if @l && $l[-1] eq '';    # Zeilenende am Schluss ist keine eigene Zeile
  return @l;
}

sub _numbered {
  my ( $lines, $from ) = @_;
  $from //= 1;
  my $w = length( $from + $#$lines );
  $w = 3 if $w < 3;
  return join "\n", map { sprintf( "%*d| %s", $w, $from + $_, $lines->[$_] ) } 0 .. $#$lines;
}

sub _int {
  my ( $v ) = @_;
  return undef unless defined $v && !ref $v && $v =~ /\A\s*(\d+)\s*\z/;
  return 0 + $1;
}

#### Werkzeuge

sub _t_dateien_auflisten {
  my ( $self, $dev ) = @_;
  my $d = $dev->{dateien} || {};
  return ( 'Keine Dateien.', 1 ) unless %$d;
  return ( join( "\n", map { my $n = () = _lines( $d->{$_} ); sprintf '%s  (%d Zeilen)', $_, $n } sort keys %$d ), 1 );
}

sub _t_datei_lesen {
  my ( $self, $dev, $p ) = @_;
  my $path = norm_path( $p->{pfad} );
  my $text = ( $dev->{dateien} || {} )->{$path};
  return ( "Fehler: Datei '".$path."' nicht vorhanden.", 0 ) unless defined $text;
  my @l = _lines($text);
  my $von = exists $p->{von} ? _int( $p->{von} ) : 1;
  my $bis = exists $p->{bis} ? _int( $p->{bis} ) : scalar @l;
  return ( 'Fehler: von und bis sind Zeilennummern ab 1.', 0 ) unless defined $von && defined $bis && $von >= 1;
  return ( '(leere Datei)', 1 ) unless @l;
  return ( 'Fehler: die Datei hat '.scalar(@l).' Zeilen.', 0 ) if $von > @l;
  $bis = @l if $bis > @l;
  return ( 'Fehler: bis liegt vor von.', 0 ) if $bis < $von;
  return ( _numbered( [ @l[ $von - 1 .. $bis - 1 ] ], $von ), 1 );
}

# Aufgezeichneter Abruf/Konsole zu Pfad + Parameter; sonst Text fuer Fehler bzw. Luecke.
sub _recorded {
  my ( $self, $dev, $list, $p ) = @_;
  my ( $path, $inline ) = norm_path( $p->{pfad} );
  my $query = norm_query( join '&', grep { length } $inline,
    ( defined $p->{parameter} && !ref $p->{parameter} ? $p->{parameter} : '' ) );
  my @same = grep { norm_path( $_->{pfad} ) eq $path } @{ $dev->{$list} || [] };
  my ( $hit ) = grep { norm_query( $_->{parameter} ) eq $query } @same;
  return ( $hit, $path, $query, \@same );
}

sub _no_record {
  my ( $self, $dev, $path, $query, $same ) = @_;
  my $exists = exists( ( $dev->{dateien} || {} )->{$path} );
  return ( "HTTP/1.1 404 Not Found\nContent-Type: text/html; charset=UTF-8\n\n"
      ._numbered( [ '<!doctype html><html><head><title>404 Not Found</title></head><body>',
        '<h1>Not Found</h1><p>The requested resource <code>/'.$path.'</code> was not found on this server.</p></body></html>' ] ), 1 )
    unless $exists;
  my @known = map { length( $_->{parameter} // '' ) ? norm_query( $_->{parameter} ) : '(ohne Parameter)' } @$same;
  my $show = $query eq '' ? '(ohne Parameter)' : $query;
  return ( 'Für '.$path.' mit '.$show.' liegt keine Aufzeichnung vor. Aufgezeichnet: '.( @known ? join( ', ', @known ) : 'nichts' ).'.',
    0, 'seite_abrufen/browser_konsole: '.$path.'?'.$query.' nicht aufgezeichnet' );
}

sub _t_seite_abrufen {
  my ( $self, $dev, $p ) = @_;
  my ( $hit, $path, $query, $same ) = $self->_recorded( $dev, abrufe => $p );
  if ( !$hit && $path !~ /\.php\z/ && defined( my $text = ( $dev->{dateien} || {} )->{$path} ) ) {
    # statische Datei: der Server liefert sie, wie sie ist
    my $type = $path =~ /\.css\z/ ? 'text/css' : $path =~ /\.js\z/ ? 'text/javascript' : 'text/plain';
    my @body = _lines($text);
    return ( "HTTP/1.1 200 OK\nContent-Type: ".$type."; charset=UTF-8\n\n".( @body ? _numbered( \@body ) : '(leerer Rumpf)' ), 1 );
  }
  return $self->_no_record( $dev, $path, $query, $same ) unless $hit;
  my @head = ( $hit->{status_zeile} // 'HTTP/1.1 '.( $hit->{status} // '' ), @{ $hit->{kopf} || [] } );
  my @body = _lines( $hit->{rumpf} // '' );
  return ( join( "\n", @head )."\n\n".( @body ? _numbered( \@body ) : '(leerer Rumpf)' ), 1 );
}

sub _t_browser_konsole {
  my ( $self, $dev, $p ) = @_;
  my ( $hit, $path, $query, $same ) = $self->_recorded( $dev, konsole => $p );
  return $self->_no_record( $dev, $path, $query, $same ) unless $hit;
  return ( $hit->{ausgabe}, 1 );
}

sub _t_befund_melden {
  my ( $self, $dev, $p ) = @_;
  my $path = norm_path( $p->{datei} );
  my $text = ( $dev->{dateien} || {} )->{$path};
  return ( "Fehler: Datei '".$path."' nicht vorhanden.", 0 ) unless defined $text;
  my ( $von, $bis ) = map { _int( $p->{$_} ) } qw( zeile_von zeile_bis );
  return ( 'Fehler: zeile_von und zeile_bis sind Zeilennummern ab 1.', 0 ) unless defined $von && defined $bis && $von >= 1;
  return ( 'Fehler: zeile_bis liegt vor zeile_von.', 0 ) if $bis < $von;
  my $n = () = _lines($text);
  return ( 'Fehler: '.$path.' hat '.$n.' Zeilen.', 0 ) if $bis > $n;
  return ( 'Fehler: Bereich zu groß (höchstens '.$MAX_SPAN.' Zeilen) — bitte die Stelle der Ursache eingrenzen.', 0 )
    if $bis - $von + 1 > $MAX_SPAN;
  for my $k (qw( ursache_schicht symptom_schicht )) {
    my $v = $p->{$k} // '';
    return ( 'Fehler: '.$k.' ist eine von '.join( ', ', @SCHICHTEN ).'.', 0 ) unless grep { $_ eq $v } @SCHICHTEN;
  }
  my $kat = $p->{kategorie} // '';
  return ( 'Fehler: kategorie ist eine von '.join( ', ', @KATEGORIEN ).'.', 0 ) unless grep { $_ eq $kat } @KATEGORIEN;
  my @trifft;
  for my $u ( @{ $dev->{ursachen} || [] } ) {
    push @trifft, $u->{id}
      if grep { norm_path( $_->{datei} ) eq $path && $_->{von} <= $bis && $_->{bis} >= $von } @{ $u->{orte} || [] };
  }
  push @{ $dev->{befunde} }, {
    datei => $path, zeile_von => $von, zeile_bis => $bis, ursache_schicht => $p->{ursache_schicht},
    symptom_schicht => $p->{symptom_schicht}, kategorie => $kat, trifft => \@trifft,
  };
  return ( 'Befund '.scalar( @{ $dev->{befunde} } ).' aufgenommen ('.$path.', Zeilen '.$von.'–'.$bis.').', 1 );
}

sub _t_kein_fehler_melden {
  my ( $self, $dev ) = @_;
  $dev->{kein_fehler} = 1;
  return ( 'Aufgenommen: kein Fehler.', 1 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Schichtfehler - The answer world schichtfehler — a web application from recorded pages: sources, fetches, console, reported findings

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # suite.yaml: every tool names the world, the tool's name picks what it does
  tools:
    - { name: datei_lesen, simulator: schichtfehler, description: …, parameters: { … } }

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok, $gap ) = $sims->tool_call( $state, schichtfehler => datei_lesen => { pfad => 'artikel.php' } );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<schichtfehler>): a small PHP application whose pages deliver HTML with
JavaScript that calls PHP again by C<fetch> (and SQL behind it). The model
looks for the B<cause> of a fault whose B<symptom> shows in another layer, and
reports it.

B<No PHP and no browser run.> The answers of the pages and the browser console
were recorded once when the suite was built (by a generator that is not part
of this distribution) and are in the state; this world only looks them up.
The tools are the same for every case; no name gives away a fault. Tool
names, parameters and world keys are German, as the model sees them:

  dateien_auflisten  { }                                   paths with line counts
  datei_lesen        { pfad, von?, bis? }                  source with line numbers
  seite_abrufen      { pfad, parameter? }                  HTTP answer (status, head, numbered body)
  browser_konsole    { pfad, parameter? }                  the browser's console and network log
  befund_melden      { datei, zeile_von, zeile_bis,
                       ursache_schicht, symptom_schicht,
                       kategorie }                         report one fault (may be called again)
  kein_fehler_melden { }                                   report that there is no fault

C<parameter> is a query like C<id=17&q=tee> (with or without C<?>), and a
query may also hang on C<pfad>; the order of the pairs and their encoding do
not matter (L</norm_query>). A fetch that was not recorded is a B<gap of the
simulation> (C<sim_gap>; the answer names the parameters recorded for the
path) — a real server would have answered. A path that does not exist answers
404 like a server; a file not ending in C<.php> is delivered as it is (CSS,
JavaScript, otherwise as text).

A report gets no feedback on whether it is right. The world notes on the
finding only B<which cause> it hits by file and lines (C<trifft>, a list of
IDs; empty = hits none): a cause has one or more C<orte> (file, lines from–to),
and a finding hits when the file is the same and the line ranges overlap.
Category and layers are for the case's rules. A range over more than
C<$MAX_SPAN> lines is refused (else "the whole file" would always hit).

=head2 State

  app:
    type: schichtfehler
    dateien:  { "artikel.php": "<?php …", "js/artikel.js": "…" }
    abrufe:   [ { pfad, parameter, status, status_zeile?, kopf: [ "Content-Type: …" ], rumpf } ]
    konsole:  [ { pfad, parameter, ausgabe } ]
    ursachen: [ { id: u1, orte: [ { datei, von, bis } ] } ]   # never shown to the model
    befunde:  []                  # what the model reports (+ trifft)
    kein_fehler: false            # true after kein_fehler_melden

C<dateien> (files) maps the path relative to the application root to its
text. C<abrufe> (fetches) are the recorded HTTP answers: C<status> like
C<200 OK>, or a whole C<status_zeile> (status line) that replaces
C<HTTP/1.1 E<lt>statusE<gt>>; C<kopf> the header lines, C<rumpf> the body.
C<konsole> (console) holds the recorded console text (C<ausgabe>) per path and
query. C<ursachen> (causes) are read only to fill C<trifft>. C<befunde>
(findings) get one entry per accepted report: C<datei>, C<zeile_von>,
C<zeile_bis>, C<ursache_schicht>, C<symptom_schicht>, C<kategorie>, C<trifft>.
C<kein_fehler> (no fault) is set to C<1> by C<kein_fehler_melden>.

Only the state, deterministic, neutral.

=head2 device_type

C<schichtfehler>.

=head2 tools

  my $tools = $world->tools;   # { datei_lesen => ['pfad'], … }

The tools of this world with their required parameters (for the loader).

=head2 tool

  my ( $output, $ok, $gap ) = $world->tool( $app, $name, \%args, $ctx );

A tool call on the state of the application (C<$app> is changed only by
C<befund_melden> and C<kein_fehler_melden>). A name not in L</tools> is an
error. C<$gap> is set for a fetch of an existing page that was not recorded.

=head2 norm_path

  norm_path('/api/artikel.php');                 # api/artikel.php
  my ( $p, $q ) = norm_path('artikel.php?id=3'); # ( 'artikel.php', 'id=3' )

A path relative to the application root: leading C</> and C<./> removed, the
query split off (second value in list context).

=head2 norm_query

  norm_query('?q=tee&id=3');   # id=3&q=tee

A query in one fixed form: pairs sorted by key (then value), percent encoding
and C<+> decoded and encoded again, empty parts dropped.

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
