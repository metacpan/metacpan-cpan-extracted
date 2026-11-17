package Langertha::Holmgang::Sim::Sehen;
# ABSTRACT: The answer world sehen — hand in what an image shows: graph, sequence, fields, table, values, finding

use Moose;
use namespace::autoclean;
use utf8;
use feature 'fc';
use JSON::MaybeXS ();
use Unicode::Normalize qw( NFC );

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.001';


# Die Werkzeuge dieser Welt mit ihren Pflichtparametern (fuer den Lader).
our %TOOLS = (
  graph_abgeben   => [qw( gerichtet knoten kanten )],
  ablauf_abgeben  => [qw( teilnehmer nachrichten )],
  felder_abgeben  => [qw( belegart nummer datum lieferdatum betrag_brutto betrag_netto waehrung iban positionen )],
  tabelle_abgeben => [qw( kopf zeilen )],
  werte_abgeben   => ['reihen'],
  befund_abgeben  => [qw( befehl fehlercode datei zeile )],
  bild_melden     => [qw( grund notiz )],
);

# Werkzeug -> Schluessel im Zustand
my %SLOT = (
  graph_abgeben   => 'graph',
  ablauf_abgeben  => 'ablauf',
  felder_abgeben  => 'felder',
  tabelle_abgeben => 'tabelle',
  werte_abgeben   => 'werte',
  befund_abgeben  => 'befund',
  bild_melden     => 'meldung',
);

our @GRUND = qw( kein_diagramm unlesbar teilweise_unlesbar );

# Monatsnamen, wie sie nach norm_text aussehen
our %MONTH = (
  ( map { ( $_ => 1 ) } qw( januar jaenner jan january ) ),
  ( map { ( $_ => 2 ) } qw( februar feber feb february ) ),
  ( map { ( $_ => 3 ) } qw( maerz mrz mar march ) ),
  ( map { ( $_ => 4 ) } qw( april apr ) ),
  ( map { ( $_ => 5 ) } qw( mai may ) ),
  ( map { ( $_ => 6 ) } qw( juni jun june ) ),
  ( map { ( $_ => 7 ) } qw( juli jul july ) ),
  ( map { ( $_ => 8 ) } qw( august aug ) ),
  ( map { ( $_ => 9 ) } qw( september sep sept ) ),
  ( map { ( $_ => 10 ) } qw( oktober okt oct october ) ),
  ( map { ( $_ => 11 ) } qw( november nov ) ),
  ( map { ( $_ => 12 ) } qw( dezember dez dec december ) ),
);

my $ISO_HINT = ' — bitte als JJJJ-MM-TT angeben.';
my $AMOUNT_HINT = ' — bitte als Zahl angeben, z. B. 1234.56.';

#### Plugin contract

sub device_type { 'sehen' }


sub tools { return \%TOOLS }


sub tool {
  my ( $self, $dev, $name, $args, $ctx ) = @_;
  $name //= '';
  my $code = $TOOLS{$name} && $self->can( '_t_'.$name )
    or return ( "Fehler: unbekanntes Werkzeug '".$name."'", 0 );
  $args = {} unless ref $args eq 'HASH';
  my ( $norm, $text, $err ) = $self->$code($args);
  return ( 'Fehler: '.$err, 0 ) if defined $err;
  my $slot = $SLOT{$name};
  my $again = ref $dev->{$slot} eq 'HASH';
  $dev->{$slot} = { roh => _copy($args), norm => $norm };
  return ( $text.( $again ? ' Die frühere Abgabe ist ersetzt.' : '' ), 1 );
}


#### Normalisierung (reine Funktionen, auch fuer Generatoren und Regeln)

