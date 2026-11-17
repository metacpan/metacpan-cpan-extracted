package Langertha::Holmgang::Sim::Uebersetzung;
# ABSTRACT: The answer world uebersetzung — a translation job: hand in segments, report ambiguity, look up the glossary

use Moose;
use namespace::autoclean;
use utf8;

use Unicode::Normalize ();

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.001';


# Die Werkzeuge dieser Welt mit ihren Pflichtparametern (fuer den Lader).
our %TOOLS = (
  uebersetzung_abgeben => [qw( segment_id text )],
  mehrdeutig_melden    => [qw( segment_id lesarten frage )],
  glossar_nachschlagen => ['begriff'],
);

#### Plugin contract

sub device_type { 'uebersetzung' }


sub tools { return \%TOOLS }


sub tool {
  my ( $self, $dev, $name, $args, $ctx ) = @_;
  $name //= '';
  my $code = $TOOLS{$name} && $self->can( '_t_'.$name )
    or return ( "Fehler: unbekanntes Werkzeug '".$name."'", 0 );
  return $self->$code( $dev, $args || {} );
}


#### Textanalyse (reine Funktionen)

sub normalize {
  my ( $s ) = @_;
  return '' unless defined $s;
  $s = Unicode::Normalize::NFC("$s");
  $s =~ tr/\x{201E}\x{201C}\x{201D}\x{00AB}\x{00BB}\x{201F}\x{2033}/"/;
  $s =~ tr/\x{201A}\x{2018}\x{2019}\x{2039}\x{203A}\x{201B}\x{2032}/'/;
  $s =~ s/[\x{00A0}\x{202F}\x{2007}\x{2009}\x{200A}\x{2002}\x{2003}]/ /g;
  $s =~ s/[\x{200B}\x{FEFF}]//g;
  $s =~ s/\s+/ /g;
  $s =~ s/\A | \z//g;
  return $s;
}


