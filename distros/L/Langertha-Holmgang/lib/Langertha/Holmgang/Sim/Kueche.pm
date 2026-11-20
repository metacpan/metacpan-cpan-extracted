package Langertha::Holmgang::Sim::Kueche;
# ABSTRACT: The answer world kueche — recipe collection, pantry, shopping list, week plan, units

use Moose;
use namespace::autoclean;
use utf8;

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.002';


our @DAYS = qw( Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag );

# Masstabelle: Schreibweise -> [ Dimension, Faktor zur Grundeinheit ].
# Dimension g (Gewicht), ml (Raum), loeffel (g oder ml, je nach Zutat),
# sonst eine Zaehleinheit (ihr eigener Name).
our %UNIT = (
  g => [ g => 1 ], gr => [ g => 1 ], gramm => [ g => 1 ], kg => [ g => 1000 ], kilogramm => [ g => 1000 ],
  ml => [ ml => 1 ], cl => [ ml => 10 ], dl => [ ml => 100 ], l => [ ml => 1000 ], liter => [ ml => 1000 ],
  el => [ loeffel => 15 ], 'esslöffel' => [ loeffel => 15 ], 'eßlöffel' => [ loeffel => 15 ], 'eßl' => [ loeffel => 15 ],
  tl => [ loeffel => 5 ], 'teelöffel' => [ loeffel => 5 ], 'teel' => [ loeffel => 5 ],
  # englisch (nur metrisch)
  gram => [ g => 1 ], grams => [ g => 1 ], kilogram => [ g => 1000 ], kilograms => [ g => 1000 ],
  milliliter => [ ml => 1 ], milliliters => [ ml => 1 ], millilitre => [ ml => 1 ], millilitres => [ ml => 1 ],
  liters => [ ml => 1000 ], litre => [ ml => 1000 ], litres => [ ml => 1000 ],
  tbsp => [ loeffel => 15 ], tablespoon => [ loeffel => 15 ], tablespoons => [ loeffel => 15 ],
  tsp => [ loeffel => 5 ], teaspoon => [ loeffel => 5 ], teaspoons => [ loeffel => 5 ],
);

# Zaehleinheiten: Einzahl -> Mehrzahl (beide werden angenommen).
our %COUNT = (
  'Stück' => 'Stück', Dose => 'Dosen', Zehe => 'Zehen', Bund => 'Bund', Becher => 'Becher',
  Packung => 'Packungen', 'Päckchen' => 'Päckchen', Scheibe => 'Scheiben', Glas => 'Gläser',
  Stange => 'Stangen', Zweig => 'Zweige', Blatt => 'Blätter', Knolle => 'Knollen', Kopf => 'Köpfe',
  Tafel => 'Tafeln', Beutel => 'Beutel', Flasche => 'Flaschen', Würfel => 'Würfel',
  Kugel => 'Kugeln', 'Tüte' => 'Tüten', 'Tütchen' => 'Tütchen', Stiel => 'Stiele', Paket => 'Pakete',
  Rolle => 'Rollen', Laib => 'Laibe', Schote => 'Schoten', Ecke => 'Ecken', Riegel => 'Riegel',
  # englisch
  clove => 'cloves', can => 'cans', slice => 'slices', sprig => 'sprigs', piece => 'pieces',
  stalk => 'stalks', head => 'heads', bunch => 'bunches', leaf => 'leaves', package => 'packages',
  sheet => 'sheets', stick => 'sticks', jar => 'jars', bottle => 'bottles', bag => 'bags',
);

# Schreibweise (klein) -> Einzahl der Zaehleinheit
our %COUNT_OF = (
  ( map { ( lc $_ => $_, lc $COUNT{$_} => $_ ) } keys %COUNT ),
  stk => 'Stück',
  ( map { ( $_ => 'Päckchen' ) } qw( pck pkg päck ) ),
);

# Die Werkzeuge dieser Welt mit ihren Pflichtparametern (fuer den Lader).
our %TOOLS = (
  rezepte_suchen   => [],
  rezept_lesen     => ['rezept'],
  vorrat_lesen     => [],
  liste_lesen      => [],
  auf_liste_setzen => [qw( zutat menge )],
  von_liste_nehmen => ['zutat'],
  plan_lesen       => [],
  plan_setzen      => [qw( tag rezept portionen )],
);

