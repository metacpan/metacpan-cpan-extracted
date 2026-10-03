package Kubernetes::Comb::SVG;
# ABSTRACT: Render Kubernetes::Comb custom resources as an SVG honeycomb


use Moo;
use Carp qw( carp );
use Types::Common::Numeric qw( PositiveInt PositiveNum );
use Types::Standard qw( Any ArrayRef Bool CodeRef Enum HashRef Maybe Object Str );
use Kubernetes::Comb::SVG::Cell;
use Kubernetes::Comb::SVG::Layout;
use namespace::autoclean;

our $VERSION = '0.001';

has combs => ( is => 'ro', isa => Any, required => 1 );


has title => ( is => 'ro', isa => Str, default => 'Combs' );


has group_label => ( is => 'ro', isa => Maybe[Str] );


has layout => ( is => 'ro', isa => Enum[qw( depth packed )], default => 'depth' );


has columns => ( is => 'ro', isa => PositiveInt, default => 6 );


# Whether columns came from the caller, see `columns` in the layout class.
has _columns_given => ( is => 'rwp', isa => Bool, init_arg => undef, default => 0 );

sub BUILD {
  my ( $self, $args ) = @_;
  $self->_set__columns_given(1) if exists $args->{columns};
}

has rows => ( is => 'ro', isa => PositiveInt, predicate => 'has_rows' );


has aspect => ( is => 'ro', isa => PositiveNum, default => 16 / 9 );


has size => ( is => 'ro', isa => PositiveNum, default => 56 );


has edges => ( is => 'lazy', isa => Bool );

sub _build_edges { $_[0]->layout eq 'packed' ? 0 : 1 }


has legend => ( is => 'ro', isa => Bool, default => 1 );


has link => ( is => 'ro', isa => Maybe[CodeRef] );


has theme => ( is => 'ro', isa => HashRef, default => sub { {} } );


has blink => ( is => 'ro', isa => ArrayRef[Str], default => sub { [] } );


has blink_seconds => ( is => 'ro', isa => PositiveNum, default => 1.2 );


has cells => ( is => 'lazy', isa => ArrayRef[Object], init_arg => undef );


sub _build_cells {
  my ( $self ) = @_;
  return [ $self->cell_class->cells_from( $self->combs, group_label => $self->group_label ) ];
}

has _layouter => ( is => 'lazy', isa => Object, init_arg => undef );

sub _build__layouter {
  my ( $self ) = @_;
  return $self->layout_class->new(
    cells  => $self->cells,
    size   => $self->size,
    mode   => $self->layout,
    aspect => $self->aspect,
    # What render puts around the honeycomb, the legend counted as one row.
    frame_width  => 2 * $self->_pad,
    frame_height => 2 * $self->_pad + $self->_title_band
      + ( $self->legend ? $self->_legend_gap + $self->_legend_row * 0.75 : 0 ),
    $self->_columns_given || $self->layout eq 'depth' ? ( columns => $self->columns ) : (),
    $self->has_rows ? ( rows => $self->rows ) : ()
  );
}

sub cell_class { 'Kubernetes::Comb::SVG::Cell' }


sub layout_class { 'Kubernetes::Comb::SVG::Layout' }


#### Phases and colours

sub phases {
  my ( $self ) = @_;
  return ( $self->cell_class->known_phases, 'Unknown' );
}


# Per phase the stroke colour in light and in dark mode; the fill is the same
# colour at a low opacity over the panel, so text keeps its contrast whatever
# colour a theme brings.
sub _default_colours {
  return {
    Running     => [ '#1a7f37', '#3fb950' ],
    Pending     => [ '#bf8700', '#e3b341' ],
    Blocked     => [ '#bc4c00', '#fb8f44' ],
    NeedsConfig => [ '#8250df', '#a371f7' ],
    Disabled    => [ '#8c959f', '#6e7681' ],
    Error       => [ '#cf222e', '#f85149' ],
    Stopped     => [ '#0891b2', '#39c5cf' ],
    NotDeployed => [ '#0969da', '#58a6ff' ],
    Unknown     => [ '#475569', '#94a3b8' ]
  };
}

sub _base_colours {
  return (
    [ bg     => '#ffffff', '#0d1117' ],
    [ border => '#d0d7de', '#30363d' ],
    [ fg     => '#1f2328', '#e6edf3' ],
    [ muted  => '#59636e', '#9198a1' ],
    [ edge   => '#57606a', '#9198a1' ]
  );
}

# A colour is used only when it is plain colour syntax: #hex, a colour name,
# or rgb()/hsl() over a strict character set. Anything else is ignored.
sub _colour {
  my ( $self, $value ) = @_;
  return if !defined $value || ref $value;
  return $value if $value =~ /\A#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/;
  return $value if $value =~ /\A[a-zA-Z]{1,32}\z/;
  return $value if $value =~ m{\A(?:rgb|hsl)a?\([0-9a-zA-Z%., /-]{1,64}\)\z}i;
  return;
}

# The light and the dark colour of a theme key (a phase or a surface): what
# the theme gives, one colour for both or one per mode, else the default.
sub _theme_colours {
  my ( $self, $key, $light, $dark ) = @_;
  my $value = $self->theme->{$key};
  my ( $l, $d ) = map { scalar $self->_colour($_) }
    ref $value eq 'HASH' ? @{$value}{qw( light dark )} : ( $value, $value );
  return ( defined $l ? $l : $light, defined $d ? $d : $dark );
}

# The phases that blink, in the order of the legend: only known phases reach
# the style, whatever order and however often they were named.
sub _blink_phases {
  my ( $self ) = @_;
  my %blink = map { $_ => 1 } @{ $self->blink };
  return grep { $blink{$_} } $self->phases;
}

# The period as plain decimals; what does not print as such (inf, a number
# beyond %f) gives the default.
sub _blink_period {
  my ( $self ) = @_;
  my $seconds = $self->_n( $self->blink_seconds );
  return 1.2 unless $seconds =~ /\A[0-9]{1,9}(?:\.[0-9]{1,2})?\z/;
  return $seconds < 0.01 ? 0.01 : $seconds;
}

# The pulse: fill and outline of the hexagon swell and settle, from and back
# to what the cell has anyway, so nothing moves and the texts stay readable.
# The phase line takes the text colour, to keep its contrast on the fuller
# fill. Without motion the outline is as thick as at the peak.
sub _blink_css {
  my ( $self ) = @_;
  my @phases = $self->_blink_phases;
  return unless @phases;
  my $s     = '.comb-svg';
  my $hex   = join( ',', map { $s.' .comb.phase-'.$_.' .hex' } @phases );
  my $width = 'stroke-width:'.$self->_n( $self->size * 0.07 );
  return (
    '@keyframes comb-blink{50%{fill-opacity:.4;'.$width.'}}',
    $hex.'{animation:comb-blink '.$self->_blink_period.'s ease-in-out infinite}',
    join( ',', map { $s.' .comb.phase-'.$_.' .phase' } @phases ).'{fill:var(--comb-fg)}',
    '@media (prefers-reduced-motion:reduce){'.$hex.'{animation:none;'.$width.'}}'
  );
}

sub _var { '--comb-'.lc $_[1] }

