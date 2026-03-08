package Graphics::Penplotter::GcodeXY::SVG v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Carp            qw( croak );
use Readonly        qw( Readonly );
use Math::Trig      qw( acos tan );
use List::Util      qw( max );
use POSIX           qw( ceil );
use Image::SVG::Transform ();
use Image::SVG::Path      qw( extract_path_info );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::SVG
# Role providing SVG import for GcodeXY.
# ---------------------------------------------------------------------------

requires qw(gsave grestore translate scale rotate skewX skewY _premulmat line
    box boxround circle ellipse polygon curve moveto stroke penup pendown
    _genfastmove _genslowmove stroketext setfont currentpoint _croak
    _flushPsegments _parse);

# ---------------------------------------------------------------------------
# Constants -- private copies of values from GcodeXY.pm.
# ---------------------------------------------------------------------------

Readonly my $TWOPI     => 6.28318530718;
Readonly my $EOL       => qq{\n};
Readonly my $SPACE     => q{ };
Readonly my $EMPTY_STR => q{};
Readonly my $I2P       => 72.0;          # inches to points scale factor
Readonly my $BBMAX     => 1_000_000.0;   # sentinel for bounding box initialisation
Readonly my $G00       => 3;             # G00 line opcode (fast move)
Readonly my $G01       => 4;             # G01 line opcode (slow move / draw)

# ---------------------------------------------------------------------------
# Unit conversion tables -- copied from GcodeXY.pm.
# ---------------------------------------------------------------------------

my %unit_to_inches = (
    px => 1.0/96.0,
    pt => 1.0/72.0,
    pc => 1.0/6.0,
    in => 1.0,
    cm => 1.0/2.54,
    mm => 1.0/25.4,
);

my %inches_to_unit = (
    pt => 72.0,
    in => 1.0,
    mm => 25.4,
    cm => 2.54,
    px => 96.0,
    pc => 6.0,
);

# ---------------------------------------------------------------------------
# Module-level state for SVG import.
# These are reset at the start of each importsvg() call.
# ---------------------------------------------------------------------------

my %_svg_defs        = ();   # id => XML::LibXML::Node
my @_svg_style_stack = ();   # reserved for future CSS inheritance
my %_svg_css_rules   = ();   # selector => { property => value }


# ===========================================================================
# PUBLIC ENTRY POINT: exportsvg
# ===========================================================================

sub exportsvg ($self, $gcout = undef) {
    if (!$gcout) { die 'exportsvg: output filename not provided' }
    my $op         = $EMPTY_STR;
    my $xn         = $EMPTY_STR;
    my $yn         = $EMPTY_STR;
    my $maxx       = 0.0;
    my $maxy       = 0.0;
    my $minx       = $BBMAX;
    my $miny       = $BBMAX;
    my $linecount  = 0;
    my ( $x, $y, $line, $st );
    $self->_flushPsegments();
    my $limit = scalar @{ $self->{currentpage} };
    if ( !$limit ) {
        croak "exportsvg: $gcout: empty queue. Aborting.";
        return 0;
    }
    open( my $out, '>', $gcout ) or croak "exportsvg: cannot open output file $gcout";
    # Skip the gcode header, stopping at the first pen-up command
    HEADER:
    while (1) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        last HEADER if $line eq $self->{penupcmd};
    }
    # Collect SVG path data and compute bounding box in one pass
    $st = $EMPTY_STR;
    while ( $linecount < $limit ) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        ( $op, $xn, $yn ) = $self->_parse($line);    # coords in inches
        if ( $op eq $G00 || $op eq $G01 ) {
            $x = 0.0 + $xn;
            $y = 0.0 + $yn;
            if ( $x > $maxx ) { $maxx = $x }
            if ( $y > $maxy ) { $maxy = $y }
            if ( $x < $minx ) { $minx = $x }
            if ( $y < $miny ) { $miny = $y }
        }
        if    ( $op eq $G01 ) {
            $st .= 'L' . ($xn * $I2P) . $SPACE . ($yn * $I2P) . $SPACE;
        }
        elsif ( $op eq $G00 ) {
            $st .= 'M' . ($xn * $I2P) . $SPACE . ($yn * $I2P) . $SPACE;
        }
        # PU and PD are ignored
    }
    # Write SVG header
    my $hdr = "<svg" . $EOL;
    $hdr .= "xmlns='http://www.w3.org/2000/svg'>" . $EOL;
    $hdr .= "<path style='fill:white; fill-opacity:0; stroke:black; " . $EOL;
    $hdr .= "stroke-opacity:1; stroke-width: 0.5'" . $EOL;
    $hdr .= "d=\"";
    print {$out} $hdr;
    # Write path data, wrapping long lines at word boundaries
    my $max_length = 120;
    while ( length($st) > $max_length ) {
        my $chunk       = substr( $st, 0, $max_length );
        my $break_point = rindex( $chunk, ' ' );
        $break_point    = $max_length if $break_point == -1;
        my $line        = substr( $st, 0, $break_point, '' );
        print {$out} $line, $EOL;
        $st =~ s/^\s+//;
    }
    print {$out} $st, $EOL if $st;
    # Write SVG trailer
    print {$out} "\"/></svg> " . $EOL;
    close $out;
    # Convert bounding box to points and optionally report it
    $minx *= $I2P;
    $miny *= $I2P;
    $maxx *= $I2P;
    $maxy *= $I2P;
    if ( $self->{check} ) {
        print STDOUT "exportsvg: $gcout: bounding box = ($minx,$miny)pt ($maxx,$maxy)pt" . $EOL;
    }
    return ( $minx, $miny, $maxx, $maxy );
}