sub norm_text {
  my ( $s ) = @_;
  return undef unless defined $s && !ref $s;
  $s = NFC("$s");
  $s =~ s/[\x{00AD}\x{200B}-\x{200D}\x{2060}\x{FEFF}]//g;
  $s = NFC( fc $s );
  $s =~ s/ä/ae/g;
  $s =~ s/ö/oe/g;
  $s =~ s/ü/ue/g;
  $s =~ s/ß/ss/g;    # fc kennt es schon; sicher ist sicher
  $s =~ tr/\x{2010}-\x{2015}\x{2212}\x{FE58}\x{FE63}\x{FF0D}/-/;
  $s =~ tr/\x{201C}-\x{201F}\x{00AB}\x{00BB}\x{2033}\x{FF02}/"/;
  $s =~ tr/\x{2018}-\x{201B}\x{2039}\x{203A}\x{2032}\x{0060}\x{00B4}\x{FF07}/'/;
  $s =~ s/[\s\p{Zs}]+/ /g;
  $s =~ s/\A \z|\A | \z//g;
  return $s;
}


sub _ymd {
  my ( $y, $m, $d ) = @_;
  return undef unless $y >= 1000 && $y <= 9999 && $m >= 1 && $m <= 12 && $d >= 1;
  my $leap = ( $y % 4 == 0 && $y % 100 != 0 ) || $y % 400 == 0;
  my $max = ( 31, ( $leap ? 29 : 28 ), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[ $m - 1 ];
  return undef if $d > $max;
  return sprintf '%04d-%02d-%02d', $y, $m, $d;
}

sub norm_date {
  my ( $in ) = @_;
  my $s = norm_text($in);
  return ( undef, 'nicht lesbar' ) unless defined $s && length $s;
  my ( $y, $m, $d );
  if ( $s =~ m{\A(\d{4})([-/.])(\d{1,2})\2(\d{1,2})\z} ) {
    ( $y, $m, $d ) = ( $1, $3, $4 );
  }
  elsif ( $s =~ m{\A(\d{1,2})\.\s?(\d{1,2})\.\s?(\d{2}|\d{4})\z} ) {
    return ( undef, 'mehrdeutig' ) if length $3 == 2;
    ( $d, $m, $y ) = ( $1, $2, $3 );
  }
  elsif ( $s =~ m{\A(\d{1,2})([-/])(\d{1,2})\2(\d{2}|\d{4})\z} ) {
    my ( $p1, $p2 ) = ( $1, $3 );
    $y = $4;
    return ( undef, 'mehrdeutig' ) if length $y == 2;
    if    ( $p1 == $p2 )             { ( $d, $m ) = ( $p1, $p2 ) }
    elsif ( $p1 > 12 && $p2 <= 12 ) { ( $d, $m ) = ( $p1, $p2 ) }
    elsif ( $p2 > 12 && $p1 <= 12 ) { ( $m, $d ) = ( $p1, $p2 ) }
    elsif ( $p1 > 12 && $p2 > 12 )  { return ( undef, 'ungültig' ) }
    else                          { return ( undef, 'mehrdeutig' ) }
  }
  elsif ( $s =~ m{\A(\d{1,2})\.?\s?([a-z]+)\.?,?\s?(\d{2}|\d{4})\z} && $MONTH{$2} ) {
    return ( undef, 'mehrdeutig' ) if length $3 == 2;
    ( $d, $m, $y ) = ( $1, $MONTH{$2}, $3 );
  }
  elsif ( $s =~ m{\A([a-z]+)\.?\s(\d{1,2})(?:st|nd|rd|th)?,?\s(\d{2}|\d{4})\z} && $MONTH{$1} ) {
    return ( undef, 'mehrdeutig' ) if length $3 == 2;
    ( $m, $d, $y ) = ( $MONTH{$1}, $2, $3 );
  }
  else { return ( undef, 'nicht lesbar' ) }
  my $iso = _ymd( $y, $m, $d );
  return defined $iso ? ($iso) : ( undef, 'ungültig' );
}


sub norm_amount {
  my ( $in ) = @_;
  return ( undef, 'nicht lesbar' ) unless defined $in && !ref $in;
  my $s = NFC("$in");
  $s =~ s/[\s\p{Zs}]+/ /g;
  $s =~ s/\A | \z//g;
  $s =~ s/\A(?:€|\$|£|eur|usd|gbp|chf)\s?//i;
  $s =~ s/\s?(?:€|\$|£|eur|usd|gbp|chf)\z//i;
  my $neg = $s =~ s/\A[-\x{2212}]\s?// ? 1 : 0;
  my ( $int, $dec );
  if    ( $s =~ /\A(\d+)\z/ )                 { ( $int, $dec ) = ( $1, '' ) }
  elsif ( $s =~ /\A\d+[.,]\d{3}\z/ )          { return ( undef, 'mehrdeutig' ) }
  elsif ( $s =~ /\A(\d+)[.,](\d{1,2})\z/ )    { ( $int, $dec ) = ( $1, $2 ) }
  elsif ( $s =~ /\A(\d{1,3}(?:([.,' \x{2019}])\d{3})+)(?:([.,])(\d{1,2}))?\z/ ) {
    my ( $g, $sep, $ds, $dd ) = ( $1, $2, $3, $4 );
    return ( undef, 'nicht lesbar' ) if defined $ds && $ds eq $sep;
    return ( undef, 'nicht lesbar' ) if ( () = $g =~ /[^\d]/g ) != ( () = $g =~ /\Q$sep\E/g );
    ( $int = $g ) =~ s/\D//g;
    $dec = $dd // '';
  }
  else { return ( undef, 'nicht lesbar' ) }
  my $cents = ( 0 + $int ) * 100 + ( length $dec ? 0 + substr( $dec.'0', 0, 2 ) : 0 );
  return ( $neg ? -$cents : $cents );
}


sub norm_number {
  my ( $in ) = @_;
  return undef unless defined $in && !ref $in;
  my $s = norm_text($in);
  return undef unless $s =~ /\A(-?)(\d+)(?:[.,](\d+))?\z/;
  return 0 + ( $1.$2.( defined $3 ? '.'.$3 : '' ) );
}


sub norm_iban {
  my ( $in ) = @_;
  return undef unless defined $in && !ref $in;
  ( my $s = NFC("$in") ) =~ s/[\s\p{Zs}]+//g;
  return length $s ? uc $s : undef;
}


sub norm_currency {
  my ( $in ) = @_;
  my $s = norm_text($in);
  return undef unless defined $s && length $s;
  return 'EUR' if $s eq '€';
  return 'GBP' if $s eq '£';
  return uc $s;
}


#### Hilfen

sub _copy {
  my ( $d ) = @_;
  return [ map { _copy($_) } @$d ] if ref $d eq 'ARRAY';
  return { map { ( $_ => _copy( $d->{$_} ) ) } keys %$d } if ref $d eq 'HASH';
  return $d;
}

sub _uniq_sorted {
  my %seen;
  return [ sort grep { !$seen{$_}++ } @_ ];
}

sub _plain { my ( $v ) = @_; return defined $v && !ref $v }

sub _bool {
  my ( $v ) = @_;
  return undef unless defined $v;
  # is_bool vor dem Ref-Test: YAML::XS laedt false als Kernboolean ohne Ref
  return $v ? 1 : 0 if JSON::MaybeXS::is_bool($v);
  return undef if ref $v;
  my $s = norm_text($v);
  return 1 if $s =~ /\A(?:1|true|ja|yes)\z/;
  return 0 if $s =~ /\A(?:0|false|nein|no)\z/;
  return undef;
}

# Liste nicht-leerer Texte, normalisiert
sub _texts {
  my ( $name, $l ) = @_;
  return ( undef, $name.' muss eine Liste von Texten sein.' ) unless ref $l eq 'ARRAY';
  my @out;
  for my $i ( 0 .. $#$l ) {
    my $t = _plain( $l->[$i] ) ? norm_text( $l->[$i] ) : undef;
    return ( undef, $name.'['.$i.'] muss ein nicht leerer Text sein.' ) unless defined $t && length $t;
    push @out, $t;
  }
  return ( \@out );
}

# ein Feld, das fehlen oder null sein darf
sub _opt_text {
  my ( $p, $k ) = @_;
  my $v = $p->{$k};
  return (undef) unless defined $v;
  return ( undef, $k.' muss ein Text oder null sein.' ) if ref $v;
  my $t = norm_text($v);
  return length $t ? ($t) : (undef);
}

sub _opt_date {
  my ( $p, $k ) = @_;
  my $v = $p->{$k};
  return (undef) unless defined $v && ( ref $v || length norm_text($v) );
  my ( $iso, $why ) = norm_date($v);
  return ($iso) if defined $iso;
  my $show = ref $v ? '' : " '".$v."'";
  return ( undef, $k.$show.' ist kein gültiges Datum.' ) if $why eq 'ungültig';
  return ( undef, $k.$show.' ist '.$why.$ISO_HINT );
}

sub _opt_amount {
  my ( $what, $v ) = @_;
  return (undef) unless defined $v && ( ref $v || length norm_text($v) );
  my ( $c, $why ) = norm_amount($v);
  return ($c) if defined $c;
  return ( undef, $what.( ref $v ? '' : " '".$v."'" ).' ist '.$why.$AMOUNT_HINT );
}

sub _num_text {
  my ( $n ) = @_;
  my $s = sprintf '%.10f', $n;
  $s =~ s/\.?0+\z//;
  return $s eq '-0' ? '0' : $s;
}

#### Werkzeuge: ( norm, text ) oder ( undef, undef, Fehler )

sub _t_graph_abgeben {
  my ( $self, $p ) = @_;
  my $dir = _bool( $p->{gerichtet} );
  return ( undef, undef, 'gerichtet muss true oder false sein.' ) unless defined $dir;
  my ( $knoten, $err ) = _texts( knoten => $p->{knoten} );
  return ( undef, undef, $err ) if $err;
  my %known = map { ( $_ => 1 ) } @$knoten;
  my $k = $p->{kanten};
  return ( undef, undef, 'kanten muss eine Liste sein.' ) unless ref $k eq 'ARRAY';
  my ( @kanten, @besch );
  for my $i ( 0 .. $#$k ) {
    my $e = $k->[$i];
    my $at = 'kanten['.$i.']';
    return ( undef, undef, $at.' muss ein Objekt mit von und nach sein.' ) unless ref $e eq 'HASH';
    my ( $von, $nach ) = map { _plain($_) ? norm_text($_) : undef } @{$e}{qw( von nach )};
    return ( undef, undef, $at.' braucht von und nach.' ) unless defined $von && length $von && defined $nach && length $nach;
    for ( [ von => $von, $e->{von} ], [ nach => $nach, $e->{nach} ] ) {
      return ( undef, undef, $at.'.'.$_->[0]." nennt '".$_->[2]."', das nicht in knoten steht." ) unless $known{ $_->[1] };
    }
    return ( undef, undef, $at.'.text muss ein Text sein.' ) if ref $e->{text};
    my $edge = $dir ? $von.' -> '.$nach : join( ' -- ', sort $von, $nach );
    push @kanten, $edge;
    my $t = norm_text( $e->{text} );
    push @besch, $edge.': '.$t if defined $t && length $t;
  }
  my $norm = { gerichtet => $dir, knoten => _uniq_sorted(@$knoten), kanten => _uniq_sorted(@kanten), beschriftungen => _uniq_sorted(@besch) };
  return ( $norm, 'Graph abgegeben: '.( $dir ? 'gerichtet' : 'ungerichtet' ).', '.scalar( @{ $norm->{knoten} } ).' Knoten, '.scalar( @{ $norm->{kanten} } ).' Kanten.' );
}

sub _t_ablauf_abgeben {
  my ( $self, $p ) = @_;
  my ( $tn, $err ) = _texts( teilnehmer => $p->{teilnehmer} );
  return ( undef, undef, $err ) if $err;
  my %seen;
  my @teilnehmer = grep { !$seen{$_}++ } @$tn;
  my $n = $p->{nachrichten};
  return ( undef, undef, 'nachrichten muss eine Liste sein.' ) unless ref $n eq 'ARRAY';
  my @msgs;
  for my $i ( 0 .. $#$n ) {
    my $m = $n->[$i];
    my $at = 'nachrichten['.$i.']';
    return ( undef, undef, $at.' muss ein Objekt mit von, an und text sein.' ) unless ref $m eq 'HASH';
    my ( $von, $an ) = map { _plain($_) ? norm_text($_) : undef } @{$m}{qw( von an )};
    return ( undef, undef, $at.' braucht von und an.' ) unless defined $von && length $von && defined $an && length $an;
    for ( [ von => $von, $m->{von} ], [ an => $an, $m->{an} ] ) {
      return ( undef, undef, $at.'.'.$_->[0]." nennt '".$_->[2]."', der nicht in teilnehmer steht." ) unless $seen{ $_->[1] };
    }
    return ( undef, undef, $at.'.text muss ein Text sein.' ) if ref $m->{text};
    my $t = norm_text( $m->{text} );
    push @msgs, $von.' -> '.$an.( defined $t && length $t ? ': '.$t : '' );
  }
  return ( { teilnehmer => \@teilnehmer, nachrichten => \@msgs },
    'Ablauf abgegeben: '.scalar(@teilnehmer).' Teilnehmer, '.scalar(@msgs).' Nachrichten.' );
}

sub _t_felder_abgeben {
  my ( $self, $p ) = @_;
  my %n;
  for my $k (qw( belegart nummer )) {
    my ( $v, $err ) = _opt_text( $p, $k );
    return ( undef, undef, $err ) if $err;
    $n{$k} = $v;
  }
  for my $k (qw( datum lieferdatum )) {
    my ( $v, $err ) = _opt_date( $p, $k );
    return ( undef, undef, $err ) if $err;
    $n{$k} = $v;
  }
  for my $k (qw( betrag_brutto betrag_netto )) {
    my ( $v, $err ) = _opt_amount( $k, $p->{$k} );
    return ( undef, undef, $err ) if $err;
    $n{$k} = $v;
  }
  for my $k (qw( waehrung iban )) {
    return ( undef, undef, $k.' muss ein Text oder null sein.' ) if ref $p->{$k};
  }
  $n{waehrung} = norm_currency( $p->{waehrung} );
  $n{iban}     = norm_iban( $p->{iban} );
  my $l = $p->{positionen} // [];
  return ( undef, undef, 'positionen muss eine Liste sein.' ) unless ref $l eq 'ARRAY';
  my @pos;
  for my $i ( 0 .. $#$l ) {
    my $e = $l->[$i];
    my $at = 'positionen['.$i.']';
    $e = { text => $e } if _plain($e);
    return ( undef, undef, $at.' muss ein Text oder ein Objekt mit text sein.' ) unless ref $e eq 'HASH' && _plain( $e->{text} );
    my %x = ( text => norm_text( $e->{text} ) );
    if ( defined $e->{menge} && ( ref $e->{menge} || length norm_text( $e->{menge} ) ) ) {
      $x{menge} = norm_number( $e->{menge} );
      return ( undef, undef, $at.".menge '".( ref $e->{menge} ? '' : $e->{menge} )."' ist keine Zahl." ) unless defined $x{menge};
    }
    my ( $b, $err ) = _opt_amount( $at.'.betrag', $e->{betrag} );
    return ( undef, undef, $err ) if $err;
    $x{betrag} = $b if defined $b;
    push @pos, \%x;
  }
  $n{positionen} = \@pos;
  return ( \%n, 'Felder abgegeben: '.scalar(@pos).' Positionen.' );
}

sub _t_tabelle_abgeben {
  my ( $self, $p ) = @_;
  my $kopf = $p->{kopf};
  return ( undef, undef, 'kopf muss eine Liste von Texten sein.' ) unless ref $kopf eq 'ARRAY' && !grep { ref } @$kopf;
  my $z = $p->{zeilen};
  return ( undef, undef, 'zeilen muss eine Liste von Listen sein.' ) unless ref $z eq 'ARRAY';
  my @rows;
  for my $i ( 0 .. $#$z ) {
    return ( undef, undef, 'zeilen['.$i.'] muss eine Liste von Texten sein.' )
      unless ref $z->[$i] eq 'ARRAY' && !grep { ref } @{ $z->[$i] };
    push @rows, [ map { norm_text($_) // '' } @{ $z->[$i] } ];
  }
  my $norm = {
    kopf        => [ map { norm_text($_) // '' } @$kopf ],
    zeilen      => \@rows,
    zeilen_text => [ map { join ' | ', @$_ } @rows ],
  };
  return ( $norm, 'Tabelle abgegeben: '.scalar(@$kopf).' Spalten, '.scalar(@rows).' Zeilen.' );
}

sub _t_werte_abgeben {
  my ( $self, $p ) = @_;
  my $r = $p->{reihen};
  return ( undef, undef, 'reihen muss eine Liste sein.' ) unless ref $r eq 'ARRAY';
  my ( %reihen, $points );
  for my $i ( 0 .. $#$r ) {
    my $e = $r->[$i];
    my $at = 'reihen['.$i.']';
    return ( undef, undef, $at.' muss ein Objekt mit name und punkte sein.' ) unless ref $e eq 'HASH';
    my $name = _plain( $e->{name} ) ? norm_text( $e->{name} ) : undef;
    return ( undef, undef, $at.'.name muss ein nicht leerer Text sein.' ) unless defined $name && length $name;
    return ( undef, undef, $at.".name '".$e->{name}."' kommt doppelt vor." ) if $reihen{$name};
    my $pk = $e->{punkte};
    return ( undef, undef, $at.'.punkte muss eine Liste sein.' ) unless ref $pk eq 'ARRAY';
    my %pts;
    for my $j ( 0 .. $#$pk ) {
      my $pt = $pk->[$j];
      my $pat = $at.'.punkte['.$j.']';
      return ( undef, undef, $pat.' muss ein Objekt mit x und y sein.' ) unless ref $pt eq 'HASH';
      return ( undef, undef, $pat.'.x muss eine Zahl oder ein Text sein.' ) unless _plain( $pt->{x} ) && length norm_text( $pt->{x} );
      my $xn = norm_number( $pt->{x} );
      my $x = defined $xn ? _num_text($xn) : norm_text( $pt->{x} );
      my $y = norm_number( $pt->{y} );
      return ( undef, undef, $pat.'.y muss eine Zahl sein.' ) unless defined $y;
      return ( undef, undef, $pat.".x '".$pt->{x}."' kommt doppelt vor." ) if exists $pts{$x};
      $pts{$x} = $y;
      $points++;
    }
    $reihen{$name} = \%pts;
  }
  return ( { reihen => \%reihen }, 'Werte abgegeben: '.scalar(@$r).' Reihen, '.( $points // 0 ).' Punkte.' );
}

sub _t_befund_abgeben {
  my ( $self, $p ) = @_;
  my %n;
  for my $k (qw( befehl fehlercode datei )) {
    my ( $v, $err ) = _opt_text( $p, $k );
    return ( undef, undef, $err ) if $err;
    $n{$k} = $v;
  }
  my $z = $p->{zeile};
  if ( defined $z && ( ref $z || length norm_text($z) ) ) {
    my $s = ref $z ? '' : norm_text($z);
    return ( undef, undef, 'zeile muss eine ganze Zahl ab 1 oder null sein.' ) unless $s =~ /\A0*([1-9]\d{0,8})\z/;
    $n{zeile} = 0 + $1;
  }
  else { $n{zeile} = undef }
  return ( \%n, 'Befund abgegeben.' );
}

sub _t_bild_melden {
  my ( $self, $p ) = @_;
  my $g = _plain( $p->{grund} ) ? norm_text( $p->{grund} ) : '';
  $g =~ s/[ -]/_/g;
  return ( undef, undef, 'grund muss '.join( ', ', @GRUND[ 0 .. $#GRUND - 1 ] ).' oder '.$GRUND[-1].' sein.' )
    unless grep { $_ eq $g } @GRUND;
  return ( undef, undef, 'notiz muss ein Text sein.' ) if ref $p->{notiz};
  return ( { grund => $g, notiz => norm_text( $p->{notiz} ) // '' }, 'Meldung abgegeben: '.$g.'.' );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Sehen - The answer world sehen — hand in what an image shows: graph, sequence, fields, table, values, finding

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # suite.yaml: every tool names the world, the tool's name picks what it does
  tools:
    - { name: felder_abgeben, simulator: sehen, description: …, parameters: { … } }

  # a case: the image goes with the user message, the world starts empty
  state:
    sehen: { type: sehen }
  rules:
    - title: Rechnungsdatum
      state: sehen.felder.norm.datum
      equals: "2024-04-03"
    - title: Kante A nach B
      state: sehen.graph.norm.kanten
      contains: [ "a -> b" ]

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok ) = $sims->tool_call( $state, sehen => bild_melden => { grund => 'unlesbar', notiz => '' } );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<sehen>) for cases whose task is to B<read an image> — a diagram, a
receipt, a table, a chart, a screenshot of an error. The model hands in what it
sees through one of the tools below; the world stores the answer, and the
case's rules grade it at the end state. Nothing in the world knows the right
answer, and no answer says whether the hand-in is right. Tool names,
parameters and world keys are German, as the model sees them:

  graph_abgeben    { gerichtet, knoten[], kanten[{von, nach, text?}] }       a graph or flow chart
  ablauf_abgeben   { teilnehmer[], nachrichten[{von, an, text}] }            a sequence diagram
  felder_abgeben   { belegart, nummer, datum, lieferdatum, betrag_brutto,
                     betrag_netto, waehrung, iban, positionen[] }            the fields of a receipt or invoice
  tabelle_abgeben  { kopf[], zeilen[[]] }                                    a table
  werte_abgeben    { reihen[{name, punkte[{x, y}]}] }                        the data points of a chart
  befund_abgeben   { befehl, fehlercode, datei, zeile }                      what a screenshot of an error shows
  bild_melden      { grund, notiz }                                          the image cannot be read as asked

C<grund> (reason) of C<bild_melden> is one of C<kein_diagramm> (not a
diagram), C<unlesbar> (unreadable), C<teilweise_unlesbar> (partly unreadable).

B<A repeated call replaces> the earlier hand-in of the same tool entirely;
hand-ins of different tools stand side by side. A call the world refuses
(an error) changes nothing — an earlier hand-in stays.

=head2 Normalisation

Every hand-in is stored twice: as the model sent it (C<roh>, raw) and
normalised (C<norm>), so rules compare values, not spellings. The rules
(applied by the functions below, which case authors and generators may use
to write expected values):

=over 4

=item Text (L</norm_text>)

Unicode NFC, full case folding, C<ä ö ü> transcribed as C<ae oe ue> (C<ß>
becomes C<ss> by case folding), so C<Straße>, C<STRASSE> and C<strasse> are
equal, and C<Müller> equals C<Mueller>. Every dash and minus sign becomes
C<->, typographic double quotes become C<">, single quotes and apostrophes
C<'>; soft hyphens and zero-width characters are dropped; runs of white space
become one space, trimmed at both ends.

=item Dates (L</norm_date>)

To ISO C<YYYY-MM-DD>. Read are ISO and year-first forms (C<2024-04-03>,
C<2024/04/03>), the German dotted form (C<3.4.2024>, day first), slash or
hyphen forms with the year last (C<13/04/2024>) when the day is evident, and
month names in German or English (C<3. April 2024>, C<April 3, 2024>,
C<3 Apr 2024>, C<3. Jänner 2024>). B<Ambiguous> forms are refused neutrally
and change nothing: a two-digit year (C<03.04.24>), and a slash or hyphen
form whose first two numbers both could be the month (C<03/04/2024>). An
impossible date (C<30.02.2024>) is refused as well.

=item Amounts (L</norm_amount>)

To whole B<cents> (an integer): C<12.5>, C<"12,50">, C<"1.234,56">,
C<"1,234.56">, C<"1 234,56 €">. A leading currency sign or code (C<€ $ £>,
C<EUR USD GBP CHF>) or a trailing one is dropped — the currency is its own
field. B<Ambiguous> amounts are refused: one separator followed by exactly
three digits (C<1.234>, C<1,234> — thousands or decimals?). More than two
decimals are refused too (no cents).

=item IBAN

Compact and upper case: white space removed, letters upper case. The check
digits are B<not> verified — that would tell the model its reading is wrong.

=item Currency

Trimmed and upper case; C<€> becomes C<EUR>, C<£> becomes C<GBP>. Anything
else stays as given (in upper case).

=back

=head2 State

  sehen:
    type: sehen
    graph:
      roh:  { gerichtet, knoten, kanten }          # the arguments as sent
      norm:
        gerichtet:      1 | 0
        knoten:         [ text … ]                 # normalised, sorted, unique
        kanten:         [ "a -> b" … ]             # directed; undirected "a -- b" with sorted ends; sorted, unique
        beschriftungen: [ "a -> b: text" … ]       # only edges with a text; sorted, unique
    ablauf:
      roh:  { teilnehmer, nachrichten }
      norm:
        teilnehmer:  [ text … ]                    # in the order given, unique
        nachrichten: [ "von -> an: text" … ]       # in the order given; "von -> an" without text
    felder:
      roh:  { belegart, … }
      norm:
        belegart, nummer, waehrung, iban:  text or null
        datum, lieferdatum:                "YYYY-MM-DD" or null
        betrag_brutto, betrag_netto:       cents (integer) or null
        positionen: [ { text, menge?, betrag? } … ] # menge a number, betrag in cents
    tabelle:
      roh:  { kopf, zeilen }
      norm:
        kopf:        [ text … ]
        zeilen:      [ [ text … ] … ]              # null cells as ""
        zeilen_text: [ "a | b | c" … ]             # each row joined, for contains
    werte:
      roh:  { reihen }
      norm:
        reihen: { <name>: { <x>: y } }             # x a number as text or normalised text, y a number
    befund:
      roh:  { befehl, fehlercode, datei, zeile }
      norm: { befehl, fehlercode, datei: text or null, zeile: integer or null }
    meldung:                                       # from bild_melden
      roh:  { grund, notiz }
      norm: { grund, notiz }

The world starts as C<< { type: sehen } >>; each key above appears with the
first accepted call of its tool. In C<felder> and C<befund> every field may be
null (the image does not show it); a missing key counts as null. A position
may be given as a bare text. In C<graph> and C<ablauf>, an edge or message
must name a node or participant from its own list.

Rules grade C<norm> (C<sehen.felder.norm.betrag_brutto equals 11900>,
C<sehen.graph.norm.kanten contains [...]>,
C<sehen.ablauf.norm.nachrichten before [...]>,
C<sehen.werte.norm.reihen.umsatz.2023 equals 12>), and C<roh> when the exact
spelling matters.

Only the state, deterministic, neutral.

=head2 device_type

C<sehen>.

=head2 tools

  my $tools = $world->tools;   # { graph_abgeben => [qw( gerichtet knoten kanten )], … }

The tools of this world with their required parameters (for the loader).

=head2 tool

  my ( $output, $ok ) = $world->tool( $sehen, $name, \%args, $ctx );

A tool call on the state of the world (C<$sehen> is changed). A name not in
L</tools> is an error; an accepted call replaces the earlier hand-in of the
same tool, a refused one changes nothing.

=head2 norm_text

  norm_text("  Straße – „Süd“ ");   # 'strasse - "sued"'

A text normalised (see L</Normalisation>), or C<undef> for C<undef> or a
reference.

=head2 norm_date

  my ( $iso, $why ) = norm_date('3.4.2024');     # ( '2024-04-03' )
  my ( $iso, $why ) = norm_date('03/04/2024');   # ( undef, 'mehrdeutig' )

A date as ISO C<YYYY-MM-DD>, or C<undef> and why: C<mehrdeutig> (ambiguous),
C<ungültig> (no such day) or C<nicht lesbar> (not readable).

=head2 norm_amount

  my ( $cents, $why ) = norm_amount('1.234,56 €');   # ( 123456 )
  my ( $cents, $why ) = norm_amount('1.234');        # ( undef, 'mehrdeutig' )

An amount in whole cents, or C<undef> and why: C<mehrdeutig> (ambiguous) or
C<nicht lesbar> (not readable). A JSON number and a text are read alike.

=head2 norm_number

  norm_number('1,5');   # 1.5

A plain number (point or comma as decimal separator, no thousands
separators), or C<undef>.

=head2 norm_iban

  norm_iban('de89 3704 0044 0532 0130 00');   # 'DE89370400440532013000'

=head2 norm_currency

  norm_currency(' eur ');   # 'EUR'
  norm_currency('€');       # 'EUR'

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