# $small: some cell sets its name in the small two-line font. Its rule is
# written only then, so a picture without such a name keeps its bytes.
# $reason: some cell has a reason line; the same holds for its rule.
sub _style {
  my ( $self, $small, $reason ) = @_;
  my $r       = $self->size;
  my $colours = $self->_default_colours;
  my ( @light, @dark );
  for my $colour ( $self->_base_colours, map { [ $_, @{ $colours->{$_} } ] } $self->phases ) {
    my ( $light, $dark ) = $self->_theme_colours(@$colour);
    push @light, $self->_var( $colour->[0] ).':'.$light;
    push @dark,  $self->_var( $colour->[0] ).':'.$dark;
  }
  push @light, '--comb-tint:.13', '--comb-tint-muted:.06';
  push @dark,  '--comb-tint:.2',  '--comb-tint-muted:.09';

  my $s = '.comb-svg';
  my @css = (
    $s.'{'.join( ';', @light )
      .';font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica Neue,Arial,sans-serif}',
    '@media (prefers-color-scheme:dark){'.$s.'{'.join( ';', @dark ).'}}',
    $s.' .panel{fill:var(--comb-bg);stroke:var(--comb-border);stroke-width:1}',
    $s.' text{fill:var(--comb-fg)}',
    $s.' .heading{font-size:'.$self->_n( $self->_title_font ).'px;font-weight:600}',
    $s.' .group-name{font-size:'.$self->_n( $self->_group_font )
      .'px;font-weight:600;fill:var(--comb-muted)}',
    $s.' .group-rule{stroke:var(--comb-border);stroke-width:1}',
    $s.' .hex{fill:var(--comb-unknown);fill-opacity:var(--comb-tint);stroke:var(--comb-unknown);stroke-width:'
      .$self->_n( $r * 0.03 ).';stroke-linejoin:round}',
    ( map {
      $s.' .phase-'.$_.' .hex{fill:var('.$self->_var($_).');stroke:var('.$self->_var($_).')}'
    } $self->phases ),
    $s.' .borrowed .hex{stroke-dasharray:'.$self->_n( $r * 0.11 ).' '.$self->_n( $r * 0.08 ).'}',
    $s.' .disabled .hex{fill-opacity:var(--comb-tint-muted);stroke-opacity:.55}',
    $s.' .comb text{text-anchor:middle}',
    $s.' .name{font-size:'.$self->_n( $self->_name_font ).'px;font-weight:500}',
    $small ? $s.' .name-small{font-size:'.$self->_n( $self->_name_small_font ).'px}' : (),
    $s.' .phase{font-size:'.$self->_n( $self->_phase_font ).'px;fill:var(--comb-muted)}',
    $s.' .upstream{font-size:'.$self->_n( $self->_upstream_font )
      .'px;font-style:italic;fill:var(--comb-muted)}',
    $reason ? $s.' .reason{font-size:'.$self->_n( $self->_reason_font )
      .'px;fill:var(--comb-muted)}' : (),
    $s.' .disabled text{fill:var(--comb-muted);fill-opacity:.8}',
    $s.' .dep{fill:none;stroke:var(--comb-edge);stroke-opacity:.5;stroke-width:'
      .$self->_n( $r * 0.025 ).';stroke-linecap:round;pointer-events:none}',
    $s.' .arrow{fill:var(--comb-edge);fill-opacity:.5}',
    $s.' .dep-start{fill:var(--comb-edge);fill-opacity:.5;pointer-events:none}',
    $s.' a{cursor:pointer;text-decoration:none}',
    $s.' .legend text{font-size:'.$self->_n( $self->_legend_font ).'px;fill:var(--comb-muted)}',
    $s.' .legend .hex{stroke-width:'.$self->_n( $r * 0.02 ).'}',
    $s.' .legend .count{font-weight:600;fill:var(--comb-fg)}',
    $self->_blink_css
  );
  return $self->_el( 'style', [], $self->_text( join( "\n", @css ) ) );
}

#### Measures, all derived from size

sub _pad { $_[0]->size * 0.45 }

sub _title_font { $_[0]->size * 0.34 }

sub _title_band { $_[0]->size * 0.75 }

sub _group_font { $_[0]->size * 0.2 }

sub _name_font { $_[0]->size * 0.22 }

# A name on two lines that is too wide at _name_font: 13 characters a line
# instead of 11.
sub _name_small_font { $_[0]->size * 0.185 }

sub _phase_font { $_[0]->size * 0.17 }

sub _upstream_font { $_[0]->size * 0.15 }

# The reason line is as small as the upstream line: 16 characters.
sub _reason_font { $_[0]->_upstream_font }

sub _legend_font { $_[0]->size * 0.19 }

sub _legend_swatch { $_[0]->size * 0.15 }

sub _legend_row { $_[0]->size * 0.44 }

sub _legend_gap { $_[0]->size * 0.5 }

# Air kept between a name and the two sides of its hexagon.
sub _name_pad { $_[0]->size * 0.14 }

sub _arrow { $_[0]->size * 0.16 }

# Radius of the dot that marks where an edge starts.
sub _start_dot { $_[0]->size * 0.04 }

# Text is not measured, it is estimated: this share of the font size per
# character. Good enough for a system sans, and the same on every machine.
sub _char_width { 0.59 }

sub _text_width {
  my ( $self, $text, $font ) = @_;
  return length( $text ) * $font * $self->_char_width;
}

# Cuts a text to what fits into $width at $font, with an ellipsis.
sub _fit {
  my ( $self, $text, $font, $width ) = @_;
  my $max = int( $width / ( $font * $self->_char_width ) );
  $max = 1 if $max < 1;
  return $text if length $text <= $max;
  return substr( $text, 0, $max - 1 )."\x{2026}";
}

# How many characters fit into $width at $font, one at the least.
sub _chars {
  my ( $self, $font, $width ) = @_;
  my $max = int( $width / ( $font * $self->_char_width ) );
  return $max < 1 ? 1 : $max;
}

# The name of a cell as it is drawn: { lines => [ one or two ], small => bool }.
# A name that fits stays one line. Otherwise it is broken after a hyphen, a
# dot or an underscore, at the break that leaves the shortest longer line (the
# earlier of two equal ones); when that is too wide for the name font the two
# lines take the small one, and what is still too wide is cut there. A name
# too long without such a character is cut on its one line.
sub _name_lines {
  my ( $self, $name ) = @_;
  my $width  = $self->_layouter->hex_width - 2 * $self->_name_pad;
  my $length = length $name;
  return { lines => [$name], small => 0 }
    if $length <= $self->_chars( $self->_name_font, $width );

  my ( $at, $longer );
  for my $break ( grep { substr( $name, $_ - 1, 1 ) =~ /\A[-._]\z/ } 1 .. $length - 1 ) {
    my $rest = $length - $break;
    my $long = $break > $rest ? $break : $rest;
    ( $at, $longer ) = ( $break, $long ) if !defined $longer || $long < $longer;
  }
  return { lines => [ $self->_fit( $name, $self->_name_font, $width ) ], small => 0 }
    unless defined $at;

  my @lines = ( substr( $name, 0, $at ), substr( $name, $at ) );
  return { lines => \@lines, small => 0 }
    if $longer <= $self->_chars( $self->_name_font, $width );
  return {
    lines => [ map { $self->_fit( $_, $self->_name_small_font, $width ) } @lines ],
    small => 1
  };
}