# ===========================================================================
# PUBLIC ENTRY POINT: importsvg
# ===========================================================================

sub importsvg ($self, $file) {
    eval { require XML::LibXML; XML::LibXML->import(); 1 } or do {
        $self->_croak("XML::LibXML is required to import SVG files: $@");
    };

    my $parser = XML::LibXML->new();
    my $doc;
    eval { $doc = $parser->load_xml( location => $file ); 1 } or do {
        $self->_croak("XML parse error in $file: $@");
    };

    # Reset module-level state for this import
    %_svg_defs        = ();
    @_svg_style_stack = ();
    %_svg_css_rules   = ();

    if ($self->{check}) {
        print STDOUT "$file:$EOL";
    }

    $self->gsave();

    my $root = $doc->documentElement();

    # Pass 1: collect <defs> and <style> before rendering, so that
    # forward references from <use> resolve correctly.
    _svg_collect_defs($self, $root);

    # Pass 2: render.
    # Route the root <svg> through _handle_svg so its viewBox/width/height
    # attributes are applied. (_traverse only processes children, so the
    # root element's own attributes would otherwise be silently ignored.)
    my %root_attr = _collect_attrs($root);
    my %root_eff  = _svg_effective_style($self, \%root_attr);
    _handle_svg($self, $root, \%root_attr, \%root_eff);

    $self->grestore();
    return 1;
}


# ===========================================================================
# PASS 1: collect defs and CSS
# ===========================================================================

