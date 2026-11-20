package Langertha::Holmgang::Sim::Denken;
# ABSTRACT: The answer world denken — reasoning tasks, the answer handed in by tool, one checker per task like score_answer of Reasoning Gym

use Moose;
use namespace::autoclean;
use utf8;
use B ();
use JSON::MaybeXS ();
use Math::BigInt ();
use Math::BigRat ();

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.002';


our %TOOLS = ( antwort_abgeben => ['antwort'] );

my %CHECK = (
  zebra_puzzles        => \&_zebra,
  knights_knaves       => \&_knights,
  propositional_logic  => \&_proplogic,
  syllogism            => \&_exact,
  course_schedule      => \&_exact,
  maze                 => \&_exact,
  self_reference       => \&_exact,
  shortest_path        => \&_shortest_path,
  graph_color          => \&_graph_color,
  calendar_arithmetic  => \&_calendar,
  time_intervals       => \&_time_intervals,
  cryptarithm          => \&_cryptarithm,
  mini_sudoku          => \&_mini_sudoku,
  family_relationships => \&_family,
  countdown            => \&_countdown,
  jugs                 => \&_jugs,
);

# Pflichtfelder von pruefung je Aufgabe
my %NEED = (
  propositional_logic => [qw( premissen variablen )],
  shortest_path       => [qw( antwort matrix )],
  graph_color         => [qw( knoten kanten farben )],
  calendar_arithmetic => [qw( antwort form )],
  time_intervals      => [qw( antwort form )],
  cryptarithm         => [qw( woerter ergebnis )],
  countdown           => [qw( zahlen ziel )],
  jugs                => [qw( kruege ziel )],
);

#### Plugin contract

sub device_type { 'denken' }


sub tools { return \%TOOLS }


sub prepare {
  my ( $self, $dev, $ctx ) = @_;
  my $art = $dev->{art} // '';
  die "denken: unbekannte Aufgabe '$art' (" . join( ', ', arten() ) . ")\n" unless $CHECK{$art};
  my $p = $dev->{pruefung};
  die "denken: pruefung fehlt (Hash)\n" unless ref $p eq 'HASH';
  for my $k ( @{ $NEED{$art} || ['antwort'] } ) {
    die "denken: pruefung.$k fehlt ($art)\n" unless defined $p->{$k};
  }
  return;
}