# The text lines of a cell, top to bottom, as text elements: { class, rows },
# a row being [ text, baseline as an offset from the centre of the cell ].
# Where the lines sit is decided by _cell_baselines. A reason too long for
# its line takes a second one where the cell has the room, see _reason_break.
sub _cell_lines {
  my ( $self, $cell ) = @_;
  my $name   = $self->_name_lines( $cell->name );
  my @names  = @{ $name->{lines} };
  my $step   = $self->size * ( $name->{small} ? 0.21 : 0.24 );
  my $reason = $self->_shows_reason($cell);

  # The small lines under the phase, by class.
  my @below = ( $reason ? 'reason' : (), $cell->borrowed ? 'upstream' : () );
  my @at    = $self->_cell_baselines( scalar @names, $step, @below );
  my @reason;
  if ($reason) {
    my $text = $cell->reason;
    my $one  = $at[ @names + 1 ];
    @reason = ( $self->_fit( $text, $self->_reason_font, $self->_reason_width($one) ) );
    my @two = length $text > $self->_reason_chars($one)
      ? $self->_cell_baselines( scalar @names, $step, 'reason', @below )
      : ();
    if (@two) {
      my @under = @two[ @names + 1, @names + 2 ];
      if ( my @broken = $self->_reason_break( $text, map { $self->_reason_chars($_) } @under ) ) {
        $broken[1] = $self->_fit( $broken[1], $self->_reason_font, $self->_reason_width( $under[1] ) );
        @reason = @broken;
        @at     = @two;
      }
    }
  }

  my @lines = (
    { class => $name->{small} ? 'name name-small' : 'name', rows => [ map { [ $_, shift @at ] } @names ] },
    { class => 'phase', rows => [ [ $cell->phase, shift @at ] ] }
  );
  push @lines, { class => 'reason', rows => [ map { [ $_, shift @at ] } @reason ] } if $reason;
  push @lines, { class => 'upstream', rows => [ [
    $self->_fit(
      defined $cell->upstream_context ? 'from '.$cell->upstream_context : 'borrowed',
      $self->_upstream_font, $self->_layouter->hex_width * 0.8
    ),
    shift @at
  ] ] } if $cell->borrowed;
  return @lines;
}

# The baselines of the lines of a cell, top to bottom, as offsets from its
# centre: $names name lines $step apart, the phase, then one line per class in
# @below ('reason', once or twice, and 'upstream'). The lines are stacked by
# their advance, the distance of a baseline from the one above.
#
# A cell without a reason line, and one with nothing but one name line, the
# phase and one reason line, starts where a cell with one name line and its
# phase sits centred, every further line moving that start up.
#
# Every other cell with a reason line is tight: the small lines sit closer
# together and the block is centred as a whole, to stay inside the hexagon.
# The advances of such a block may add up to 0.89 of the size; what the block
# leaves of that goes to the phase, up to 0.28 of the size from the name
# above it, so that it does not read as one more name line. A block that is
# too high even with the phase at 0.24 gives an empty list when it has two
# reason lines -- there is no room for the second -- and is drawn as it is
# otherwise.
sub _cell_baselines {
  my ( $self, $names, $step, @below ) = @_;
  my $r      = $self->size;
  my $reason = grep { $_ eq 'reason' } @below;
  my $tight  = $reason && $names + @below > 2;
  my ( $to_phase, $to_below ) = $tight ? ( 0.24 * $r, 0.2 * $r ) : ( 0.3 * $r, 0.25 * $r );
  my @advance = ( $to_below ) x @below;
  $advance[1] = 0.17 * $r if $reason > 1;

  my $at;
  if ($tight) {
    my $sum = $step * ( $names - 1 ) + $to_phase;
    $sum += $_ for @advance;
    my $spare = 0.89 * $r - $sum;
    return if $reason > 1 && $spare < -$r * 1e-9;
    $spare = $spare < 0 ? 0 : $spare > 0.04 * $r ? 0.04 * $r : $spare;
    $to_phase += $spare;
    $at = 0.06 * $r - ( $sum + $spare ) / 2;
  }
  else {
    $at = -0.07 * $r - $step * ( $names - 1 ) / 2 - 0.1 * $r * @below;
  }
  my @at = ( $at );
  push @at, $at += $_ for ( $step ) x ( $names - 1 ), $to_phase, @advance;
  return @at;
}

# The width a reason line with its baseline at $at may take, and the number
# of characters that is: sixteen inside the full-width band of the hexagon,
# fewer for a line that reaches below it.
sub _reason_width {
  my ( $self, $at ) = @_;
  my $font = $self->_reason_font;
  return $self->_line_width( $at - 0.75 * $font, $at + 0.25 * $font );
}

sub _reason_chars {
  my ( $self, $at ) = @_;
  return $self->_chars( $self->_reason_font, $self->_reason_width($at) );
}

# A reason on two lines of at most $first and $second characters, or nothing
# when it cannot be broken. It breaks at a run of whitespace, which is
# dropped, and before an upper-case letter that follows a lower-case letter
# or a digit. Of the breaks that make both lines fit it takes the one with the
# shortest longer line (the earlier of two equal ones); when there is none,
# the last break whose first line fits, the second line then being too long
# and left to the caller to cut.
sub _reason_break {
  my ( $self, $text, $first, $second ) = @_;
  my ( @best, $longer, @last );
  while ( $text =~ /\s+|(?<=[\p{Ll}0-9])(?=\p{Lu})/g ) {
    my @lines = ( substr( $text, 0, $-[0] ), substr( $text, $+[0] ) );
    next if !length $lines[0] || !length $lines[1] || length $lines[0] > $first;
    @last = @lines;
    next if length $lines[1] > $second;
    my ( $long ) = sort { $b <=> $a } map { length } @lines;
    ( $longer, @best ) = ( $long, @lines ) if !defined $longer || $long < $longer;
  }
  return @best ? @best : @last;
}

# Whether a cell gets a reason line: it has a reason and is not Running.
sub _shows_reason {
  my ( $self, $cell ) = @_;
  my $reason = $cell->reason;
  return 0 if !defined $reason || ref $reason || !length $reason;
  return $cell->phase eq 'Running' ? 0 : 1;
}

# The width a line of text may take when it reaches from $top to $bottom,
# both offsets from the centre of the cell: the width of the hexagon where it
# is narrowest in that span -- full inside the middle band of half a radius
# up and down, less towards the corners -- minus the air on both sides.
sub _line_width {
  my ( $self, $top, $bottom ) = @_;
  my $r = $self->size;
  my ( $far ) = sort { $b <=> $a } abs $top, abs $bottom;
  my $share = $far <= $r / 2 ? 1 : $far >= $r ? 0 : 2 * ( $r - $far ) / $r;
  return $self->_layouter->hex_width * $share - 2 * $self->_name_pad;
}

#### Escaping

# Text content. Drops what XML 1.0 cannot carry, escapes the five special
# characters, and writes everything outside ASCII as a character reference,
# so the document is plain ASCII whatever the input was.
sub _text {
  my ( $self, $value ) = @_;
  return '' if !defined $value || ref $value;
  $value = ''.$value;
  $value =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//g;
  $value =~ s/&/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
  $value =~ s/"/&quot;/g;
  $value =~ s/'/&#39;/g;
  $value =~ s/([\x0D\x7F-\x{10FFFF}])/'&#'.ord($1).';'/ge;
  return $value;
}