sub _svg_collect_defs ($self, $node) {
    for my $child ($node->childNodes) {
        next unless $child->nodeType == 1;
        my $tag = lc $child->localname;

        if ($tag eq 'defs' || $tag eq 'symbol') {
            _svg_index_ids($child);
            _svg_collect_defs($self, $child);
        }
        elsif ($tag eq 'style') {
            _css_parse_block( $child->textContent // '' );
        }
        else {
            _svg_index_ids($child);
            _svg_collect_defs($self, $child);
        }
    }
}

sub _svg_index_ids ($node) {
    my $id = $node->getAttribute('id') // $node->getAttribute('xml:id');
    if (defined $id && $id ne '') {
        $_svg_defs{$id} = $node;
    }
    for my $child ($node->childNodes) {
        next unless $child->nodeType == 1;
        _svg_index_ids($child);
    }
}


# ===========================================================================
# PASS 2: recursive traversal
# ===========================================================================

sub _traverse ($self, $node) {
    return unless $node;
    for my $child ($node->childNodes) {
        next unless $child->nodeType == 1;
        my %attr = _collect_attrs($child);
        my $tag  = lc $child->localname;

        my %eff = _svg_effective_style($self, \%attr);

        next if ($eff{display}    // '') eq 'none';
        next if ($eff{visibility} // '') eq 'hidden';

        _handle_element($self, $child, $tag, \%attr, \%eff);
    }
}

sub _collect_attrs ($node) {
    my %attr;
    for my $a ($node->attributes) {
        my $name = $a->nodeName;
        $name =~ s/^xlink://;    # xlink:href -> href
        $attr{$name} = $a->value;
    }
    return %attr;
}


# ===========================================================================
# ELEMENT DISPATCHER
# ===========================================================================

sub _handle_element ($self, $node, $tag, $attr, $eff) {

    # --- Container / structural elements --------------------------------

    if ($tag eq 'svg') {
        _handle_svg($self, $node, $attr, $eff);
        return;
    }

    if ($tag eq 'g' || $tag eq 'a' || $tag eq 'switch') {
        $self->gsave();
        _apply_transform($self, $attr->{transform});
        _traverse($self, $node);
        $self->grestore();
        return;
    }

    if ($tag eq 'defs' || $tag eq 'symbol') {
        return;    # rendered only when instantiated by <use>
    }

    if ($tag eq 'use') {
        _handle_use($self, $node, $attr, $eff);
        return;
    }

    # --- Metadata / non-geometric elements ------------------------------

    if ($tag =~ /\A(?:title|desc|metadata|style|script|animate.*|set|mpath)\z/) {
        return;
    }

    if ($tag eq 'image') {
        if ($self->{check}) {
            print STDOUT "importsvg: <image> ignored (raster, not plottable)$EOL";
        }
        return;
    }

    if ($tag eq 'foreignobject') {
        return;
    }

    # --- Gradient / pattern / clip / marker definitions -----------------

    if ($tag =~ /\A(?:lineargradient|radialgradient|pattern|clippath|mask|filter|marker)\z/) {
        return;
    }

    # --- Geometric elements ---------------------------------------------

    $self->gsave();
    _apply_transform($self, $attr->{transform});

    if    ($tag eq 'path')     { _handle_path    ($self, $attr) }
    elsif ($tag eq 'line')     { _handle_line    ($self, $attr) }
    elsif ($tag eq 'rect')     { _handle_rect    ($self, $attr) }
    elsif ($tag eq 'circle')   { _handle_circle  ($self, $attr) }
    elsif ($tag eq 'ellipse')  { _handle_ellipse ($self, $attr) }
    elsif ($tag eq 'polyline') { _handle_polyline($self, $attr, 0) }
    elsif ($tag eq 'polygon')  { _handle_polyline($self, $attr, 1) }
    elsif ($tag eq 'text')     { _handle_text    ($self, $node, $attr, $eff) }
    elsif ($tag eq 'tspan')    { _handle_tspan   ($self, $node, $attr, $eff) }
    else {
        if ($self->{check}) {
            print STDOUT "importsvg: unhandled element <$tag>$EOL";
        }
    }

    $self->grestore();
}


# ===========================================================================
# <svg> root and nested viewport
# ===========================================================================

sub _handle_svg ($self, $node, $attr, $eff) {
    $self->gsave();
    if ($self->{check} && defined $attr->{width} && defined $attr->{height}) {
        print STDOUT "SVG size: $attr->{width} x $attr->{height}$EOL";
    }
    _svg_viewbox_transform($self, $attr) if defined $attr->{viewBox};
    _apply_transform($self, $attr->{transform});
    _traverse($self, $node);
    $self->grestore();
}


# ===========================================================================
# viewBox mapping
# ===========================================================================

sub _svg_viewbox_transform ($self, $attr) {
    my $vb = $attr->{viewBox} // return;
    $vb =~ s/,/ /g;
    my ($vbx, $vby, $vbw, $vbh) = split /\s+/, $vb;
    return unless defined $vbw && $vbw > 0 && defined $vbh && $vbh > 0;

    my $vpw = defined $attr->{width}  ? $self->_svgconvert($attr->{width})  : $self->{xsize};
    my $vph = defined $attr->{height} ? $self->_svgconvert($attr->{height}) : $self->{ysize};
    return unless defined $vpw && $vpw > 0 && defined $vph && $vph > 0;

    my $par = $attr->{preserveAspectRatio} // 'xMidYMid meet';

    my ($sx, $sy);
    if ($par =~ /none/i) {
        $sx = $vpw / $vbw;
        $sy = $vph / $vbh;
    }
    else {
        my $s = ($vpw / $vbw < $vph / $vbh) ? $vpw / $vbw : $vph / $vbh;
        $sx = $sy = $s;
    }

    $self->translate(-$vbx * $sx, -$vby * $sy);
    $self->scale($sx, $sy);

    if ($self->{check}) {
        printf STDOUT "SVG viewBox: (%g %g %g %g) -> scale (%g, %g)$EOL",
            $vbx, $vby, $vbw, $vbh, $sx, $sy;
    }
}


# ===========================================================================
# <use> -- symbol instantiation
# ===========================================================================

sub _handle_use ($self, $node, $attr, $eff) {
    my $href = $attr->{href} // $attr->{'xlink:href'} // '';
    $href =~ s/^#//;

    unless (defined $_svg_defs{$href}) {
        if ($self->{check}) {
            print STDOUT "importsvg: <use> references unknown id '$href'$EOL";
        }
        return;
    }

    my $target = $_svg_defs{$href};
    my $ttag   = lc $target->localname;

    $self->gsave();
    _apply_transform($self, $attr->{transform});
    my $ux = defined $attr->{x} ? $self->_svgconvert($attr->{x}) : 0;
    my $uy = defined $attr->{y} ? $self->_svgconvert($attr->{y}) : 0;
    $self->translate($ux, $uy) if ($ux || $uy);

    if ($ttag eq 'symbol') {
        my %tattr = _collect_attrs($target);
        $self->gsave();
        _svg_viewbox_transform($self, \%tattr) if defined $tattr{viewBox};
        _traverse($self, $target);
        $self->grestore();
    }
    else {
        my %tattr = _collect_attrs($target);
        my %teff  = _svg_effective_style($self, \%tattr);
        _handle_element($self, $target, $ttag, \%tattr, \%teff);
    }

    $self->grestore();
}


# ===========================================================================
# GEOMETRIC ELEMENT HANDLERS
# ===========================================================================

sub _handle_path ($self, $attr) {
    my $d = $attr->{d} // return;
    $self->_dopath($d);
}

sub _handle_line ($self, $attr) {
    my $x1 = $self->_svgconvert($attr->{x1} // 0);
    my $y1 = $self->_svgconvert($attr->{y1} // 0);
    my $x2 = $self->_svgconvert($attr->{x2} // 0);
    my $y2 = $self->_svgconvert($attr->{y2} // 0);
    $self->line($x1, $y1, $x2, $y2);
}

sub _handle_rect ($self, $attr) {
    my $x  = $self->_svgconvert($attr->{x}      // 0);
    my $y  = $self->_svgconvert($attr->{y}      // 0);
    my $w  = $self->_svgconvert($attr->{width}  // 0);
    my $h  = $self->_svgconvert($attr->{height} // 0);
    return if $w <= 0 || $h <= 0;

    my $rx = defined $attr->{rx} ? $self->_svgconvert($attr->{rx}) : undef;
    my $ry = defined $attr->{ry} ? $self->_svgconvert($attr->{ry}) : undef;
    $rx //= $ry;
    $ry //= $rx;

    if ($rx) {
        $rx = $w / 2 if $rx > $w / 2;
        $ry = $h / 2 if $ry > $h / 2;
        $self->boxround($x, $y, $x + $w, $y + $h, $rx);
    }
    else {
        $self->box($x, $y, $x + $w, $y + $h);
    }
}

sub _handle_circle ($self, $attr) {
    my $cx = $self->_svgconvert($attr->{cx} // 0);
    my $cy = $self->_svgconvert($attr->{cy} // 0);
    my $r  = $self->_svgconvert($attr->{r}  // 0);
    return if $r <= 0;
    $self->circle($cx, $cy, $r);
}

sub _handle_ellipse ($self, $attr) {
    my $cx = $self->_svgconvert($attr->{cx} // 0);
    my $cy = $self->_svgconvert($attr->{cy} // 0);
    my $rx = $self->_svgconvert($attr->{rx} // 0);
    my $ry = $self->_svgconvert($attr->{ry} // 0);
    return if $rx <= 0 || $ry <= 0;
    $self->ellipse($cx, $cy, $rx, $ry);
}

sub _handle_polyline ($self, $attr, $close) {
    my $pts = $attr->{points} // return;
    $pts =~ s/,/ /g;
    $pts =~ s/\s+/ /g;
    $pts =~ s/^\s+//;
    my @c = map { $self->_svgconvert($_) } split / /, $pts;
    return unless @c >= 4;
    push @c, $c[0], $c[1] if $close;
    $self->polygon(@c);
}


# ===========================================================================
# TEXT HANDLING
# ===========================================================================

sub _handle_text ($self, $node, $attr, $eff) {
    my $x = defined $attr->{x} ? $self->_svgconvert($attr->{x}) : 0;
    my $y = defined $attr->{y} ? $self->_svgconvert($attr->{y}) : 0;
    $self->gsave();
    $self->translate($x, $y);
    my $text = _collect_text_content($node);
    _render_text_content($self, $text, $attr, $eff) if $text =~ /\S/;
    $self->grestore();
}

sub _handle_tspan ($self, $node, $attr, $eff) {
    my $dx = defined $attr->{dx} ? $self->_svgconvert($attr->{dx}) : 0;
    my $dy = defined $attr->{dy} ? $self->_svgconvert($attr->{dy}) : 0;
    $self->gsave();
    if (defined $attr->{x} && defined $attr->{y}) {
        $self->translate($self->_svgconvert($attr->{x}),
                         $self->_svgconvert($attr->{y}));
    }
    elsif ($dx || $dy) {
        my ($cx, $cy) = $self->currentpoint();
        $self->translate($cx + $dx, $cy + $dy);
    }
    my $text = _collect_text_content($node);
    _render_text_content($self, $text, $attr, $eff) if $text =~ /\S/;
    $self->grestore();
}

sub _collect_text_content ($node) {
    my $text = '';
    for my $child ($node->childNodes) {
        if ($child->nodeType == 3) {
            $text .= $child->data;
        }
        elsif ($child->nodeType == 1 && lc $child->localname eq 'tspan') {
            $text .= _collect_text_content($child);
        }
    }
    return $text;
}

sub _render_text_content ($self, $text, $attr, $eff) {
    my $fontsize = _css_property($eff, 'font-size')
                // $attr->{'font-size'}
                // $self->{fontsize}
                // 12;
    $fontsize =~ s/[a-z]+$//i;

    my $fontname = _css_property($eff, 'font-family')
                // $attr->{'font-family'}
                // $self->{fontname}
                // '';

    if ($fontname && $fontsize) {
        my $face = eval { $self->setfont($fontname, $fontsize) };
        if ($face) { $self->stroketext($face, $text); return; }
    }
    if ($self->{fontname} && $self->{fontsize}) {
        my $face = eval { $self->setfont($self->{fontname}, $self->{fontsize}) };
        if ($face) { $self->stroketext($face, $text); return; }
    }
    if ($self->{check}) {
        print STDOUT "importsvg: text '$text' skipped (no font set)$EOL";
    }
}


# ===========================================================================
# TRANSFORM HANDLING
# The name _apply_transform is used internally; the public name
# _dotransform is aliased below for any legacy callers.
# ===========================================================================

sub _apply_transform ($self, $t) {
    return unless defined $t && $t ne '';

    my @calls;
    while ($t =~ /(\w+)\s*\(([^)]*)\)/g) {
        push @calls, { type => lc $1, params => [ split /[\s,]+/, $2 ] };
    }

    for my $c (@calls) {
        my @p = @{ $c->{params} };

        if ($c->{type} eq 'translate') {
            my $tx = $self->_svgconvert($p[0] // 0);
            my $ty = defined $p[1] ? $self->_svgconvert($p[1]) : 0;
            $self->translate($tx, $ty);
        }
        elsif ($c->{type} eq 'scale') {
            my $sx = $p[0] // 1;
            my $sy = defined $p[1] ? $p[1] : $sx;
            $self->scale($sx, $sy);
        }
        elsif ($c->{type} eq 'rotate') {
            my $angle = $p[0] // 0;
            if (defined $p[1] && defined $p[2]) {
                # Use GcodeXY's 3-arg rotate directly -- the translate-based
                # workaround used GcodeXY's non-standard translate() which
                # replaces CTM[0][2]/[1][2] rather than post-multiplying,
                # giving the wrong result for non-origin centres.
                my $cx = $self->_svgconvert($p[1]);
                my $cy = $self->_svgconvert($p[2]);
                $self->rotate($angle, $cx, $cy);
            }
            else {
                $self->rotate($angle);
            }
        }
        elsif ($c->{type} eq 'skewx') { $self->skewX($p[0] // 0) }
        elsif ($c->{type} eq 'skewy') { $self->skewY($p[0] // 0) }
        elsif ($c->{type} eq 'matrix') {
            # SVG matrix(a,b,c,d,e,f) is column-major: a-d are the 2x2
            # linear part (dimensionless); e,f are translation and may carry units.
            my ($a, $b, $c_, $d, $e, $f) = @p;
            $e = $self->_svgconvert($e // 0);
            $f = $self->_svgconvert($f // 0);
            my @matrix = (
                [ $a,  $c_, $e ],
                [ $b,  $d,  $f ],
                [ 0,   0,   1  ],
            );
            $self->_premulmat(\@matrix, \@{ $self->{CTM} });
        }
    }
}

# Legacy alias used by GcodeXY.pm internals if still present
*_dotransform = \&_apply_transform;


# ===========================================================================
# CSS STYLE HANDLING
# ===========================================================================

sub _svg_effective_style ($self, $attr) {
    my %eff;

    # 1. Class rules (lowest priority)
    if (defined $attr->{class}) {
        for my $cls (split /\s+/, $attr->{class}) {
            my $rules = $_svg_css_rules{".$cls"} // {};
            %eff = (%eff, %$rules);
        }
    }

    # 2. Presentation attributes
    for my $prop (qw(display visibility font-family font-size font-weight)) {
        $eff{$prop} = $attr->{$prop} if defined $attr->{$prop};
    }

    # 3. Inline style (highest priority)
    if (defined $attr->{style}) {
        my %inline = _parse_style_attr($attr->{style});
        %eff = (%eff, %inline);
    }

    return %eff;
}

sub _parse_style_attr ($style) {
    my %props;
    for my $decl (split /;/, $style) {
        $decl =~ s/^\s+|\s+$//g;
        next unless $decl =~ /:/;
        my ($prop, $val) = split /:/, $decl, 2;
        $prop =~ s/^\s+|\s+$//g;
        $val  =~ s/^\s+|\s+$//g;
        $props{ lc $prop } = $val if defined $val;
    }
    return %props;
}

sub _css_parse_block ($css) {
    $css =~ s{/\*.*?\*/}{}gs;
    while ($css =~ /([^{]+)\{([^}]*)\}/g) {
        my ($sel_list, $decls) = ($1, $2);
        my %props = _parse_style_attr($decls);
        for my $sel (split /,/, $sel_list) {
            $sel =~ s/^\s+|\s+$//g;
            next unless $sel =~ /\A[\w.-]+\z/;
            $_svg_css_rules{$sel} = { %{ $_svg_css_rules{$sel} // {} }, %props };
        }
    }
}

sub _css_property ($eff, $prop) {
    return $eff->{$prop} if defined $eff->{$prop};
    (my $camel = $prop) =~ s/-([a-z])/uc($1)/ge;
    return $eff->{$camel};
}


# ===========================================================================
# UNIT CONVERSION
# These replace _svg_value_to_inches and _svgconvert in GcodeXY.pm.
# Both methods should be REMOVED from GcodeXY.pm.
# ===========================================================================

sub _svg_value_to_inches ($value) {
    # Support negative values (e.g. x='-0.5in') and optional whitespace.
    my ($num, $unit) = $value =~ /^\s*([+-]?[\d.]+)\s*(\D*)\s*$/;
    return undef unless defined $num;
    $num += 0;
    return $num if !defined $unit || $unit eq '';  # bare number: SVG user units
    $unit = lc $unit;
    $unit = 'px' unless exists $unit_to_inches{$unit};
    return $num * $unit_to_inches{$unit};
}

sub _svgconvert ($self, $value) {
    $self->_croak('svgconvert: no value provided') unless defined $value;
    # Bare numbers are SVG user units.  When a viewBox transform is active
    # the CTM encodes the user-unit->GcodeXY mapping, so return them as-is.
    # Applying px conversion (1/96) would break viewBox coordinate scaling.
    return $value + 0 if $value =~ /^\s*[+-]?[\d.]+\s*$/;
    my $inches = _svg_value_to_inches($value);
    return undef unless defined $inches;
    return $inches * $inches_to_unit{ $self->{units} };
}


# ===========================================================================
# PATH PROCESSING
# _dopath replaces the version in GcodeXY.pm (remove it from there).
# ===========================================================================

sub _dopath ($self, $d) {
    # SVG path data must be unitless per spec; strip any unit suffixes that
    # may appear in hand-crafted or test SVGs (e.g. '1in' -> '1').
    $d =~ s/(\d)\s*(?:in|mm|cm|px|pt|em|rem)\b/$1/gi;
    my @r    = extract_path_info( $d, { absolute => 1, no_smooth => 1 } );
    my $x    = undef;
    my $y    = undef;
    my $curx = 0;
    my $cury = 0;
    my ($xa, $ya);

    for (@r) {
        if ( $_->{svg_key} =~ m{\A[mM]\z}i ) {
            $self->moveto( $_->{point}[0], $_->{point}[1] );
            $x    = $_->{point}[0];
            $y    = $_->{point}[1];
            $curx = $_->{point}[0];
            $cury = $_->{point}[1];
        }
        if ( $_->{svg_key} =~ m{\A[lL]\z}i ) {
            $self->line( $_->{point}[0], $_->{point}[1] );
            $curx = $_->{point}[0];
            $cury = $_->{point}[1];
        }
        if ( $_->{svg_key} =~ m{\A[vV]\z}i ) {
            $self->line( $curx, $_->{y} );
            $cury = $_->{y};
        }
        if ( $_->{svg_key} =~ m{\A[hH]\z}i ) {
            $self->line( $_->{x}, $cury );
            $curx = $_->{x};
        }
        if ( $_->{svg_key} =~ m{\A[zZ]\z}i ) {
            $self->line( $x, $y );
            $curx = $x;
            $cury = $y;
        }
        if ( $_->{svg_key} =~ m{\A[cC]\z}i ) {
            ($xa, $ya) = $self->currentpoint();
            $self->curve(
                $xa,              $ya,
                $_->{control1}[0], $_->{control1}[1],
                $_->{control2}[0], $_->{control2}[1],
                $_->{end}[0],      $_->{end}[1],
            );
            $curx = $_->{end}[0];
            $cury = $_->{end}[1];
        }
        if ( $_->{svg_key} =~ m{\A[qQ]\z}i ) {
            ($xa, $ya) = $self->currentpoint();
            $self->curve(
                $xa,              $ya,
                $_->{control}[0], $_->{control}[1],
                $_->{end}[0],     $_->{end}[1],
            );
            $curx = $_->{end}[0];
            $cury = $_->{end}[1];
        }
        if ( $_->{svg_key} =~ m{\A[sS]\z}i ) {
            if ($self->{check}) {
                print STDOUT "path internal error: s or S command found$EOL";
            }
        }
        if ( $_->{svg_key} =~ m{\A[tT]\z}i ) {
            if ($self->{check}) {
                print STDOUT "path internal error: t or T command found$EOL";
            }
        }
        if ( $_->{svg_key} =~ m{\A[aA]\z}i ) {
            ($xa, $ya) = $self->currentpoint();
            $self->_a2c( $xa, $ya,
                $_->{rx}, $_->{ry}, $_->{x_axis_rotation},
                $_->{large_arc_flag}, $_->{sweep_flag},
                $_->{x}, $_->{y} );
            $curx = $_->{x};
            $cury = $_->{y};
        }
    }
    return 1;
}


# ===========================================================================
# ARC MATH
# These three functions and _a2c replace the versions in GcodeXY.pm.
# Remove the originals from GcodeXY.pm.
# ===========================================================================

sub _unit_vector_angle ($ux, $uy, $vx, $vy) {
    my $sign = ($ux * $vy - $uy * $vx < 0) ? -1 : 1;
    my $dot  = $ux * $vx + $uy * $vy;
    $dot /= sqrt($ux*$ux + $uy*$uy) * sqrt($vx*$vx + $vy*$vy);
    $dot =  1.0 if $dot >  1.0;
    $dot = -1.0 if $dot < -1.0;
    return $sign * acos($dot);
}

sub _get_arc_center ($x1, $y1, $x2, $y2, $fa, $fs, $rx, $ry, $sin_phi, $cos_phi) {
    my $x1p    = $cos_phi  * ($x1 - $x2) / 2 + $sin_phi  * ($y1 - $y2) / 2;
    my $y1p    = -$sin_phi * ($x1 - $x2) / 2 + $cos_phi  * ($y1 - $y2) / 2;
    my $rx_sq  = $rx * $rx;
    my $ry_sq  = $ry * $ry;
    my $x1p_sq = $x1p * $x1p;
    my $y1p_sq = $y1p * $y1p;
    my $radicant = ($rx_sq * $ry_sq) - ($rx_sq * $y1p_sq) - ($ry_sq * $x1p_sq);
    $radicant = 0 if $radicant < 0;
    $radicant /= ($rx_sq * $y1p_sq) + ($ry_sq * $x1p_sq);
    $radicant = sqrt($radicant) * ($fa == $fs ? -1 : 1);
    my $cxp = $radicant *  $rx / $ry * $y1p;
    my $cyp = $radicant * -$ry / $rx * $x1p;
    my $cx  = $cos_phi * $cxp - $sin_phi * $cyp + ($x1 + $x2) / 2;
    my $cy  = $sin_phi * $cxp + $cos_phi * $cyp + ($y1 + $y2) / 2;
    my $v1x = ( $x1p - $cxp) / $rx;
    my $v1y = ( $y1p - $cyp) / $ry;
    my $v2x = (-$x1p - $cxp) / $rx;
    my $v2y = (-$y1p - $cyp) / $ry;
    my $theta1      = _unit_vector_angle(1, 0, $v1x, $v1y);
    my $delta_theta = _unit_vector_angle($v1x, $v1y, $v2x, $v2y);
    $delta_theta -= $TWOPI if $fs == 0 && $delta_theta > 0;
    $delta_theta += $TWOPI if $fs == 1 && $delta_theta < 0;
    return ($cx, $cy, $theta1, $delta_theta);
}

sub _approximate_unit_arc ($theta1, $delta_theta) {
    my $alpha = 4 / 3 * tan($delta_theta / 4);
    my $x1    = cos $theta1;
    my $y1    = sin $theta1;
    my $x2    = cos($theta1 + $delta_theta);
    my $y2    = sin($theta1 + $delta_theta);
    return (
        $x1, $y1,
        $x1 - $y1 * $alpha,
        $y1 + $x1 * $alpha,
        $x2 + $y2 * $alpha,
        $y2 - $x2 * $alpha,
        $x2, $y2,
    );
}

sub _a2c ($self, $x1, $y1, $rx, $ry, $phi, $fa, $fs, $x2, $y2) {
    my $sin_phi = sin($phi * $TWOPI / 360);
    my $cos_phi = cos($phi * $TWOPI / 360);
    my $x1p     = $cos_phi * ($x1 - $x2) / 2 + $sin_phi * ($y1 - $y2) / 2;
    my $y1p     = -$sin_phi * ($x1 - $x2) / 2 + $cos_phi * ($y1 - $y2) / 2;
    return 0 if $x1p == 0 && $y1p == 0;
    return 0 if $rx  == 0 || $ry  == 0;
    $rx = abs $rx;
    $ry = abs $ry;
    my $lambda = ($x1p * $x1p) / ($rx * $rx) + ($y1p * $y1p) / ($ry * $ry);
    if ($lambda > 1) { $rx *= sqrt $lambda; $ry *= sqrt $lambda; }
    my @cc          = _get_arc_center($x1, $y1, $x2, $y2, $fa, $fs,
                                      $rx, $ry, $sin_phi, $cos_phi);
    my $theta1      = $cc[2];
    my $delta_theta = $cc[3];
    my $segments    = max(ceil(abs($delta_theta) / ($TWOPI / 4)), 1);
    $delta_theta   /= $segments;
    for (my $i = 0; $i < $segments; $i++) {
        my @curve = _approximate_unit_arc($theta1, $delta_theta);
        for (my $j = 0; $j < scalar @curve; $j += 2) {
            my $x  = $curve[$j]   * $rx;
            my $y  = $curve[$j+1] * $ry;
            my $xp = $cos_phi * $x - $sin_phi * $y;
            my $yp = $sin_phi * $x + $cos_phi * $y;
            $curve[$j]   = $xp + $cc[0];
            $curve[$j+1] = $yp + $cc[1];
        }
        $self->curve(@curve);
        $theta1 += $delta_theta;
    }
    return 1;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::SVG - SVG import role for GcodeXY

=head1 SYNOPSIS

    $g->importsvg('drawing.svg');

=head1 DESCRIPTION

A L<Role::Tiny> role that adds SVG import to
L<Graphics::Penplotter::GcodeXY>.

=head1 ELEMENTS SUPPORTED

C<svg>, C<g>, C<a>, C<switch>, C<defs>, C<use>, C<symbol>,
C<path>, C<line>, C<rect>, C<circle>, C<ellipse>, C<polyline>,
C<polygon>, C<text>, C<tspan>.

C<title>, C<desc>, C<metadata>, C<image>, C<linearGradient>,
C<radialGradient>, C<pattern>, C<clipPath>, C<mask>, C<filter>,
C<marker>, C<foreignObject> are silently ignored (appropriate for a
pen plotter).

=head1 METHODS

=over 4

=item importsvg($filename)

Parse the SVG file at C<$filename> and emit the vector content into the
current GcodeXY drawing.  A two-pass approach is used: all C<id>
attributes are indexed before rendering begins, so C<< <use> >> elements
that appear before their C<< <defs> >> target work correctly.

=back

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