sub codes { my ( $s ) = @_; return ( $s // '' ) =~ /`([^`]+)`/g }


my $PLACEHOLDER = qr/\{\{\s*[A-Za-z_][\w.]*\s*\}\}|\{[A-Za-z_][\w.]*\}|%(?:\d+\$)?[sdif]|<\/?[A-Za-z][A-Za-z0-9]*(?:\s[^<>]*)?\/?>/;

sub _no_codes { my ( $s ) = @_; ( my $t = $s // '' ) =~ s/`[^`]*`/ /g; return $t }

sub placeholders { my ( $s ) = @_; return _no_codes($s) =~ /($PLACEHOLDER)/g }


sub numbers {
  my ( $s, $lang ) = @_;
  ( my $t = _no_codes($s) ) =~ s/$PLACEHOLDER/ /g;
  my @out;
  while ( $t =~ /(?<![\p{L}\d_])(\d+(?:[.,]\d+)*)/g ) {
    my $tok = $1;
    my $v;
    if ( ( $lang // 'de' ) eq 'en' ) {
      if    ( $tok =~ /\A\d{1,3}(?:,\d{3})+(?:\.\d+)?\z/ ) { ( $v = $tok ) =~ tr/,//d }
      elsif ( $tok =~ /\A\d+(?:\.\d+)?\z/ )               { $v = $tok }
    }
    else {
      if    ( $tok =~ /\A\d{1,3}(?:\.\d{3})+(?:,\d+)?\z/ ) { ( $v = $tok ) =~ tr/.//d; $v =~ tr/,/./ }
      elsif ( $tok =~ /\A\d+(?:,\d+)?\z/ )                { ( $v = $tok ) =~ tr/,/./ }
    }
    push @out, defined $v ? _value($v) : $tok;
  }
  return @out;
}


sub _value {
  my ( $v ) = @_;
  $v =~ s/\A0+(?=\d)//;
  $v =~ s/(\.\d*?)0+\z/$1/;
  $v =~ s/\.\z//;
  return $v;
}

# Was aus @want (mit Vielfachheit) in @have fehlt.
sub _missing {
  my ( $want, $have ) = @_;
  my %n;
  $n{$_}++ for @$have;
  my @miss;
  for (@$want) { if ( $n{$_} ) { $n{$_}-- } else { push @miss, $_ } }
  return \@miss;
}

sub length_class {
  my ( $src, $txt ) = @_;
  my ( $n, $m ) = map { length normalize($_) } $src, $txt;
  return 'kurz' if $m < 0.5 * $n - 5;
  return 'lang' if $m > 2 * $n + 10;
  return 'ok';
}


sub analyse {
  my ( $src, $text, $from, $to ) = @_;
  my $norm  = normalize($text);
  my $snorm = normalize($src);
  my @z = numbers( $norm, $to );
  my @c = codes($norm);
  my @p = placeholders($norm);
  return {
    text                 => "$text",
    norm                 => $norm,
    zahlen               => \@z,
    codes                => \@c,
    platzhalter          => \@p,
    fehlende_zahlen      => _missing( [ numbers( $snorm, $from ) ], \@z ),
    fehlende_codes       => _missing( [ codes($snorm) ], \@c ),
    fehlende_platzhalter => _missing( [ placeholders($snorm) ], \@p ),
    laenge               => length_class( $snorm, $norm ),
  };
}


#### Werkzeuge

sub _segment {
  my ( $self, $dev, $id ) = @_;
  my $seg = $dev->{segmente} || {};
  $id = '' unless defined $id && !ref $id;
  ( my $k = $id ) =~ s/\A\s+|\s+\z//g;
  $k =~ s/\A\[(.*)\]\z/$1/;
  return ( $k, undef ) if exists $seg->{$k};
  return ( undef, "Fehler: Segment '$id' gibt es in diesem Auftrag nicht (".join( ', ', sort keys %$seg ).').' );
}

sub _t_uebersetzung_abgeben {
  my ( $self, $dev, $p ) = @_;
  my ( $id, $err ) = $self->_segment( $dev, $p->{segment_id} );
  return ( $err, 0 ) unless defined $id;
  my $text = $p->{text};
  return ( 'Fehler: text ist leer.', 0 ) unless defined $text && !ref $text && length normalize($text);
  $dev->{abgaben}{$id} = analyse( $dev->{segmente}{$id}, $text, $dev->{quelle} // 'de', $dev->{ziel} // 'en' );
  return ( "Segment $id: angenommen.", 1 );
}

sub _t_mehrdeutig_melden {
  my ( $self, $dev, $p ) = @_;
  my ( $id, $err ) = $self->_segment( $dev, $p->{segment_id} );
  return ( $err, 0 ) unless defined $id;
  my @l = grep { defined && !ref && length normalize($_) } @{ ref $p->{lesarten} eq 'ARRAY' ? $p->{lesarten} : [] };
  return ( 'Fehler: mindestens zwei Lesarten angeben.', 0 ) unless @l >= 2;
  $dev->{meldungen}{$id} = { lesarten => [ map { normalize($_) } @l ], frage => normalize( $p->{frage} ) };
  return ( "Meldung zu Segment $id: angenommen.", 1 );
}

sub _t_glossar_nachschlagen {
  my ( $self, $dev, $p ) = @_;
  my $q = lc normalize( $p->{begriff} );
  return ( 'Fehler: begriff ist leer.', 0 ) unless length $q;
  push @{ $dev->{_nachschlagen} }, $q;
  my @hit = grep {
    my $e = $_;
    grep { index( lc normalize( $e->{$_} // '' ), $q ) >= 0 } qw( de en );
  } @{ $dev->{glossar} || [] };
  return ( "Kein Eintrag für \"$q\".", 1 ) unless @hit;
  return ( join( "\n", map { "de: $_->{de} | en: $_->{en}" } @hit ), 1 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Uebersetzung - The answer world uebersetzung — a translation job: hand in segments, report ambiguity, look up the glossary

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # suite.yaml: every tool names the world, the tool's name picks what it does
  tools:
    - { name: uebersetzung_abgeben, simulator: uebersetzung, description: …, parameters: { … } }

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok ) = $sims->tool_call( $state, uebersetzung => uebersetzung_abgeben => { segment_id => 's1', text => 'The invoice …' } );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<uebersetzung>): a B<translation job> with segments. The tools are the
same for every case and always answer neutrally — the world never tells
whether a translation is right. Tool names, parameters and world keys are
German, as the model sees them:

  uebersetzung_abgeben { segment_id, text }               hand in the translation of a segment (again: replaces it)
  mehrdeutig_melden    { segment_id, lesarten[], frage }  report a segment as ambiguous (readings, question)
  glossar_nachschlagen { begriff }                        search the job's glossary (both languages)

A C<segment_id> may be written in brackets (C<[s1]>) and with surrounding
blanks. An unknown segment, an empty text, fewer than two non-empty readings
or an empty term are errors.

=head2 Normalisation

Every hand-in is normalised (L</normalize>: NFC, typographic quotes to
straight ones, no-break and thin spaces to spaces, zero-width characters
dropped, whitespace collapsed and trimmed) and taken apart; grading checks
only the state:

  abgaben:
    s1:
      text:  "…"                      # as handed in
      norm:  "…"                      # normalised (regex rules read here)
      zahlen: [ "1250.5", "14" ]      # numbers in the target language's format, as values
      codes:  [ "systemctl restart nginx" ]   # contents of `…`
      platzhalter: [ "{count}", "<b>", "</b>" ]
      fehlende_zahlen: []             # numbers of the source missing in the hand-in
      fehlende_codes: []              # codes of the source not literally inside `…`
      fehlende_platzhalter: []        # placeholders/tags of the source missing (with multiplicity)
      laenge: ok                      # ok | kurz | lang (against the length of the source)

B<Numbers> are read in the format of the language (L</numbers>): German
C<1.250,50> (thousands point, decimal comma), English C<1,250.50>. What does
not fit that format (C<1.4.2>, a C<1.250,50> in an English text) stays text
and so matches no number of the source. Numbers inside codes and
placeholders do not count.

B<Length>: C<ok> when the hand-in is at least half (minus 5 characters) and
at most double (plus 10 characters) as long as the source; the allowance keeps
short interface strings ("Save" → "Speichern") in range. C<kurz> (short) and
C<lang> (long) otherwise.

=head2 State

  uebersetzung:
    type: uebersetzung
    quelle: de                     # language of the source (de|en), default de
    ziel: en                       # language of the translation, default en
    segmente: { s1: "Die Rechnung …", s2: "…" }
    glossar: [ { de: Verantwortlicher, en: controller } ]
    abgaben: {}                    # hand-ins, see above
    meldungen: {}                  # s1: { lesarten: [ … ], frage: "…" }   (normalised)

A lookup leaves only a run trace (C<_nachschlagen>, the normalised lower-case
terms; a key with a leading C<_> is bookkeeping and no change).

Only the state, deterministic, neutral.

=head2 device_type

C<uebersetzung>.

=head2 tools

  my $tools = $world->tools;   # { uebersetzung_abgeben => [qw( segment_id text )], … }

The tools of this world with their required parameters (for the loader).

=head2 tool

  my ( $output, $ok ) = $world->tool( $auftrag, $name, \%args, $ctx );

A tool call on the state of the job (C<$auftrag> is changed). A name not in
L</tools> is an error.

=head2 normalize

  normalize("„Hallo“\x{a0} Welt ");   # '"Hallo" Welt'

NFC; typographic double quotes (C<„ “ ” « » ‟ ″>) to C<">, single ones
(C<‚ ‘ ’ ‹ › ‛ ′>) to C<'>; no-break, thin and fixed-width spaces to a space;
zero-width space and BOM dropped; whitespace collapsed to one space and
trimmed. C<undef> gives the empty text.

=head2 codes

  codes('Run `nginx -t` first');   # ( 'nginx -t' )

The contents between backticks, in order.

=head2 placeholders

  placeholders('{count} Dateien in <b>{ordner}</b>');   # ( '{count}', '<b>', '{ordner}', '</b>' )

Placeholders (C<{name}>, C<{{name}}>, C<%s>, C<%1$d>) and tags outside
backticks, in order.

=head2 numbers

  numbers( 'Die Rechnung über 1.250,50 € ist in 14 Tagen fällig.', 'de' );   # ( '1250.5', '14' )

The numbers of a text read in the format of the language (C<de>, the default,
or C<en>), as values (text without superfluous zeros); a token that does not
fit the format comes back unchanged. Codes and placeholders do not count.

=head2 length_class

  length_class( $quelle, $abgabe );   # 'ok' | 'kurz' | 'lang'

The length class of a hand-in against its source (see L</DESCRIPTION>).

=head2 analyse

  my $abgabe = analyse( $quelltext, $abgabetext, 'de', 'en' );

What the world puts into the state for a hand-in (see L</Normalisation>).

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