# Attribute value: as text, and tab and newline as references too, so they
# survive attribute value normalisation.
sub _attr {
  my ( $self, $value ) = @_;
  $value = $self->_text($value);
  $value =~ s/([\x09\x0A])/'&#'.ord($1).';'/ge;
  return $value;
}

# One element. Attributes are name/value pairs in the order given, every
# value escaped here; $content is markup already and undef closes the tag.
sub _el {
  my ( $self, $name, $attrs, $content ) = @_;
  my @pairs = @$attrs;
  my $tag   = '<'.$name;
  while (@pairs) {
    my ( $key, $value ) = splice @pairs, 0, 2;
    $tag .= ' '.$key.'="'.$self->_attr($value).'"';
  }
  return defined $content ? $tag.'>'.$content.'</'.$name.'>' : $tag.'/>';
}

# Two decimals, as a number: the same on every platform, and no '-0'.
sub _n {
  my ( $self, $value ) = @_;
  return sprintf( '%.2f', $value ) + 0;
}

#### Render

sub render {
  my ( $self ) = @_;
  my $layout = $self->_layouter->layout;
  my $pad    = $self->_pad;
  my %cell   = map { $_->id => $_ } @{ $self->cells };
  my @placed = grep { $cell{ $_->{id} } } @{ $layout->{cells} };

  my %count;
  $count{ $cell{ $_->{id} }->phase }++ for @placed;
  my @occurring = grep { $count{$_} } $self->phases;

  my @legend = $self->legend
    ? map { { phase => $_, count => $count{$_}, width => $self->_legend_item_width( $_, $count{$_} ) } }
      @occurring
    : ();
  my $content = $layout->{width};
  for my $width (
    $self->_text_width( $self->title, $self->_title_font ),
    ( map { $_->{width} } @legend ),
    ( map { $self->_text_width( $_->{name}, $self->_group_font ) }
      grep { defined $_->{name} } @{ $layout->{groups} } )
  ) {
    $content = $width if $width > $content;
  }
  my @legend_rows = $self->_legend_rows( \@legend, $content );

  my $ox     = $pad;
  my $oy     = $pad + $self->_title_band;
  my $bottom = $oy + $layout->{height};
  my $legend_top = $bottom + $self->_legend_gap;
  $bottom = $legend_top + @legend_rows * $self->_legend_row - $self->_legend_row / 4
    if @legend_rows;
  my $width  = $content + 2 * $pad;
  my $height = $bottom + $pad;

  my $summary = ( @placed == 1 ? '1 Comb' : scalar(@placed).' Combs' )
    .( @occurring ? ': '.join( ', ', map { $count{$_}.' '.$_ } @occurring ) : '' );

  my %at = map { $_->{id} => [ $_->{x} + $ox, $_->{y} + $oy ] } @placed;

  my @out = (
    $self->_el( 'title', [ id => 'comb-title' ], $self->_text( $self->title ) ),
    $self->_el( 'desc',  [ id => 'comb-desc' ],  $self->_text($summary) ),
    $self->_style(
      scalar( grep { $self->_name_lines( $cell{ $_->{id} }->name )->{small} } @placed ),
      scalar( grep { $self->_shows_reason( $cell{ $_->{id} } ) } @placed )
    ),
    $self->_el( 'defs', [], $self->_marker ),
    $self->_el( 'rect', [
      class  => 'panel',
      x      => 0.5,
      y      => 0.5,
      width  => $self->_n( $width - 1 ),
      height => $self->_n( $height - 1 ),
      rx     => $self->_n( $self->size * 0.22 )
    ] ),
    $self->_el( 'text', [
      class => 'heading',
      x     => $self->_n($ox),
      y     => $self->_n( $pad + $self->_title_font * 0.8 )
    ], $self->_text( $self->title ) )
  );

  push @out, map { $self->_group( $_, $ox, $oy, $content ) }
    grep { $_->{heading} } @{ $layout->{groups} };

  if ( $self->edges ) {
    my @paths = map { $self->_edge( $_, $at{ $_->{from} }, $at{ $_->{to} } ) }
      grep { $at{ $_->{from} } && $at{ $_->{to} } } @{ $layout->{edges} };
    push @out, $self->_el( 'g', [ class => 'deps' ], join( '', @paths ) ) if @paths;
  }

  push @out, map { $self->_comb( $cell{ $_->{id} }, @{ $at{ $_->{id} } } ) } @placed;

  push @out, $self->_legend( \@legend_rows, $ox, $legend_top ) if @legend_rows;

  return $self->_el( 'svg', [
    xmlns             => 'http://www.w3.org/2000/svg',
    viewBox           => '0 0 '.$self->_n($width).' '.$self->_n($height),
    role              => 'img',
    class             => 'comb-svg',
    'aria-labelledby' => 'comb-title comb-desc'
  ], "\n".join( "\n", @out )."\n" )."\n";
}


sub _marker {
  my ( $self ) = @_;
  my $arrow = $self->_n( $self->_arrow );
  return $self->_el( 'marker', [
    id           => 'comb-arrow',
    viewBox      => '0 0 10 10',
    refX         => 0,
    refY         => 5,
    markerWidth  => $arrow,
    markerHeight => $arrow,
    markerUnits  => 'userSpaceOnUse',
    orient       => 'auto'
  ], $self->_el( 'path', [ class => 'arrow', d => 'M0 1L10 5L0 9z' ] ) );
}

# The heading of a group: its name and a faint rule to the right of it. The
# unnamed group among named ones gets the rule alone.
sub _group {
  my ( $self, $group, $ox, $oy, $content ) = @_;
  my $x    = $group->{heading}{x} + $ox;
  my $y    = $group->{heading}{y} + $oy;
  my $font = $self->_group_font;
  my ( $text, $from ) = ( '', $x );
  if ( defined $group->{name} ) {
    $text = $self->_el( 'text', [
      class => 'group-name',
      x     => $self->_n($x),
      y     => $self->_n($y)
    ], $self->_text( $group->{name} ) );
    $from = $x + $self->_text_width( $group->{name}, $font ) + $font * 0.8;
  }
  my $to   = $ox + $content;
  my $rule = $to - $from > $font
    ? $self->_el( 'line', [
        class => 'group-rule',
        x1    => $self->_n($from),
        y1    => $self->_n( $y - $font * 0.35 ),
        x2    => $self->_n($to),
        y2    => $self->_n( $y - $font * 0.35 )
      ] )
    : '';
  return $self->_el( 'g', [
    class => 'group',
    defined $group->{name} ? ( 'data-group' => $group->{name} ) : ()
  ], $text.$rule );
}

sub _hexagon {
  my ( $self, $x, $y, $radius ) = @_;
  my $half = $radius * sqrt(3) / 2;
  my @points = (
    [ $x,         $y - $radius ],
    [ $x + $half, $y - $radius / 2 ],
    [ $x + $half, $y + $radius / 2 ],
    [ $x,         $y + $radius ],
    [ $x - $half, $y + $radius / 2 ],
    [ $x - $half, $y - $radius / 2 ]
  );
  return $self->_el( 'polygon', [
    class  => 'hex',
    points => join( ' ', map { $self->_n( $_->[0] ).','.$self->_n( $_->[1] ) } @points )
  ] );
}