my %VULGAR = ( '½' => 0.5, '¼' => 0.25, '¾' => 0.75, '⅓' => 1 / 3, '⅔' => 2 / 3 );

#### Plugin contract

sub device_type { 'kueche' }


sub tools { return \%TOOLS }


sub tool {
  my ( $self, $dev, $name, $args, $ctx ) = @_;
  $name //= '';
  my $code = $TOOLS{$name} && $self->can( '_t_'.$name )
    or return ( "Fehler: unbekanntes Werkzeug '".$name."'", 0 );
  return $self->$code( $dev, $args || {} );
}


#### Mengen (reine Funktionen, auch fuer Generatoren)

sub number {
  my ( $s ) = @_;
  return undef unless defined $s;
  $s =~ s/\A\s+|\s+\z//g;
  return $VULGAR{$s} if exists $VULGAR{$s};
  return $1 + $VULGAR{$2} if $s =~ /\A(\d+)\s*([½¼¾⅓⅔])\z/;
  return $2 ? $1 / $2 : undef if $s =~ m{\A(\d+)\s*/\s*(\d+)\z};
  return undef unless $s =~ /\A\d+(?:[.,]\d+)?\z/;
  $s =~ tr/,/./;
  return 0 + $s;
}


sub show_number {
  my ( $n ) = @_;
  my $s = sprintf '%.3f', $n;
  $s =~ s/\.?0+\z//;
  $s =~ tr/./,/;
  return $s;
}


sub unit_of {
  my ( $u ) = @_;
  return () unless defined $u;
  ( my $k = lc $u ) =~ s/\.\z//;
  return @{ $UNIT{$k} } if $UNIT{$k};
  return ( $COUNT_OF{$k}, 1 ) if $COUNT_OF{$k};
  return ();
}