sub tool {
  my ( $self, $dev, $name, $args, $ctx ) = @_;
  return ( "Fehler: unbekanntes Werkzeug '" . ( $name // '' ) . "'", 0 ) unless ( $name // '' ) eq 'antwort_abgeben';
  my $ans = ( $args || {} )->{antwort};
  return ( 'Fehler: antwort fehlt (Text).', 0 ) unless defined $ans && !ref $ans;
  my ( $ok, $why ) = pruefe( $dev->{art}, $dev->{pruefung}, "$ans" );
  $dev->{antwort}  = "$ans";
  $dev->{abgaben}  = ( $dev->{abgaben} // 0 ) + 1;
  $dev->{ergebnis} = $ok ? 'richtig' : 'falsch';
  $dev->{befund}   = $why;
  return ( 'Antwort gespeichert.', 1 );
}


#### Pruefer (reine Funktionen)

sub arten { return sort keys %CHECK }


sub pruefe {
  my ( $art, $p, $answer ) = @_;
  my $code = $CHECK{ $art // '' } or return ( 0, 'unbekannte Aufgabe' );
  return ( 0, 'keine Antwort' ) unless defined $answer && !ref $answer;
  my @r = eval { $code->( $p || {}, $answer ) };
  return ( 0, 'nicht auswertbar: ' . ( "$@" =~ s/\s+\z//r ) ) unless @r;
  return ( $r[0] ? 1 : 0, $r[1] // ( $r[0] ? 'richtig' : 'falsch' ) );
}


# --- Hilfen wie Python --------------------------------------------------------

sub _strip { my ($s) = @_; $s =~ s/\A\s+|\s+\z//g; return $s }

# int(text) wie Python: Leerraum aussen, Vorzeichen, Ziffern mit einzelnen _
sub _pyint {
  my ($s) = @_;
  return undef unless defined $s;
  $s = _strip($s);
  return undef unless $s =~ /\A([+-]?)(\d+(?:_\d+)*)\z/a;
  my ( $sign, $d ) = ( $1, $2 =~ tr/_//dr );
  $d =~ s/\A0+(?=\d)//;
  return $sign eq '-' && $d ne '0' ? "-$d" : $d;
}

sub _fail { return ( 0, $_[0] ) }

# --- Prüfer -----------------------------------------------------------------

sub _exact {
  my ( $p, $ans ) = @_;
  return $ans eq "$p->{antwort}" ? ( 1, 'gleich' ) : _fail('nicht gleich');
}

sub _zebra {
  my ( $p, $ans ) = @_;
  my $norm = sub { lc( $_[0] =~ s/\n//gr ) };
  return $norm->($ans) eq $norm->( $p->{antwort} ) ? ( 1, 'gleich' ) : _fail('nicht gleich');
}

sub _family {
  my ( $p, $ans ) = @_;
  return lc( _strip($ans) ) eq lc( _strip( $p->{antwort} ) ) ? ( 1, 'gleich' ) : _fail('nicht gleich');
}

my %ROLES = map { $_ => 1 }
  qw( knight sinner fool pioneer laggard hero sage villain egoist angel altruist saint devil knave );

sub _kk_pairs {
  my ($s) = @_;
  $s = _strip( lc $s );
  $s =~ tr/.,)(/    /;
  $s =~ s/ and / /g;
  my ( %set, $name );
  for my $w ( split ' ', $s ) {
    next if $w eq 'is' || $w eq 'a' || $w eq 'an';
    if ( $ROLES{$w} ) {
      $set{"$name\0$w"} = 1 if defined $name;
      undef $name;
    }
    else { $name = $w }
  }
  return join "\n", sort keys %set;
}

sub _knights {
  my ( $p, $ans ) = @_;
  return _fail('leer') unless length $ans;
  return _kk_pairs($ans) eq _kk_pairs( $p->{antwort} ) ? ( 1, 'Zuordnung gleich' ) : _fail('Zuordnung anders');
}

# Aussagenlogik: Parser wie parse_expr in reasoning_gym/logic/propositional_logic.py
my @PL_LEVELS = ( '↔', '→', '∨', '∧' );

sub _pl_parse {
  my ( $e, $depth ) = @_;
  die "zu tief verschachtelt\n" if ( $depth // 0 ) > 400;
  $depth = ( $depth // 0 ) + 1;
  $e = _strip($e);
  die "leerer Ausdruck\n" unless length $e;
  if ( substr( $e, 0, 1 ) eq '(' && substr( $e, -1 ) eq ')' ) {
    my ( $level, $valid ) = ( 0, 1 );
    for my $ch ( split //, substr( $e, 1, length($e) - 2 ) ) {
      if ( $ch eq '(' ) { $level++ }
      elsif ( $ch eq ')' ) { $level--; if ( $level < 0 ) { $valid = 0; last } }
    }
    return _pl_parse( substr( $e, 1, length($e) - 2 ), $depth ) if $level == 0 && $valid;
  }
  for my $op (@PL_LEVELS) {
    my $level = 0;
    for ( my $i = length($e) - 1; $i >= 0; $i-- ) {
      my $ch = substr( $e, $i, 1 );
      if    ( $ch eq ')' ) { $level++ }
      elsif ( $ch eq '(' ) { $level-- }
      elsif ( $level == 0 && $ch eq $op ) {
        return [ $op, _pl_parse( substr( $e, 0, $i ), $depth ), _pl_parse( substr( $e, $i + 1 ), $depth ) ];
      }
    }
  }
  return [ '¬', _pl_parse( substr( $e, 1 ), $depth ) ] if substr( $e, 0, 1 ) eq '¬';
  return [ var => $e ];
}

sub _pl_vars {
  my ( $x, $acc ) = @_;
  if ( $x->[0] eq 'var' ) { $acc->{ $x->[1] } = 1 }
  else { _pl_vars( $_, $acc ) for @{$x}[ 1 .. $#$x ] }
  return $acc;
}

sub _pl_eval {
  my ( $x, $v ) = @_;
  my $op = $x->[0];
  return $v->{ $x->[1] } if $op eq 'var';
  return !_pl_eval( $x->[1], $v ) if $op eq '¬';
  my ( $l, $r ) = ( _pl_eval( $x->[1], $v ), _pl_eval( $x->[2], $v ) );
  return $op eq '∧' ? $l && $r : $op eq '∨' ? $l || $r : $op eq '→' ? !$l || $r : ( $l ? 1 : 0 ) == ( $r ? 1 : 0 );
}

sub _pl_assignments {
  my (@vars) = sort @_;
  die "zu viele Atome\n" if @vars > 16;
  return map { my $i = $_; +{ map { ( $vars[$_] => ( $i >> $_ ) & 1 ) } 0 .. $#vars } } 0 .. 2**@vars - 1;
}

sub _proplogic {
  my ( $p, $ans ) = @_;
  my %valid = map { $_ => 1 } @{ $p->{variablen} };
  my ($bad) = grep { !$valid{$_} } $ans =~ /([A-Z])/g;
  return _fail("Atom $bad kommt in der Aufgabe nicht vor") if defined $bad;
  my @prem = map { _pl_parse($_) } @{ $p->{premissen} };
  my $c = eval { _pl_parse($ans) } or return _fail( 'nicht lesbar: ' . ( "$@" =~ s/\s+\z//r ) );
  my %all;
  _pl_vars( $_, \%all ) for @prem, $c;
  for my $v ( _pl_assignments( keys %all ) ) {
    return _fail('folgt nicht aus den Prämissen') if !( grep { !_pl_eval( $_, $v ) } @prem ) && !_pl_eval( $c, $v );
  }
  return _fail('trivial (einzelnes Atom)') if $c->[0] eq 'var';
  my $own = _pl_vars( $c, {} );
  return _fail('trivial (Tautologie)') unless grep { !_pl_eval( $c, $_ ) } _pl_assignments( keys %$own );
  return ( 1, 'folgt und ist nicht trivial' );
}

my %DIR = ( right => [ 0, 1 ], down => [ 1, 0 ], left => [ 0, -1 ], up => [ -1, 0 ] );

sub _shortest_path {
  my ( $p, $ans ) = @_;
  return _fail('leer') unless length $ans;
  my $oracle = _strip( $p->{antwort} );
  return ( 1, 'gleich' ) if _strip($ans) eq $oracle;
  my @path = split ' ', $ans;
  my @want = split ' ', $oracle;
  my $m = $p->{matrix};
  my ( $rows, $cols ) = ( scalar @$m, scalar @{ $m->[0] } );
  my ( @start, @goal );
  for my $r ( 0 .. $rows - 1 ) {
    for my $c ( 0 .. $cols - 1 ) {
      @start = ( $r, $c ) if !@start && $m->[$r][$c] eq '*';
      @goal  = ( $r, $c ) if !@goal  && $m->[$r][$c] eq '#';
    }
  }
  my ( $r, $c ) = @start;
  for my $d (@path) {
    my $step = $DIR{$d} or return _fail("keine Richtung: $d");
    ( $r, $c ) = ( $r + $step->[0], $c + $step->[1] );
    return _fail('verlässt das Gitter') unless $r >= 0 && $r < $rows && $c >= 0 && $c < $cols;
    return _fail('läuft durch X') if $m->[$r][$c] eq 'X';
  }
  return _fail('endet nicht am Ziel') unless $r == $goal[0] && $c == $goal[1];
  return @path == @want ? ( 1, 'gültiger kürzester Weg' ) : _fail( 'gültig, aber ' . scalar(@path) . ' statt ' . scalar(@want) . ' Schritte' );
}

my $JSON = JSON::MaybeXS->new( utf8 => 0, allow_nonref => 1 );

# Zahl aus JSON (keine Zeichenkette); Wahrheitswerte wie in Python 1/0
sub _json_num {
  my ($v) = @_;
  return undef unless defined $v;
  if ( ref $v ) {
    return JSON::MaybeXS::is_bool($v) ? ( $v ? 1 : 0 ) : undef;
  }
  my $f = B::svref_2object( \$v )->FLAGS;
  return undef if $f & B::SVf_POK && !( $f & ( B::SVf_IOK | B::SVf_NOK ) );
  return undef if $f & B::SVf_POK && $v !~ /\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/;
  return 0 + $v;
}

sub _graph_color {
  my ( $p, $ans ) = @_;
  my $col = eval { $JSON->decode($ans) };
  return _fail('kein JSON') if $@;
  my $get;
  if ( ref $col eq 'HASH' ) {
    $get = sub { exists $col->{"$_[0]"} ? ( 1, $col->{"$_[0]"} ) : (0) };
  }
  elsif ( ref $col eq 'ARRAY' ) {
    # Python: `knoten in liste` vergleicht Werte, dann liste[knoten]
    $get = sub {
      my $v = shift;
      return (0) unless grep { defined && $_ == $v } map { _json_num($_) } @$col;
      die "Index $v ausserhalb der Liste\n" if $v > $#$col;
      return ( 1, $col->[$v] );
    };
  }
  else { return _fail('kein JSON-Objekt') }
  my %allowed = map { $_ => 1 } @{ $p->{farben} };
  my %c;
  for my $v ( @{ $p->{knoten} } ) {
    my ( $has, $val ) = $get->($v);
    return _fail("Knoten $v ohne Farbe") unless $has;
    $c{$v} = $val;
  }
  for my $v ( @{ $p->{knoten} } ) {
    my $n = _json_num( $c{$v} );
    return _fail("Knoten $v mit unerlaubter Farbe") unless defined $n && grep { $_ == $n } keys %allowed;
    $c{$v} = $n;
  }
  for my $e ( @{ $p->{kanten} } ) {
    my ( $u, $v ) = @$e;
    return _fail("Kante $u-$v gleich gefärbt") if $c{$u} == $c{$v};
  }
  return ( 1, 'gültige Färbung' );
}

my %WEEKDAY_TASK = map { $_ => 1 } qw( weekday_offset weekday_of_date weekday_of_date_from_first_date );
my %NUMBER_TASK  = map { $_ => 1 } qw( count_business_days count_days recurring_event_day );

sub _calendar {
  my ( $p, $ans ) = @_;
  return _fail('leer') unless length $ans;
  my ( $form, $o ) = ( $p->{form}, "$p->{antwort}" );
  if ( $WEEKDAY_TASK{$form} ) {
    return _strip($ans) eq $o ? ( 1, 'gleich' ) : _fail('anderer Wochentag oder Form');
  }
  if ( $NUMBER_TASK{$form} ) {
    my ( $x, $y ) = ( _pyint($ans), _pyint($o) );
    return _fail('keine ganze Zahl') unless defined $x && defined $y;
    return $x eq $y ? ( 1, 'gleiche Zahl' ) : _fail('andere Zahl');
  }
  if ( $form eq 'is_leap_year' ) {
    return lc( _strip($ans) ) eq lc($o) ? ( 1, 'gleich' ) : _fail('nicht gleich');
  }
  return _fail("unbekannte Form $form");
}

sub _need_int { my $v = _pyint( $_[0] ); die "keine ganze Zahl\n" unless defined $v; return 0 + $v }

sub _parse_time {
  my ($t) = @_;
  my @parts = split /:/, _strip($t), -1;
  die "Zeit ohne Minuten\n" unless @parts >= 2;
  my $s = _need_int( $parts[0] ) * 3600 + _need_int( $parts[1] ) * 60;
  if ( @parts > 2 ) {
    if ( index( $parts[2], '.' ) >= 0 ) {
      my @q = split /\./, $parts[2], -1;
      die "Sekunden mit mehr als einem Punkt\n" unless @q == 2;
      $s += _need_int( $q[0] ) + _need_int( $q[1] ) / 1000;
    }
    else { $s += _need_int( $parts[2] ) }
  }
  return $s;
}

sub _parse_datetime {
  my ($t) = @_;
  my $days = _need_int( ( split /\Q days,\E/, $t, -1 )[0] );
  my @c = split /,/, $t, -1;
  die "ohne Komma\n" unless @c > 1;
  my @parts = split /:/, _strip( $c[1] ), -1;
  die "Zeit ohne Minuten\n" unless @parts >= 2;
  my $s = _need_int( $parts[0] ) * 3600 + _need_int( $parts[1] ) * 60;
  $s += _need_int( $parts[2] ) if @parts > 2;
  return $days * 86400 + $s;
}

sub _time_intervals {
  my ( $p, $ans ) = @_;
  my ( $form, $o ) = ( $p->{form}, "$p->{antwort}" );
  my ( $x, $y );
  if ( $form eq 'date' ) {
    my $first = sub { my @w = split ' ', _strip( $_[0] ); die "leer\n" unless @w; _need_int( $w[0] ) };
    ( $x, $y ) = ( $first->($ans), $first->($o) );
  }
  elsif ( $form =~ /\Atime/ ) { ( $x, $y ) = ( _parse_time($ans), _parse_time($o) ) }
  else                        { ( $x, $y ) = ( _parse_datetime($ans), _parse_datetime($o) ) }
  return $x == $y ? ( 1, 'gleiche Dauer' ) : _fail( 'andere Dauer (' . ( $x - $y ) . ')' );
}

sub _cryptarithm {
  my ( $p, $ans ) = @_;
  my %map;
  for my $pair ( split /,/, $ans, -1 ) {
    my @lr = split /=/, _strip($pair), -1;
    @lr = ('') unless @lr;
    return _fail("nicht lesbar: '$pair'") unless @lr == 2;
    my $d = _pyint( $lr[1] );
    return _fail("keine Zahl: '$lr[1]'") unless defined $d;
    $map{ _strip( $lr[0] ) } = 0 + $d;
  }
  my @words = @{ $p->{woerter} };
  my $res   = $p->{ergebnis};
  my %need  = map { $_ => 1 } map { split // } @words, $res;
  for ( sort keys %need ) { return _fail("Buchstabe $_ fehlt") unless exists $map{$_} }
  for ( sort keys %map )  { return _fail("Buchstabe $_ zu viel") unless $need{$_} }
  for ( sort keys %map )  { return _fail("Ziffer für $_ ungültig") unless $map{$_} >= 0 && $map{$_} <= 9 }
  my %seen;
  return _fail('Ziffer doppelt') if grep { $seen{$_}++ } values %map;
  unless ( $p->{fuehrende_null} ) {
    for my $w ( @words, $res ) {
      return _fail( 'führende Null bei ' . substr( $w, 0, 1 ) ) if length $w && $map{ substr( $w, 0, 1 ) } == 0;
    }
  }
  my $num = sub { Math::BigInt->new( join '', map { $map{$_} } split //, $_[0] ) };
  my $sum = Math::BigInt->new(0);
  $sum += $num->($_) for @words;
  return $sum == $num->($res) ? ( 1, 'Gleichung stimmt' ) : _fail('Summe stimmt nicht');
}

sub _mini_sudoku {
  my ( $p, $ans ) = @_;
  return _fail('leer') unless length $ans;
  my $o = "$p->{antwort}";
  my $norm = sub { join "\n", map { s/\s+\z//r } split /\n/, $_[0], -1 };
  return _fail('anderes Gitter oder andere Form') unless $norm->($ans) eq $norm->($o);
  return _fail('länger als die Lösung') if length $ans > length $o;
  return ( 1, 'gleich' );
}

sub _jugs {
  my ( $p, $ans ) = @_;
  my $moves = eval { $JSON->decode($ans) };
  return _fail('kein JSON') if $@;
  return _fail('keine Liste von Zügen') unless ref $moves eq 'ARRAY';
  my @cap = @{ $p->{kruege} };
  my %idx = map { ( chr( 65 + $_ ) => $_ ) } 0 .. $#cap;
  my @s = (0) x @cap;
  for my $m (@$moves) {
    return _fail('Zug ist kein Text') if !defined $m || ref $m;
    my @t = split ' ', $m;
    return _fail('leerer Zug') unless @t;
    if ( $t[0] eq 'fill' || $t[0] eq 'empty' ) {
      return _fail("unbekannter Krug in '$m'") unless defined $t[1] && exists $idx{ $t[1] };
      $s[ $idx{ $t[1] } ] = $t[0] eq 'fill' ? $cap[ $idx{ $t[1] } ] : 0;
    }
    elsif ( $t[0] eq 'pour' ) {
      return _fail("unvollständig: '$m'") unless defined $t[1];
      my @xy = split /->/, $t[1], -1;
      return _fail("Form X->Y erwartet: '$m'") unless @xy == 2 && exists $idx{ $xy[0] } && exists $idx{ $xy[1] };
      my ( $i, $j ) = @idx{@xy};
      my $amt = $s[$i] < $cap[$j] - $s[$j] ? $s[$i] : $cap[$j] - $s[$j];
      $s[$i] -= $amt;
      $s[$j] += $amt;
    }
    else { return _fail("unbekannter Zug '$m'") }
  }
  return ( grep { $_ == $p->{ziel} } @s ) ? ( 1, "Ziel erreicht (@s)" ) : _fail("Ziel nicht erreicht (@s)");
}

# --- Countdown: arithmetischer Ausdruck wie Python (Präzedenz, // % **, n!) ---

sub _cd_tokens {
  my ($s) = @_;
  my ( @t, $depth );
  $depth = 0;
  pos($s) = 0;
  while ( pos($s) < length $s ) {
    if ( $s =~ /\G([ \t\f]+|\n)/gc ) {
      die "Zeilenumbruch ausserhalb von Klammern\n" if $1 eq "\n" && !$depth;
      next;
    }
    if ( $s =~ /\G(\d[\d_]*(?:\.[\d_]*)?(?:[eE][+-]?\d[\d_]*)?|\.\d[\d_]*(?:[eE][+-]?\d[\d_]*)?)/agc ) {
      push @t, [ num => $1 ];
      next;
    }
    if ( $s =~ m{\G(\*\*|//|[-+*/%()!])}gc ) {
      $depth++ if $1 eq '(';
      $depth-- if $1 eq ')';
      push @t, [ op => $1 ];
      next;
    }
    die "Zeichen nicht erlaubt\n";
  }
  return \@t;
}

sub _cd_number {
  my ($lit) = @_;
  my $d = qr/\d(?:_?\d)*/a;
  if ( $lit =~ /\A$d\z/ ) {
    die "führende Null\n" if $lit =~ /\A0/ && $lit =~ /[1-9]/;
    return Math::BigRat->new( $lit =~ tr/_//dr );
  }
  die "Zahl nicht lesbar\n" unless $lit =~ /\A(?:$d)?(?:\.(?:$d)?)?(?:[eE][+-]?$d)?\z/ && $lit =~ /\d/;
  ( my $x = $lit ) =~ tr/_//d;
  my ( $mant, $exp ) = split /[eE]/, $x;
  $mant = "0$mant" if $mant =~ /\A\./;
  $mant .= '0'     if $mant =~ /\.\z/;
  my ( $i, $f ) = split /\./, $mant;
  $f //= '';
  my $r = Math::BigRat->new( ( $i . $f ) =~ s/\A0+(?=\d)//r ) / Math::BigRat->new( '1' . ( '0' x length $f ) );
  $exp //= 0;
  die "Exponent zu gross\n" if abs($exp) > 400;
  $r *= Math::BigRat->new(10)**$exp if $exp > 0;
  $r /= Math::BigRat->new(10)**( -$exp ) if $exp < 0;
  return $r;
}

sub _cd_parse {
  my ($t) = @_;
  my $i = 0;
  my $peek = sub { $i < @$t && $t->[$i][0] eq 'op' ? $t->[$i][1] : '' };
  my ( $expr, $term, $factor, $power, $atom );
  $expr = sub {
    my $v = $term->();
    while ( ( my $op = $peek->() ) =~ /\A[-+]\z/ ) {
      $i++;
      my $r = $term->();
      $v = $op eq '+' ? $v + $r : $v - $r;
    }
    return $v;
  };
  $term = sub {
    my $v = $factor->();
    while ( ( my $op = $peek->() ) =~ m{\A(?:\*|/|//|%)\z} ) {
      $i++;
      my $r = $factor->();
      if ( $op eq '*' ) { $v = $v * $r; next }
      die "Division durch null\n" if $r->is_zero;
      if    ( $op eq '/' )  { $v = $v / $r }
      elsif ( $op eq '//' ) { $v = ( $v / $r )->bfloor }
      else                  { $v = $v - $r * ( $v / $r )->bfloor }
    }
    return $v;
  };
  $factor = sub {
    my $op = $peek->();
    if ( $op eq '-' || $op eq '+' ) { $i++; my $v = $factor->(); return $op eq '-' ? -$v : $v }
    return $power->();
  };
  $power = sub {
    my $v = $atom->();
    if ( $peek->() eq '**' ) {
      $i++;
      my $e = $factor->();
      die "Exponent nicht ganzzahlig\n" unless $e->is_int;
      die "Exponent zu gross\n" if abs($e) > 64;
      die "0 hoch negativ\n" if $v->is_zero && $e < 0;
      $v = $e < 0 ? Math::BigRat->new(1) / ( $v->copy**( -$e ) ) : $v->copy**$e;
    }
    return $v;
  };
  $atom = sub {
    die "Ausdruck endet zu früh\n" unless $i < @$t;
    my $tok = $t->[ $i++ ];
    my $v;
    if ( $tok->[0] eq 'num' ) {
      $v = _cd_number( $tok->[1] );
      if ( $peek->() eq '!' ) {
        $i++;
        die "Fakultät nur von ganzen Zahlen 0..20\n" unless $tok->[1] =~ /\A\d+\z/a && $v <= 20;
        my $f = Math::BigRat->new(1);
        $f *= $_ for 2 .. $v->numify;
        $v = $f;
      }
      return $v;
    }
    if ( $tok->[1] eq '(' ) {
      $v = $expr->();
      die "Klammer nicht geschlossen\n" unless $peek->() eq ')';
      $i++;
      return $v;
    }
    die "unerwartet: $tok->[1]\n";
  };
  my $v = $expr->();
  die "unerwartet am Ende\n" if $i < @$t;
  return $v;
}

sub _countdown {
  my ( $p, $ans ) = @_;
  return _fail('leer') unless length _strip($ans);
  my $v = eval { _cd_parse( _cd_tokens( _strip($ans) ) ) };
  return _fail( 'nicht auswertbar: ' . ( "$@" =~ s/\s+\z//r ) ) unless defined $v;
  my @used = sort { $a <=> $b } map { 0 + $_ } $ans =~ /\b(\d+)\b/ag;
  my @want = sort { $a <=> $b } @{ $p->{zahlen} };
  return _fail('nicht genau die gegebenen Zahlen') unless "@used" eq "@want";
  my $t = Math::BigRat->new( $p->{ziel} );
  my $tol = ( Math::BigRat->new(1) + Math::BigRat->new(10) * abs($t) ) / Math::BigRat->new(1_000_000);
  return abs( $v - $t ) <= $tol ? ( 1, 'ergibt das Ziel' ) : _fail( 'ergibt ' . $v->numify );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Denken - The answer world denken — reasoning tasks, the answer handed in by tool, one checker per task like score_answer of Reasoning Gym

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # suite.yaml
  tools:
    - { name: antwort_abgeben, simulator: denken, description: …, parameters: { … antwort: string … } }

  # a case: the state
  state:
    aufgabe:
      type: denken
      art: countdown
      pruefung: { zahlen: [ 2, 3, 4 ], ziel: 20 }

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok ) = $sims->tool_call( $state, denken => antwort_abgeben => { antwort => '(2+3)*4' } );

  my ( $ok, $why ) = Langertha::Holmgang::Sim::Denken::pruefe( countdown => $pruefung, '(2+3)*4' );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<denken>) for reasoning tasks: the task is in the message, the model
hands in its answer with the only tool:

  antwort_abgeben { antwort }    stores the answer; a repeated call replaces it

The output is always C<Antwort gespeichert.> (answer stored) — the tool never
tells whether the answer is right. The answer is graded when it is handed in
and written into the state, which the model never sees:

  aufgabe:
    type: denken
    art: <task>           # name of the task in Reasoning Gym, e.g. graph_color
    pruefung: { … }       # what the checker needs (solution or puzzle data)
    antwort: "…"          # the answer handed in last
    abgaben: 2            # number of calls
    ergebnis: richtig     # richtig | falsch (right | wrong) — the case's rule checks this
    befund: "…"           # the reason (for the report)

C<prepare> checks, when the case loads, that C<art> is known and that
C<pruefung> carries the fields its checker needs; otherwise the case does not
load. A call the world refuses (no C<antwort>, or not a text) changes nothing.

=head2 Checkers

Per task the same logic as C<score_answer> of the task in Reasoning Gym
(version 0.1.25); B<only the full score (1.0) counts as right>, partial
scores count as wrong. The fields of C<pruefung> each checker needs are in
brackets (C<antwort> when none are named).

  zebra_puzzles         equal without line breaks, ignoring case
  knights_knaves        same set of pairs (name, role); order and wording do not matter
  propositional_logic   follows from the premises (truth table) and is neither a tautology
                        nor a single atom (premissen, variablen)
  syllogism, course_schedule, maze
                        exactly equal (the base of score_answer: equality = 1.0)
  self_reference        exactly equal
  shortest_path         equal (trimmed) or a valid path of the same length (antwort, matrix)
  graph_color           JSON object node -> colour, every node coloured, allowed colours,
                        the ends of every edge differ (knoten, kanten, farben)
  calendar_arithmetic   weekday trimmed equal, number equal as int, leap year ignoring case
                        (antwort, form)
  time_intervals        the same duration in seconds, by the format of the task (antwort, form)
  cryptarithm           "A=1,B=2": every letter, digits unique, no leading zero, the sum holds
                        (woerter, ergebnis; optional fuehrende_null)
  mini_sudoku           equal up to white space at line ends, and not longer than the solution
  family_relationships  trimmed equal, ignoring case
  countdown             the expression yields the target and uses exactly the numbers
                        (as a multiset) (zahlen, ziel)
  jugs                  JSON list of moves (fill X, empty X, pour X->Y); at the end a jug
                        holds the target (kruege, ziel)

Deviations from Python (for countdown, Python evaluates every Python
expression with sympy): here only arithmetic counts — numbers,
C<+ - * / // % **>, factorial C<n!>, brackets; functions, constants, C<^>,
comparisons and non-integer exponents are wrong. For jugs only a JSON list
counts (Python would also walk the keys of an object). More than 16 atoms in
a propositional answer are wrong.

Only the state, pure functions, deterministic, neutral.

=head2 device_type

C<denken>.

=head2 tools

  my $tools = $world->tools;   # { antwort_abgeben => ['antwort'] }

The tools of this world with their required parameters (for the loader).

=head2 prepare

  $world->prepare( $aufgabe, $ctx );

Checks, when the case loads, that C<art> is a known task and C<pruefung> (a
hash) carries the fields of its checker; C<die>s otherwise. Changes nothing.

=head2 tool

  my ( $output, $ok ) = $world->tool( $aufgabe, antwort_abgeben => { antwort => '…' } );

Stores the answer and its grade in C<$aufgabe> (which is changed). A name not
in L</tools> is an error.

=head2 arten

  my @arten = Langertha::Holmgang::Sim::Denken::arten();

The known tasks, sorted.

=head2 pruefe

  my ( $richtig, $grund ) = Langertha::Holmgang::Sim::Denken::pruefe( $art, $pruefung, $antwort );

Grades an answer (text) like C<score_answer> of the task: true only for the
full score. C<$grund> says briefly why.

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