sub _tooltip {
  my ( $self, $cell ) = @_;
  my @lines = ( $cell->id );
  push @lines, 'namespace: '.$cell->namespace if defined $cell->namespace;
  push @lines, 'class: '.$cell->class         if defined $cell->class;
  push @lines, 'phase: '.$cell->phase
    .( $cell->phase eq 'Unknown' && defined $cell->raw_phase ? ' ('.$cell->raw_phase.')' : '' );
  push @lines, 'message: '.$cell->message
    if defined $cell->message && $cell->phase ne 'Running';
  push @lines, map { 'endpoint: '.$_->{name}.( defined $_->{port} ? ' '.$_->{port} : '' ) }
    @{ $cell->endpoints };
  if ( $cell->upstream_recorded ) {
    my @upstream = (
      defined $cell->upstream_class   ? $cell->upstream_class              : (),
      defined $cell->upstream_context ? 'context '.$cell->upstream_context : ()
    );
    push @lines, 'upstream: '.( @upstream ? join( ', ', @upstream ) : 'recorded' )
      .( $cell->borrowed ? '' : ' (not borrowing)' );
    push @lines, 'via: '.join( ', ', @{ $cell->upstream_via } ) if @{ $cell->upstream_via };
  }
  push @lines, 'missing: '.join( ', ', @{ $cell->missing } ) if @{ $cell->missing };
  return join( "\n", @lines );
}