sub parse_amount {
  my ( $text, $base ) = @_;
  $text = '' unless defined $text;
  $text = "$text";
  $text =~ s/\A\s+|\s+\z//g;
  my ( $num, $unit ) = $text =~ /\A(\d+(?:[.,]\d+)?(?:\s*\/\s*\d+)?|\d*\s*[½¼¾⅓⅔])\s*(.*)\z/;
  my $n = number($num);
  return ( undef, undef, "Menge '".$text."' nicht lesbar (z. B. \"250 g\", \"2 EL\", \"3\")" ) unless defined $n && $n > 0;
  my ( $dim, $f );
  if ( !length $unit ) { ( $dim, $f ) = ( $base && ( $base eq 'g' || $base eq 'ml' ) ? undef : ( $base // 'Stück' ), 1 ) }
  else                 { ( $dim, $f ) = unit_of($unit) }
  return ( undef, undef, "Einheit '".$unit."' unbekannt" ) unless defined $dim || !length $unit;
  return ( undef, undef, "Menge '".$text."' ohne Einheit — bitte mit Einheit angeben (in ".$base.')' ) unless defined $dim;
  $base //= $dim eq 'loeffel' ? 'g' : $dim;
  if ( $dim eq 'loeffel' ) {
    return ( undef, undef, 'Löffelmaß passt nicht zu '.$base ) unless $base eq 'g' || $base eq 'ml';
    $dim = $base;
  }
  return ( undef, undef, "Einheit '".$unit."' passt nicht — wird in ".$base.' geführt' ) unless $dim eq $base;
  return ( 0 + sprintf( '%.3f', $n * $f ), $base );
}


sub portions {
  my ( $n ) = @_;
  return !defined $n ? 'Portionen ohne Angabe' : $n == 1 ? '1 Portion' : $n.' Portionen';
}


#### Zustand

sub _canon {
  my ( $self, $dev, $name ) = @_;
  return undef unless defined $name && !ref $name;
  ( my $want = lc $name ) =~ s/\A\s+|\s+\z//g;
  my $z = $dev->{zutaten} || {};
  for my $k ( sort keys %$z ) {
    return $k if lc $k eq $want || grep { lc $_ eq $want } @{ $z->{$k}{namen} || [] };
  }
  for my $k ( sort keys %{ $dev->{liste} || {} } ) { return $k if lc $k eq $want }
  return undef;
}

# "2 Eier" oder "30 g Mehl" als Menge: der Name der Zutat am Ende faellt weg.
sub _strip_name {
  my ( $self, $dev, $z, $menge ) = @_;
  return $menge unless defined $menge && !ref $menge;
  my $known = $self->_zutat( $dev, $z );
  for my $n ( sort { length $b <=> length $a } $z, @{ $known ? $known->{namen} || [] : [] } ) {
    return $1 if $menge =~ /\A(.*?\S)\s+\Q$n\E\s*\z/i;
  }
  return $menge;
}

# lesen, ohne den Zustand anzulegen: ein Lesebefehl aendert nichts
sub _zutat {
  my ( $self, $dev, $z ) = @_;
  my $all = $dev->{zutaten};
  return ref $all eq 'HASH' && defined $z ? $all->{$z} : undef;
}

sub _base {
  my ( $self, $dev, $z ) = @_;
  my $e = $self->_zutat( $dev, $z );
  return ref $e eq 'HASH' ? $e->{einheit} : undef;
}

sub _show_amount {
  my ( $self, $dev, $z, $n ) = @_;
  my $u = $self->_base( $dev, $z ) // 'Stück';
  $u = $COUNT{$u} if $COUNT{$u} && $n != 1;
  return show_number($n).' '.$u;
}

sub _recipe {
  my ( $self, $dev, $ref ) = @_;
  my $r = $dev->{rezepte} || {};
  return undef unless defined $ref && !ref $ref;
  ( my $want = lc $ref ) =~ s/\A\s+|\s+\z//g;
  return $want if $r->{$want};
  my @hit = grep { lc( $r->{$_}{titel} // '' ) eq $want } sort keys %$r;
  return @hit == 1 ? $hit[0] : undef;
}

sub _veg {
  my ( $self, $v ) = @_;
  return { vegan => 'vegan', ja => 'vegetarisch', nein => 'nicht vegetarisch' }->{ $v // '' } // 'unbekannt';
}

sub _zeit {
  my ( $self, $z ) = @_;
  return defined $z ? $z.' min' : 'keine Angabe';
}

sub _list_text {
  my ( $self, $dev, $h, $empty ) = @_;
  my @k = sort { lc $a cmp lc $b } grep { $h->{$_} } keys %{ $h || {} };
  return $empty unless @k;
  return join "\n", map { '- '.$_.': '.( $h->{$_} =~ /\A\d/ ? $self->_show_amount( $dev, $_, $h->{$_} ) : $h->{$_} ) } @k;
}

#### Werkzeuge

sub _t_rezepte_suchen {
  my ( $self, $dev, $p ) = @_;
  my $q = lc( $p->{suchbegriff} // '' );
  $q =~ s/\A\s+|\s+\z//g;
  my $r = $dev->{rezepte} || {};
  my @ids = grep {
    my $x = $r->{$_};
    !length $q || index( lc $x->{titel}, $q ) >= 0 || grep { index( lc $_->{zutat}, $q ) >= 0 } @{ $x->{zutaten} || [] };
  } sort { lc $r->{$a}{titel} cmp lc $r->{$b}{titel} || $a cmp $b } keys %$r;
  return ( 'Keine Rezepte gefunden.', 1 ) unless @ids;
  return ( join( "\n", scalar(@ids).' Rezepte:', map {
    my $x = $r->{$_};
    '- '.$_.': '.$x->{titel}.' ('.portions( $x->{portionen} ).', '.$self->_zeit( $x->{zeit} ).', '.$self->_veg( $x->{vegetarisch} ).')';
  } @ids ), 1 );
}

sub _t_rezept_lesen {
  my ( $self, $dev, $p ) = @_;
  my $id = $self->_recipe( $dev, $p->{rezept} )
    or return ( "Rezept '".( $p->{rezept} // '' )."' nicht gefunden.", 0 );
  my $x = $dev->{rezepte}{$id};
  my @l = (
    $x->{titel}.' (ID '.$id.')',
    'Portionen: '.( $x->{portionen} // 'keine Angabe' ),
    'Zubereitungszeit: '.$self->_zeit( $x->{zeit} ),
    'Vegetarisch: '.$self->_veg( $x->{vegetarisch} ),
    'Zutaten:',
  );
  push @l, map { '- '.$_->{text} } @{ $x->{zutaten} || [] };
  push @l, 'Quelle: '.$x->{quelle} if $x->{quelle};
  return ( join( "\n", @l ), 1 );
}

sub _t_vorrat_lesen {
  my ( $self, $dev ) = @_;
  return ( $self->_list_text( $dev, $dev->{vorrat}, 'Der Vorrat ist leer.' ), 1 );
}

sub _t_liste_lesen {
  my ( $self, $dev ) = @_;
  return ( $self->_list_text( $dev, $dev->{liste}, 'Die Einkaufsliste ist leer.' ), 1 );
}

sub _t_auf_liste_setzen {
  my ( $self, $dev, $p ) = @_;
  my $name = $p->{zutat} // '';
  $name =~ s/\A\s+|\s+\z//g;
  return ( 'Fehler: Zutat fehlt.', 0 ) unless length $name;
  my $z = $self->_canon( $dev, $name );
  my ( $n, $base, $err ) = parse_amount( $self->_strip_name( $dev, $z // $name, $p->{menge} ), $z ? $self->_base( $dev, $z ) : undef );
  return ( 'Fehler: '.$err.'.', 0 ) if $err;
  if ( !$z ) {
    $z = $name;
    $dev->{zutaten}{$z} = { einheit => $base } unless $dev->{zutaten}{$z};
  }
  $dev->{liste}{$z} = 0 + sprintf '%.3f', ( $dev->{liste}{$z} // 0 ) + $n;
  return ( 'Auf der Liste: '.$z.' '.$self->_show_amount( $dev, $z, $dev->{liste}{$z} ), 1 );
}

sub _t_von_liste_nehmen {
  my ( $self, $dev, $p ) = @_;
  my $z = $self->_canon( $dev, $p->{zutat} );
  return ( "Fehler: '".( $p->{zutat} // '' )."' steht nicht auf der Liste.", 0 ) unless $z && $dev->{liste} && $dev->{liste}{$z};
  if ( !defined $p->{menge} || $p->{menge} eq '' ) {
    delete $dev->{liste}{$z};
    return ( $z.' von der Liste gestrichen.', 1 );
  }
  my ( $n, undef, $err ) = parse_amount( $self->_strip_name( $dev, $z, $p->{menge} ), $self->_base( $dev, $z ) );
  return ( 'Fehler: '.$err.'.', 0 ) if $err;
  my $left = 0 + sprintf '%.3f', $dev->{liste}{$z} - $n;
  return ( 'Fehler: auf der Liste stehen nur '.$self->_show_amount( $dev, $z, $dev->{liste}{$z} ).'.', 0 ) if $left < 0;
  if ( $left == 0 ) {
    delete $dev->{liste}{$z};
    return ( $z.' von der Liste gestrichen.', 1 );
  }
  $dev->{liste}{$z} = $left;
  return ( 'Auf der Liste: '.$z.' '.$self->_show_amount( $dev, $z, $left ), 1 );
}

sub _t_plan_lesen {
  my ( $self, $dev ) = @_;
  my $p = $dev->{plan} || {};
  my $r = $dev->{rezepte} || {};
  my @l = map {
    my $e = $p->{$_};
    $e ? '- '.$_.': '.( ( $r->{ $e->{rezept} } || {} )->{titel} // $e->{rezept} ).' (ID '.$e->{rezept}.'), '.portions( $e->{portionen} ) : ();
  } @DAYS;
  return ( @l ? join( "\n", @l ) : 'Der Wochenplan ist leer.', 1 );
}

sub _t_plan_setzen {
  my ( $self, $dev, $p ) = @_;
  my ($tag) = grep { lc $_ eq lc( $p->{tag} // '' ) } @DAYS;
  return ( 'Fehler: Tag '.join( ', ', @DAYS ).'.', 0 ) unless $tag;
  my $id = $self->_recipe( $dev, $p->{rezept} )
    or return ( "Fehler: Rezept '".( $p->{rezept} // '' )."' nicht gefunden.", 0 );
  my $por = $p->{portionen} // '';
  my ($n) = "$por" =~ /\A\s*([1-9]\d{0,2})\s*\z/
    or return ( 'Fehler: Portionen als ganze Zahl ab 1.', 0 );
  $dev->{plan}{$tag} = { rezept => $id, portionen => 0 + $n };
  return ( $tag.': '.$dev->{rezepte}{$id}{titel}.', '.portions($n).'.', 1 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Kueche - The answer world kueche — recipe collection, pantry, shopping list, week plan, units

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # suite.yaml: every tool names the world, the tool's name picks what it does
  tools:
    - { name: auf_liste_setzen, simulator: kueche, description: …, parameters: { … } }

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok ) = $sims->tool_call( $state, kueche => auf_liste_setzen => { zutat => 'Mehl', menge => '2 EL' } );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<kueche>): a kitchen with a B<recipe collection>, B<pantry>, B<shopping
list> and B<week plan>. The tools are general and the same for every case; no
name gives away a fault. Tool names, parameters and world keys are German,
as the model sees them:

  rezepte_suchen   { suchbegriff? }                 search titles and ingredients
  rezept_lesen     { rezept }                       one recipe (ID or exact title)
  vorrat_lesen     { }                              what is in the pantry
  liste_lesen      { }                              the shopping list
  auf_liste_setzen { zutat, menge }                 add an amount to the list (adds up)
  von_liste_nehmen { zutat, menge? }                subtract an amount; without one, strike it entirely
  plan_lesen       { }                              the week plan
  plan_setzen      { tag, rezept, portionen }       set a dish for one day

=head2 Units

The tools take amounts in any form the B<measure table> knows (C<"2 EL">,
C<"30 g">, C<"0,5 l">, C<"3">, C<"2 Dosen">). The world converts them into the
B<base unit of the ingredient> (weight C<g>, volume C<ml> or a count unit such
as C<Stück>, C<Dose>, C<Zehe>), so grading compares only numbers. Spoons are
kitchen measures: 1 EL (tablespoon) = 15 g or 15 ml, 1 TL (teaspoon) = 5 g or
5 ml. Weight and volume are never converted into each other; what does not
fit, the tool refuses like a scale would („Mehl wird in g geführt", flour is
kept in g).

Vague amounts (Prise, etwas, nach Belieben, ranges — a pinch, some, to taste)
are not in the table; a generator makes no cases from them.

=head2 State

  kueche:
    type: kueche
    zutaten: { Ei: { einheit: Stück, namen: [Eier] }, Mehl: { einheit: g } }
    rezepte: { apfelkuchen: { titel, portionen, zeit, vegetarisch, nuesse, zutaten: [ { zutat, menge, text } ], quelle } }
    vorrat:  { Mehl: 1000, Salz: vorhanden }   # base unit of the ingredient; without an amount: text
    liste:   { Ei: 2 }               # base unit of the ingredient
    plan:    { Montag: { rezept: apfelkuchen, portionen: 4 } }

C<zutaten> (ingredients) gives each ingredient its base unit (C<einheit>) and
further names the tools accept it under (C<namen>, e.g. the plural).
C<rezepte> (recipes) is the collection by ID: C<vegetarisch> is C<ja>,
C<vegan> or C<nein>, C<zeit> the preparation time in minutes; the tools do not
read C<nuesse> (nuts; for a case's rules). C<menge> (amount) in a recipe line
is in the ingredient's base unit, C<text> is the line as the recipe writes it;
a line without an amount (Salz, „1 Prise Zucker") has no C<menge>, and its
ingredient is in the pantry (C<vorrat>) as C<vorhanden> (present).

An ingredient not listed in C<zutaten> goes on the list (C<liste>) with the
base unit of its amount; C<auf_liste_setzen> then enters it into C<zutaten>
with that C<einheit>.

Only the state, deterministic, neutral.

=head2 device_type

C<kueche>.

=head2 tools

  my $tools = $world->tools;   # { auf_liste_setzen => [qw( zutat menge )], … }

The tools of this world with their required parameters (for the loader).

=head2 tool

  my ( $output, $ok ) = $world->tool( $kueche, $name, \%args, $ctx );

A tool call on the state of the kitchen (C<$kueche> is changed). A name not
in L</tools> is an error.

=head2 number

  number('1,5');   # 1.5
  number('1/2');   # 0.5

A number as recipes write it (comma or point, simple fraction, C<½>), or
C<undef>.

=head2 show_number

  show_number(1.5);   # "1,5"

=head2 unit_of

  my ( $dim, $factor ) = unit_of('EL');     # ( 'loeffel', 15 )
  my ( $dim, $factor ) = unit_of('Dosen');  # ( 'Dose', 1 )

A unit from the measure table, or empty.

=head2 parse_amount

  my ( $value, $unit, $error ) = parse_amount( '2 EL', 'g' );   # ( 30, 'g' )

Reads an amount and converts it into the base unit C<$base> (C<g>, C<ml> or
a count unit; without C<$base> the natural base unit of the amount). Errors
as text.

=head2 portions

  portions(1);   # "1 Portion"

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