# The href for a cell, or undef: what the link callback answers, when it is
# relative or http(s) and carries neither whitespace nor control characters.
sub _href {
  my ( $self, $cell ) = @_;
  return unless $self->link;
  my $href = eval { $self->link->($cell) };
  if ( my $error = $@ ) {
    carp __PACKAGE__.'->render: link callback died for '.$cell->id.': '.$error;
    return;
  }
  return if !defined $href || ref $href || !length $href;
  return if $href =~ /[\x00-\x20\x7F]/;
  return $href if $href =~ m{\Ahttps?://}i;
  return if $href =~ m{\A[^/?#]*:};
  return $href;
}

# One text element of a cell. A single row is the text itself; several rows
# are one <tspan> each, placed on its own, so the text content of the element
# is still the whole of what is shown.
sub _cell_text {
  my ( $self, $line, $x, $y ) = @_;
  my @rows = map { [ $self->_text( $_->[0] ), x => $self->_n($x), y => $self->_n( $y + $_->[1] ) ] }
    @{ $line->{rows} };
  return $self->_el( 'text', [ class => $line->{class}, @{ $rows[0] }[ 1 .. 4 ] ], $rows[0][0] )
    if @rows == 1;
  return $self->_el( 'text', [ class => $line->{class} ],
    join( '', map { $self->_el( 'tspan', [ @{$_}[ 1 .. 4 ] ], $_->[0] ) } @rows ) );
}

sub _comb {
  my ( $self, $cell, $x, $y ) = @_;
  my $r        = $self->size;
  my $borrowed = $cell->borrowed;
  my $disabled = $cell->phase eq 'Disabled';

  my @parts = (
    $self->_el( 'title', [], $self->_text( $self->_tooltip($cell) ) ),
    $self->_hexagon( $x, $y, $r ),
    map { $self->_cell_text( $_, $x, $y ) } $self->_cell_lines($cell)
  );

  my $group = $self->_el( 'g', [
    class => join( ' ', 'comb', 'phase-'.$cell->phase,
      $borrowed ? 'borrowed' : (), $disabled ? 'disabled' : () ),
    'data-name'  => $cell->name,
    'data-id'    => $cell->id,
    'data-phase' => $cell->phase
  ], join( '', @parts ) );

  my $href = $self->_href($cell);
  return defined $href ? $self->_el( 'a', [ href => $href ], $group ) : $group;
}

# One dependency, dependent to dependency, drawn between the label-free
# corner regions of its two ends: the name, phase and upstream lines fill the
# middle band of a hexagon, the regions towards its top and bottom corner are
# free. The line starts at a dot just inside the outline of the dependent and
# its arrowhead ends inside the dependency.
#
# Across rows it is a straight line from the corner region facing the
# dependency into the corner region facing the dependent. Inside one row it
# is a bow through the corner regions of the cells it passes: above the row
# when it runs left to right, below when it runs right to left, so the two
# edges of a cycle never share a line.
sub _edge {
  my ( $self, $edge, $from, $to ) = @_;
  my $r = $self->size;
  my ( $dx, $dy ) = ( $to->[0] - $from->[0], $to->[1] - $from->[1] );
  return () if abs($dx) < 0.01 && abs($dy) < 0.01;

  my ( @a, @b, @via );
  if ( abs($dy) < 0.01 ) {
    my $along = $dx > 0 ? 1 : -1;
    my $side  = -$along;
    my $steps = abs($dx) / $self->_layouter->step_x;
    $steps = 3 if $steps > 3;
    @a   = ( $from->[0] + $along * $r * 0.3, $from->[1] + $side * $r * 0.62 );
    @b   = ( $to->[0] - $along * $r * 0.35,  $to->[1] + $side * $r * 0.55 );
    @via = ( ( $a[0] + $b[0] ) / 2, $from->[1] + $side * $r * ( 0.9 + 0.15 * $steps ) );
  }
  else {
    my $side = $dy > 0 ? 1 : -1;
    @a = ( $from->[0] + $self->_clamp( $dx * 0.3, $r * 0.2 ), $from->[1] + $side * $r * 0.62 );
    @b = ( $to->[0] - $self->_clamp( $dx * 0.3, $r * 0.3 ),   $to->[1] - $side * $r * 0.6 );
  }

  # @b is the tip of the arrowhead; the marker draws it beyond the end of the
  # path, so the path stops one arrowhead short, along its last direction.
  my @last  = @via ? @via : @a;
  my $angle = atan2( $b[1] - $last[1], $b[0] - $last[0] );
  my @end   = ( $b[0] - cos($angle) * $self->_arrow, $b[1] - sin($angle) * $self->_arrow );

  # @a is the centre of the start dot; the line leaves it at its rim, so the
  # two translucent shapes do not overlap.
  my @first = @via ? @via : @end;
  my $out   = atan2( $first[1] - $a[1], $first[0] - $a[0] );
  my @start = ( $a[0] + cos($out) * $self->_start_dot, $a[1] + sin($out) * $self->_start_dot );

  my $d = 'M'.$self->_n( $start[0] ).' '.$self->_n( $start[1] )
    .( @via ? 'Q'.$self->_n( $via[0] ).' '.$self->_n( $via[1] ).' ' : 'L' )
    .$self->_n( $end[0] ).' '.$self->_n( $end[1] );
  return $self->_el( 'path', [
    class        => 'dep',
    'data-from'  => $edge->{from},
    'data-to'    => $edge->{to},
    d            => $d,
    'marker-end' => 'url(#comb-arrow)'
  ] ).$self->_el( 'circle', [
    class => 'dep-start',
    cx    => $self->_n( $a[0] ),
    cy    => $self->_n( $a[1] ),
    r     => $self->_n( $self->_start_dot )
  ] );
}

sub _clamp {
  my ( $self, $value, $limit ) = @_;
  return $value > $limit ? $limit : $value < -$limit ? -$limit : $value;
}

#### Legend

sub _legend_item_width {
  my ( $self, $phase, $count ) = @_;
  return $self->_legend_swatch * 2.6
    + $self->_text_width( $phase.' '.$count, $self->_legend_font );
}

# Fills rows of at most $width, at least one item each.
sub _legend_rows {
  my ( $self, $items, $width ) = @_;
  my $gap = $self->size * 0.35;
  my ( @rows, $used );
  for my $item (@$items) {
    if ( !@rows || $used + $gap + $item->{width} > $width ) {
      push @rows, [];
      $used = -$gap;
    }
    $item->{x} = $used + $gap;
    $used = $item->{x} + $item->{width};
    push @{ $rows[-1] }, $item;
  }
  return @rows;
}

sub _legend {
  my ( $self, $rows, $ox, $top ) = @_;
  my $swatch = $self->_legend_swatch;
  my @items;
  for my $row ( 0 .. $#$rows ) {
    my $y = $top + $row * $self->_legend_row + $swatch;
    for my $item ( @{ $rows->[$row] } ) {
      my $x = $ox + $item->{x} + $swatch;
      push @items, $self->_el( 'g', [
        class        => 'legend-item phase-'.$item->{phase},
        'data-phase' => $item->{phase},
        'data-count' => $item->{count}
      ], $self->_hexagon( $x, $y, $swatch )
        .$self->_el( 'text', [
          x => $self->_n( $x + $swatch * 1.6 ),
          y => $self->_n( $y + $self->_legend_font * 0.35 )
        ], $self->_text( $item->{phase} ).' '
          .$self->_el( 'tspan', [ class => 'count' ], $self->_text( $item->{count} ) ) ) );
    }
  }
  return $self->_el( 'g', [ class => 'legend' ], join( '', @items ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::SVG - Render Kubernetes::Comb custom resources as an SVG honeycomb

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Kubernetes::Comb::SVG;

  my $svg = Kubernetes::Comb::SVG->new(
    combs       => \@combs,
    title       => 'Lab',
    group_label => 'app.kubernetes.io/part-of',
    columns     => 4,
    link        => sub { '/combs/'.$_[0]->name },
    theme       => { Running => '#2da44e', bg => { light => '#fff', dark => '#000' } },
    blink       => ['Error']
  )->render;

  # A status monitor for a wall screen: packed, shaped for a 16:9 display
  my $monitor = Kubernetes::Comb::SVG->new(
    combs  => \@combs,
    layout => 'packed',
    aspect => 16 / 9,
    blink  => [ 'Error', 'Blocked' ]
  )->render;

  # @combs: hashes in CR shape, e.g.
  #   { metadata => { name => 'db', namespace => 'lab' },
  #     spec     => { class => 'postgres' },
  #     status   => { phase => 'Running' } }
  #   { metadata => { name => 'nats' }, spec => { dependsOn => ['db'] } }

=head1 DESCRIPTION

Draws a set of L<Kubernetes::Comb> custom resources as one self-contained SVG
document: a honeycomb with one hexagon per Comb, coloured by its phase, with
the dependencies drawn between them and a legend of the phases that occur.
The Combs are placed by dependency depth, or, as a status monitor, packed into
one compact honeycomb, see L</layout>; the colours follow the light or dark
mode of the viewer and can be set by option or by the embedding page, see
L</theme> and L</THE PICTURE>.
Data in, string out: the dist never talks to a cluster -- the caller fetches
the custom resources (C<kubectl get combs -A -o json>, a client library, a
fixture) and hands them in. L<Kubernetes::Comb> and L<IO::K8s> are not
dependencies; the input is duck-typed, see L</combs>.

The same input gives the same bytes: no timestamps, no generated ids, every
hash sorted before it reaches the output. The picture carries no script and no
reference to anything outside the document, and everything that comes from a
custom resource is escaped, see L</THE PICTURE>.

Odd data never dies: an unknown phase is drawn as C<Unknown>, a missing
C<status> is fine, a dependency on a name that is not in the input is listed
as missing in the tooltip, a dependency cycle puts its cells on one row. Only
a Comb without C<metadata.name> is an error.

C<examples/demo.pl> in the distribution renders C<examples/demo.json> to
C<examples/demo.svg>, the picture the README shows. The command line
equivalent is L<comb-svg>.

=begin html

<p><img src="https://raw.githubusercontent.com/Getty/p5-kubernetes-comb-svg/main/examples/demo.png" alt="Honeycomb of seventeen Combs in two groups, coloured by phase, with dependency edges" width="700"></p>

<p><img src="https://raw.githubusercontent.com/Getty/p5-kubernetes-comb-svg/main/examples/monitor.png" alt="The same Combs in the packed layout, the status monitor" width="700"></p>

=end html

=head2 combs

Required. The custom resources to draw, in any of these shapes:

=over

=item * an array reference of Comb custom resources

=item * a C<List> hash, a hash with C<items>, as C<kubectl get combs -o json>
prints it

=item * a single custom resource (a hash without C<items>)

=back

Each custom resource is a plain hash in CR shape (C<metadata>, C<spec>,
C<status>) or an object answering C<TO_JSON> with such a hash, like the
L<IO::K8s> classes of L<Kubernetes::Comb>. C<undef> and an empty list give a
valid picture with no cells.

  combs => [ { metadata => { name => 'db' } }, $comb_object ]
  combs => { items => \@combs }

Of two custom resources with the same C<namespace/name> the first is kept. The
input is read when the picture is first needed (L</cells>, L</render>), not by
the constructor; a Comb without C<metadata.name> dies there. See
L<Kubernetes::Comb::SVG::Cell/cells_from> for what is read from each one.

=head2 title

Default C<Combs>. The text of the heading above the honeycomb and of the
C<< <title> >> of the SVG (what a screen reader announces). The canvas widens
if a long title needs it.

=head2 group_label

Optional, no default. A label key, for example
C<app.kubernetes.io/part-of>: the Combs are grouped by the value that label
has in C<metadata.labels>. Each group is drawn under its own heading, groups
stacked top to bottom in name order, the Combs without the label in a last
group without a name. Without it there is one group and no headings. No label
key is built in; which one groups your Combs is your choice.

=head2 layout

Default C<depth>: inside a group a Comb sits one row below its deepest
dependency. C<packed> is the status monitor for a wall screen: dependencies
play no part in placement, the Combs are sorted by C<namespace/name> and fill
the rows left to right, top to bottom, as one compact honeycomb (one per
group with L</group_label>). A Comb keeps its place as long as the set of
Combs is the same; a phase changing moves nothing. The grid of C<packed>
comes from L</columns> when given, else from L</rows>, else from L</aspect>,
and L</edges> defaults to false there.

=head2 columns

Default C<6>, a positive integer. How many hexagons a row holds before it
wraps into the next row. Wrapped rows stay in the group and in the dependency
depth they belong to. In the C<packed> L</layout> it is the cells per row and
counts only when given: the default leaves the grid to L</rows> and
L</aspect>.

=head2 rows

Optional, a positive integer, no default. C<packed> L</layout> only, and only
when L</columns> is not given: the number of rows of a block; the columns
follow from the number of Combs. A block has fewer rows when its Combs do not
fill them, and with L</group_label> it holds for every group on its own.

=head2 aspect

Default C<16/9>, a positive number. C<packed> L</layout> only, and only when
neither L</columns> nor L</rows> is given: width divided by height of the
area the picture is to fill, C<9/16> for an upright screen. The column count
is the one whose picture -- all groups with their headings, plus padding,
title and a legend of one row -- comes closest to that shape. A long title or
a legend that wraps is not accounted for.

=head2 size

Default C<56>, a positive number. The radius of a hexagon, centre to corner,
in SVG units. Fonts, gaps, stroke widths and the padding all derive from it,
so the picture changes scale as a whole. The SVG has a C<viewBox> and no
fixed pixel size: it scales with the box that embeds it anyway.

=head2 edges

Default true, false in the C<packed> L</layout>; a given value wins in both.
Draws one arrow per dependency, from the dependent Comb to the Comb it
depends on. False leaves out the C<g.deps> group; the placement of the cells
does not change.

=head2 legend

Default true. Draws the legend below the honeycomb: one entry for each phase
that occurs, with its colour and the number of Combs in it. False leaves out
the C<g.legend> group.

=head2 link

Optional coderef, no default. Called once per cell with its
L<Kubernetes::Comb::SVG::Cell> object; it returns the URL the cell links to,
or C<undef> for no link. A linked cell is wrapped in C<< <a href="..."> >>.

  link => sub { my ( $cell ) = @_; '/combs/'.$cell->namespace.'/'.$cell->name }

The result is used only when it is relative (C</combs/db>, C<db.html>) or
starts with C<http://> or C<https://>, and carries no whitespace or control
character; anything else (C<javascript:>, C<data:>, a reference, an empty
string) draws the cell without a link. The value is escaped as an attribute.
A callback that dies is caught: the cell is drawn without a link and a
warning (L<Carp/carp>) names it.

=head2 theme

Default C<{}>. A hash from key to colour, merged over the built-in colours.
The keys are the phase names (C<Running>, C<Pending>, C<Blocked>,
C<NeedsConfig>, C<Disabled>, C<Error>, C<Stopped>, C<NotDeployed>, C<Unknown>,
see L</phases>) and the surfaces of the picture: C<bg> (the panel), C<fg>
(text), C<muted> (secondary text), C<border> (panel outline and group rules)
and C<edge> (dependency edges). Keys are case-sensitive; any other key is
ignored.

  theme => {
    Running => '#2da44e',
    Error   => { light => 'crimson', dark => '#ff6b6b' },
    bg      => { light => '#ffffff', dark => '#000000' }
  }

A value is one colour, used in light and in dark mode, or a hash with
C<light> and C<dark>; a mode the hash leaves out keeps its built-in colour.
The colour of a phase is the outline of the hexagon; its fill is the same
colour at low opacity, so the text stays readable whatever colour is chosen.
Accepted are C<#rgb>, C<#rgba>, C<#rrggbb>, C<#rrggbbaa>, a colour name
(letters only) and C<rgb()>, C<rgba()>, C<hsl()>, C<hsla()> over plain
numbers; any other value falls back to the built-in colour, for each mode on
its own. Every colour ends up as a custom property, see L</THE PICTURE>.

The built-in colours, light / dark:

  Running      #1a7f37 / #3fb950      bg      #ffffff / #0d1117
  Pending      #bf8700 / #e3b341      fg      #1f2328 / #e6edf3
  Blocked      #bc4c00 / #fb8f44      muted   #59636e / #9198a1
  NeedsConfig  #8250df / #a371f7      border  #d0d7de / #30363d
  Disabled     #8c959f / #6e7681      edge    #57606a / #9198a1
  Error        #cf222e / #f85149
  Stopped      #0891b2 / #39c5cf
  NotDeployed  #0969da / #58a6ff
  Unknown      #475569 / #94a3b8

=head2 blink

Default C<[]>. The phases (see L</phases>, case-sensitive) whose cells pulse,
for a screen on which an C<Error> has to catch the eye:

  blink => [ 'Error', 'Blocked' ]

The pulse is a CSS animation in the C<< <style> >> of the picture, no script:
fill and outline of the hexagon swell and settle, the texts stay as they are.
Where the viewer asks for reduced motion nothing moves and the cell has a
thicker outline instead. A name that is no phase is ignored; order and
repeats do not matter. Without it the picture carries no animation at all.

=head2 blink_seconds

Default C<1.2>, a positive number. The period of the pulse of L</blink> in
seconds, there and back. Written with two decimals, C<0.01> at the least.

=head2 cells

The L<Kubernetes::Comb::SVG::Cell> objects read from L</combs>, in input
order. Built on first use. Not a constructor argument.

=head2 cell_class

Returns the class name that reads the custom resources,
C<Kubernetes::Comb::SVG::Cell>. It must answer C<cells_from>, C<known_phases>
and the cell accessors. Override in a subclass to read the custom resources
differently.

=head2 layout_class

Returns the class name that places the cells, C<Kubernetes::Comb::SVG::Layout>.
It is built with C<cells>, C<size>, C<mode> (the L</layout>), C<aspect>,
C<frame_width>, C<frame_height> and, when given, C<columns> and C<rows>, and
must answer C<layout>
and the geometry methods of L<Kubernetes::Comb::SVG::Layout>. Override in a
subclass to place the cells differently.

=head2 phases

  my @phases = $svg->phases;

Returns the phases a cell can be drawn in, in the fixed order of the legend:
C<Running>, C<Pending>, C<Blocked>, C<NeedsConfig>, C<Disabled>, C<Error>,
C<Stopped>, C<NotDeployed>, then C<Unknown> for every other C<status.phase>
(and for a missing one). These are the keys L</theme> understands.

=head2 render

  my $svg = $svg->render;

Returns the picture as one SVG document in a string: it starts with C<< <svg >>
(no XML declaration, so it can be inlined into HTML as well as served as
C<image/svg+xml>) and ends with a newline. The string is pure ASCII: what is
outside ASCII is written as a character reference. Same input and options,
same bytes. The document is self-contained, see L</THE PICTURE>.

Dies with C<Comb without metadata.name> when an element of L</combs> has no
name; nothing else in the data is an error. The constructor dies, as Moo
does, on an option of the wrong type. A dying L</link> callback only warns.

=head1 THE PICTURE

What the document contains, so a page that embeds it can style or script
against it. Everything is plain SVG; a page can query it with the DOM when the
SVG is inlined.

Where the cells sit depends on L</layout>. With C<depth> a cell is in the row
of its dependency depth, so what has to be up first is above. With C<packed>
the cells are sorted by C<namespace/name> and fill one compact honeycomb
(one per group) whatever they depend on; the dependency edges are then left
out unless L</edges> is true. The elements below are the same in both.

=over

=item * The root is C<< <svg class="comb-svg" role="img"> >> with C<xmlns>, a
C<viewBox> and no fixed width or height, labelled by C<< <title
id="comb-title"> >> (from L</title>) and C<< <desc id="comb-desc"> >>, a
generated summary such as C<3 Combs: 2 Running, 1 Blocked>.

=item * One C<< <g class="comb phase-Running"> >> per cell. The class is
C<comb>, C<phase-E<lt>PhaseE<gt>> (see L</phases>), plus C<borrowed> when the
Comb really takes its service from an upstream layer (dashed outline, a line
naming the upstream context; see
L<borrowed|Kubernetes::Comb::SVG::Cell/borrowed>: an upstream is recorded, it
is not unreachable, and the phase is Running or Pending) and C<disabled> for a
Disabled one. Attributes: C<data-name> (C<metadata.name>), C<data-id>
(C<namespace/name>, or the name alone), C<data-phase>. With L</link> the group
sits inside an C<< <a> >>. Inside, in this order:

=over

=item * C<< <title> >>, the tooltip: id, namespace, class, phase, the message
when the phase is not Running, endpoints, upstream, missing dependencies. The
upstream line is there for every Comb that records one:
C<upstream: E<lt>classE<gt>, context E<lt>contextE<gt>>, either part alone
when the other is absent, C<upstream: recorded> with neither, followed by
C<(not borrowing)> when the cell is not borrowed; a C<via:> line follows when
the upstream names a chain. The tooltip also carries the full name of a cell
whose drawn name had to be cut.

=item * C<polygon.hex>, the hexagon.

=item * C<text.name>, the name. A name that fits stays on one line. One that
does not is broken into two after a hyphen, a dot or an underscore, each line a
C<< <tspan> >> inside C<text.name>, at the break that leaves the shortest
longer line. When the two lines are still too wide the element has the class
C<name-small> as well and a smaller font (13 characters a line instead of 11).
Only what fits neither way is cut with an ellipsis, as is a too long name
without such a character.

=item * C<text.phase>, the phase, always written as text, never by colour
alone.

=item * C<text.reason>, only for a Comb that is not Running and says why: the
L<reason|Kubernetes::Comb::SVG::Cell/reason> of the cell in small text, 16
characters a line. It is what a wall screen shows in place of the tooltip; a
Running cell never has it. A reason too long for one line is broken into two,
each a C<< <tspan> >> inside C<text.reason>: at a run of whitespace, which is
dropped, or before an upper-case letter that follows a lower-case letter or a
digit (C<Missing> / C<Prerequisites>), at the break that leaves the shortest
longer line. When no break makes both lines fit, the last one whose first line
fits is taken and the second line is cut with an ellipsis; a reason without
such a break is cut on its one line. The six-line exception: a cell with no
room for a sixth line of text -- a name on two lines, the phase, two reason
lines and an upstream line -- cuts a too long reason on one line as well.
Under a name on two lines the second reason line sits where the hexagon
narrows and holds 14 characters, 15 under a name in the smaller font.

=item * C<text.upstream>, only for a borrowed Comb: C<from E<lt>contextE<gt>>,
or C<borrowed> when no context is recorded.

=back

A cell with a reason line and more than three lines of text sets them closer
together, the phase a little further from the name than the name lines are
from each other.

=item * C<g.deps> holds one C<path.dep> per dependency, with C<data-from> (the
dependent) and C<data-to> (the dependency) as ids, an arrowhead at the
dependency, and a C<circle.dep-start> marking where it leaves the dependent.
It is drawn before the cells, so cells stay on top; it is absent with
C<< edges => 0 >> and when there are no edges.

=item * C<g.group> per group heading, with C<data-group> (the label value)
unless it is the group without a name; holds C<text.group-name> and a faint
C<line.group-rule>. Only present when the picture has headings, see
L</group_label>.

=item * C<g.legend> holds one C<g.legend-item.phase-E<lt>PhaseE<gt>> per
phase that occurs, with C<data-phase> and C<data-count>.

=item * One C<< <style> >> element. Colours are CSS custom properties on
C<.comb-svg>, see L</Styling from outside>. A
C<@media (prefers-color-scheme: dark)> block gives the dark values. The font
is the system sans stack.

=item * With L</blink>, the same C<< <style> >> holds C<@keyframes comb-blink>,
an C<animation> named C<comb-blink> on C<.comb.phase-E<lt>PhaseE<gt> .hex> for
each blinking phase, and a C<@media (prefers-reduced-motion: reduce)> block
that turns the animation off and thickens the outline. Without L</blink> none
of this is in the document.

=back

=head2 Styling from outside

When the SVG is inlined into a page, the CSS of that page can restyle it. The
custom property names, the class names and the animation name are public
interface; the rest of the markup is not promised to stay as it is.

Custom properties, set on C<.comb-svg> (light values), and again inside
C<@media (prefers-color-scheme: dark)> (dark values):

=over

=item * C<--comb-bg>, C<--comb-fg>, C<--comb-muted>, C<--comb-border>,
C<--comb-edge>: the panel, the text, secondary text (group names, phase,
reason and upstream line, legend), the outline of the panel and the group rules, and the dependency
edges

=item * C<--comb-running>, C<--comb-pending>, C<--comb-blocked>,
C<--comb-needsconfig>, C<--comb-disabled>, C<--comb-error>, C<--comb-stopped>,
C<--comb-notdeployed>, C<--comb-unknown>:
the colour of each phase (the name is C<--comb-> and the lower-case phase);
it is the outline of the hexagon and, at low opacity, its fill

=item * C<--comb-tint> and C<--comb-tint-muted>: the fill opacity of a
hexagon and of a Disabled one

=back

Classes: C<.comb> per cell with C<.phase-E<lt>PhaseE<gt>>, C<.borrowed> and
C<.disabled> (the C<.phase-E<lt>PhaseE<gt>> class is also on the entries of
the legend); inside it C<.hex>, C<.name> (with C<.name-small> for a
name on two lines in the smaller font; its rule is in the C<< <style> >> only
when a cell needs it), C<.phase>, C<.reason> (its rule, too, is there only
when a cell has a reason line) and C<.upstream>. Around
them C<.panel>, C<.heading>, C<.group>, C<.group-name> and C<.group-rule>;
C<.deps> with C<.dep>, C<.arrow> and C<.dep-start>; C<.legend> with
C<.legend-item> and C<.count>. The animation is named C<comb-blink>.

The built-in custom properties sit on C<.comb-svg> itself, and the
C<< <style> >> is part of the document, so whether a page rule with the same
selector wins depends on which comes later. Use a more specific selector, such
as C<svg.comb-svg>, to win regardless. The dark block is a rule of its own: a
colour a page sets that way holds in dark mode too, unless the page sets the
dark one in its own media query.

  /* in the CSS of the embedding page */
  svg.comb-svg {
    --comb-error: #ff0033;
    --comb-bg: #fafafa;
  }
  @media (prefers-color-scheme: dark) {
    svg.comb-svg { --comb-error: #ff6680; --comb-bg: #101010 }
  }
  /* dim the Combs that are fine */
  svg.comb-svg .comb.phase-Running { opacity: .6 }
  /* a different pulse: override animation on the hexagon of a blinking phase */
  svg.comb-svg .comb.phase-Error .hex { animation-duration: .6s }

Setting L</theme> instead needs no page CSS: it writes the same properties.

The picture is self-contained: no script, no web font, no stylesheet link, no
image, no reference to anything outside the document (the arrowhead is a
C<< <marker> >> inside it). Every value that comes from a custom resource --
names, namespaces, messages, reasons, label values, upstream classes and contexts, a L</link>
result -- is escaped wherever it lands, in text, in C<< <title> >> and in
attributes, and the five XML special characters become entities. Characters
XML 1.0 cannot carry are dropped, and everything outside ASCII becomes a
numeric character reference. A Comb named C<< </svg><script> >> comes out as
text.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::SVG::Cell>

=item * L<Kubernetes::Comb::SVG::Layout>

=item * L<comb-svg>

=item * L<Kubernetes::Comb>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb-svg/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
