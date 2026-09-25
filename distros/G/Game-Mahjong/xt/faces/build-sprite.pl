#!/usr/bin/env perl
# build-sprite.pl - the forty-two faces as one SVG symbol sheet, and the two
# prototype pages that show them.
#
#   perl xt/faces/build-sprite.pl xt/faces/glyphs.json \
#       ../web/Peer2Peer-Site/root/templates/_mahjong_tiles.tmpl \
#       ../plan_mahjong/prototype
#
# Every symbol is 60 x 80. Dots and bamboo are primitives; the characters, the
# winds and two of the dragons are the traced paths of glyphs.json (Noto Sans
# CJK SC Bold, OFL), placed by a transform; the white dragon is a frame; a
# flower or a season is its number and a plain motif. Nothing in the sheet is
# text: the whole point is that no device font is consulted. The sheet is
# ASCII only and carries no style attribute the site's CSP would refuse.
#
# The tile BODY (ivory, edge, shadow, raised, selected, back) is not here: it
# is CSS on the element that carries the <use>, so a face is the same symbol on
# a rack, in a meld, in a pool and on a back. The colours in the sheet are the
# traditional ones and are fixed in both themes, like a playing card's.

use 5.010;
use strict;
use warnings;
use JSON::PP ();

my ($glyphs_path, $sprite_path, $proto_dir) = @ARGV;
die "usage: build-sprite.pl glyphs.json sprite.tmpl prototype-dir\n"
	unless $glyphs_path && $sprite_path && $proto_dir;

my $json = do { local $/; open my $fh, '<', $glyphs_path or die "$glyphs_path: $!"; <$fh> };
my $G = JSON::PP->new->decode($json)->{glyphs};

my $INK   = '#1e1a17';
my $RED   = '#b8322a';
my $GREEN = '#1f7a4d';
my $BLUE  = '#2f4c8a';
my $PINK  = '#c2527a';

# ---- placing a glyph ---------------------------------------------------------
# A glyph's path is in a 1000-unit em, y-down, baseline at 0. To draw it in a
# box (x, y, w, h) of the tile: scale so the glyph's own bounding box fills the
# box (keeping aspect), then translate. The bounding box is what centres it,
# not the advance, because a tile centres the ink and not the type.
sub glyph {
	my ($key, $x, $y, $w, $h, $fill) = @_;
	my $g = $G->{$key} or die "no glyph $key";
	my ($x1, $y1, $x2, $y2) = @{ $g->{box} };
	my ($gw, $gh) = ($x2 - $x1, $y2 - $y1);
	my $s = $w / $gw;
	$s = $h / $gh if $h / $gh < $s;
	my $tx = $x + ($w - $gw * $s) / 2 - $x1 * $s;
	my $ty = $y + ($h - $gh * $s) / 2 - $y1 * $s;
	return sprintf('<path fill="%s" transform="translate(%.2f %.2f) scale(%.4f)" d="%s"/>',
		$fill, $tx, $ty, $s, $g->{d});
}

# ---- the primitives ----------------------------------------------------------
sub dot {
	my ($cx, $cy, $r, $colour) = @_;
	return sprintf('<circle cx="%s" cy="%s" r="%s" fill="%s"/><circle cx="%s" cy="%s" r="%s" fill="#fbf7ee"/><circle cx="%s" cy="%s" r="%s" fill="%s"/>',
		$cx, $cy, $r, $colour, $cx, $cy, $r * 0.62, $cx, $cy, $r * 0.3, $colour);
}

sub stick {
	my ($cx, $cy, $colour) = @_;
	# a bamboo segment: a rounded bar with two joints
	return sprintf('<rect x="%s" y="%s" width="8" height="18" rx="3" fill="%s"/><rect x="%s" y="%s" width="10" height="2.5" rx="1" fill="#fbf7ee"/><rect x="%s" y="%s" width="10" height="2.5" rx="1" fill="#fbf7ee"/>',
		$cx - 4, $cy - 9, $colour, $cx - 5, $cy - 3.5, $cx - 5, $cy + 1);
}

# the layouts of the dots, as (cx, cy) in a 60 x 80 box
my %DOTS = (
	1 => [ [30, 40] ],
	2 => [ [30, 24], [30, 56] ],
	3 => [ [17, 22], [30, 40], [43, 58] ],
	4 => [ [19, 24], [41, 24], [19, 56], [41, 56] ],
	5 => [ [17, 22], [43, 22], [30, 40], [17, 58], [43, 58] ],
	6 => [ [19, 20], [41, 20], [19, 40], [41, 40], [19, 60], [41, 60] ],
	7 => [ [14, 16], [30, 22], [46, 28], [19, 46], [41, 46], [19, 64], [41, 64] ],
	8 => [ [19, 14], [41, 14], [19, 31], [41, 31], [19, 49], [41, 49], [19, 66], [41, 66] ],
	9 => [ [16, 19], [30, 19], [44, 19], [16, 40], [30, 40], [44, 40], [16, 61], [30, 61], [44, 61] ],
);
my %DOT_R = (1 => 14, 2 => 10, 3 => 9, 4 => 9, 5 => 8, 6 => 8, 7 => 7, 8 => 7, 9 => 7);

# the layouts of the bamboo, and which sticks are red (the tradition marks a few)
my %BAM = (
	2 => [ [30, 28, 'g'], [30, 52, 'g'] ],
	3 => [ [30, 24, 'g'], [19, 54, 'g'], [41, 54, 'g'] ],
	4 => [ [19, 28, 'g'], [41, 28, 'g'], [19, 52, 'g'], [41, 52, 'g'] ],
	5 => [ [17, 24, 'g'], [43, 24, 'g'], [30, 40, 'r'], [17, 56, 'g'], [43, 56, 'g'] ],
	6 => [ [16, 28, 'g'], [30, 28, 'g'], [44, 28, 'g'], [16, 52, 'g'], [30, 52, 'g'], [44, 52, 'g'] ],
	7 => [ [30, 18, 'r'], [16, 40, 'g'], [30, 40, 'g'], [44, 40, 'g'], [16, 62, 'g'], [30, 62, 'g'], [44, 62, 'g'] ],
	8 => [ [16, 19, 'g'], [30, 19, 'g'], [44, 19, 'g'], [16, 40, 'g'], [44, 40, 'g'], [16, 61, 'g'], [30, 61, 'g'], [44, 61, 'g'] ],
	9 => [ [16, 19, 'g'], [30, 19, 'g'], [44, 19, 'g'], [16, 40, 'r'], [30, 40, 'r'], [44, 40, 'r'], [16, 61, 'g'], [30, 61, 'g'], [44, 61, 'g'] ],
);

# the bird on the one of bamboo, drawn from primitives: a body, a head, a
# tail, a beak and an eye, on a perch
sub bird {
	return join '',
		'<rect x="14" y="66" width="32" height="3" rx="1.5" fill="' . $GREEN . '"/>',
		'<ellipse cx="30" cy="46" rx="13" ry="10" fill="' . $GREEN . '"/>',
		'<circle cx="41" cy="33" r="7" fill="' . $GREEN . '"/>',
		'<path d="M17 43 L6 34 L11 48 Z" fill="' . $RED . '"/>',
		'<path d="M47 32 L55 34 L47 37 Z" fill="' . $RED . '"/>',
		'<circle cx="43" cy="31.5" r="1.4" fill="#fbf7ee"/>',
		'<path d="M24 55 L22 66 M34 55 L36 66" stroke="' . $RED . '" stroke-width="2" stroke-linecap="round"/>';
}

# a five-petal rosette for a flower, a leaf for a season
sub rosette {
	my ($cx, $cy, $colour) = @_;
	my $s = '';
	for my $i (0 .. 4) {
		my $a = $i * 72 - 90;
		my ($px, $py) = ($cx + 9 * cos($a * 3.14159265 / 180), $cy + 9 * sin($a * 3.14159265 / 180));
		$s .= sprintf('<circle cx="%.1f" cy="%.1f" r="6.5" fill="%s"/>', $px, $py, $colour);
	}
	$s .= sprintf('<circle cx="%s" cy="%s" r="4" fill="#f4d35e"/>', $cx, $cy);
	return $s;
}

sub leaf {
	my ($cx, $cy, $colour) = @_;
	return sprintf('<path d="M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s Z" fill="%s"/><path d="M%s %s L%s %s" stroke="#fbf7ee" stroke-width="1.5"/>',
		$cx - 14, $cy + 10, $cx - 14, $cy - 12, $cx + 4, $cy - 16, $cx + 14, $cy - 10,
		$cx + 14, $cy + 8, $cx - 2, $cy + 16, $cx - 14, $cy + 10, $colour,
		$cx - 12, $cy + 9, $cx + 12, $cy - 9);
}

# ---- the forty-two ------------------------------------------------------------
my @SYMBOLS;

sub symbol {
	my ($code, $body) = @_;
	push @SYMBOLS, qq{    <symbol id="mj-$code" viewBox="0 0 60 80">$body</symbol>};
}

# characters: the numeral above in ink, the wan sign below in red, and the
# small index digit in the corner drawn in currentColor. A <use> clones the
# symbol into a shadow tree that document CSS cannot reach by class, but the
# inherited `color` crosses that boundary, so the digit shows in the tile's
# colour and a rule of `color: transparent` on the tile hides it. That is the
# one switch the owner's eye decides (plan_mahjong/01).
for my $r (1 .. 9) {
	symbol("m$r",
		glyph("n$r", 10, 6, 40, 30, $INK)
		. glyph('wan', 10, 42, 40, 32, $RED)
		. glyph("d$r", 46, 3, 10, 12, 'currentColor'));
}

# dots: the traditional layouts; the one of dots is a big dot in three rings
for my $r (1 .. 9) {
	my $colour = $r == 1 ? $RED : $r % 2 ? $GREEN : $BLUE;
	my $s = '';
	for my $d (@{ $DOTS{$r} }) {
		my $c = ($r == 5 && $d->[0] == 30) || ($r == 3 && $d->[0] == 30) || ($r == 9 && $d->[0] == 30) ? $RED : $colour;
		$s .= dot($d->[0], $d->[1], $DOT_R{$r}, $c);
	}
	symbol("p$r", $s);
}

# bamboo: the bird, then the sticks
symbol('s1', bird());
for my $r (2 .. 9) {
	my $s = '';
	for my $st (@{ $BAM{$r} }) {
		$s .= stick($st->[0], $st->[1], $st->[2] eq 'r' ? $RED : $GREEN);
	}
	symbol("s$r", $s);
}

# winds: the character, large, in ink
symbol($_, glyph($_, 8, 14, 44, 52, $INK)) for qw(we ws ww wn);

# dragons: red, green, and the white dragon's blue frame
symbol('dr', glyph('dr', 8, 14, 44, 52, $RED));
symbol('dg', glyph('dg', 8, 14, 44, 52, $GREEN));
symbol('dw', '<rect x="10" y="12" width="40" height="56" rx="3" fill="none" stroke="' . $BLUE . '" stroke-width="4"/>'
	. '<rect x="17" y="19" width="26" height="42" rx="2" fill="none" stroke="' . $BLUE . '" stroke-width="2"/>');

# flowers: a rosette and the number; seasons: a leaf and the number
for my $n (1 .. 4) {
	symbol("f$n", rosette(30, 34, $PINK) . glyph("d$n", 22, 54, 16, 20, $INK));
	symbol("t$n", leaf(30, 34, $BLUE) . glyph("d$n", 22, 54, 16, 20, $INK));
}

die 'not forty-two symbols: ' . scalar @SYMBOLS unless @SYMBOLS == 42;

# The lobby icon, drafted here and landed in _game_icons.tmpl by phase 10:
# 64 x 64, its own rx=14 ground, three tiles fanned with the red dragon on
# the front one, authored to read at 48 px.
my $gi = '<symbol id="gi-mahjong" viewBox="0 0 64 64">'
	. '<rect width="64" height="64" rx="14" fill="#2f6b46"/>'
	. '<g transform="rotate(-14 24 34)"><rect x="12" y="18" width="22" height="30" rx="3" fill="#e8e0cb" stroke="#b8a98a" stroke-width="1"/></g>'
	. '<g transform="rotate(-4 32 34)"><rect x="20" y="16" width="22" height="30" rx="3" fill="#f3ecd9" stroke="#b8a98a" stroke-width="1"/></g>'
	. '<rect x="29" y="15" width="24" height="32" rx="3" fill="#fbf7ee" stroke="#b8a98a" stroke-width="1"/>'
	. glyph('dr', 32, 19, 18, 24, $RED)
	. '</symbol>';
die 'the icon is not ASCII' if $gi =~ /[^\x09\x0a\x20-\x7e]/;

my $sheet = join "\n", @SYMBOLS;
die 'the sheet is not ASCII' if $sheet =~ /[^\x09\x0a\x20-\x7e]/;
die 'the sheet carries a style attribute' if $sheet =~ /\bstyle=/;

my $header = <<'HEADER';
{%# The forty-two tile faces: one hidden symbol sheet, used as
    <use href="#mj-CODE"> inside an element whose CSS is the tile body.

    GENERATED by Game-Mahjong/xt/faces/build-sprite.pl from
    xt/faces/glyphs.json; do not edit by hand. The seventeen Chinese
    characters are PATHS traced once from Noto Sans CJK SC Bold (SIL Open
    Font License 1.1), because a <text> would consult the device's fonts and
    stock Android has no glyphs for the Unicode Mahjong Tiles block and
    often no CJK face: a rack of tofu is a broken game. Dots and bamboo are
    primitives. Nothing here is text, nothing here is a style attribute, and
    the sheet is ASCII.

    Each symbol is 60 x 80 and reads at 44 px wide, which is a thumb. The
    colours are the traditional ones and do not change with the theme, like a
    playing card's. The group .mj-idx on the character tiles is the small
    index digit, an option CSS shows or hides. %}
<svg class="mj-faces" aria-hidden="true" focusable="false" width="0" height="0">
  <defs>
HEADER

open my $out, '>', $sprite_path or die "$sprite_path: $!";
print {$out} $header, $sheet, "\n  </defs>\n</svg>\n";
close $out;

# ---- the prototype pages -----------------------------------------------------
# Static HTML with the sheet inlined and the tile body's CSS as 09 will write
# it, so the owner sees exactly what the site will show. faces.html: every
# face at 80, 60 and 44 px, light and dark, with and without the index digit.
# rack.html: a table on a 360 px phone.

my $css = <<'CSS';
:root { --ground:#d9d5c9; --surface:#efebe2; --ink:#221d18; --muted:#6d655a; --line:#c4bdae;
  --walnut:#5a3a24; --brass:#cfa64f; --card:#fbf7ee; --card-ink:#1e1a17; --card-edge:rgba(30,20,10,.22);
  --back:#2f4c8a; --shadow:rgba(30,20,10,.22); --accent:#7a4b22; --peg-red:#c23b2c; }
.dark { --ground:#1b1815; --surface:#26211c; --ink:#ece5d8; --muted:#a79d8f; --line:#3d362e; --shadow:rgba(0,0,0,.5); --accent:#d3aa55; }
html, body { margin:0; }
body { background:var(--ground); color:var(--ink); font:14px/1.35 system-ui, sans-serif; }
.wrap { padding:8px; }
h2 { font-size:14px; margin:14px 0 6px; color:var(--muted); font-weight:600; }
/* the tile body, as 09 will write it into site.css */
.mj-tile { --w:44px; display:inline-block; width:var(--w); aspect-ratio:3/4; box-sizing:border-box;
  background:var(--card); color:var(--card-ink); border:1px solid var(--card-edge); border-radius:calc(var(--w) * .09);
  box-shadow:0 1px 0 var(--card-edge), 0 2px 3px var(--shadow); padding:0; vertical-align:top; position:relative; }
.mj-tile svg { display:block; width:100%; height:100%; }
.mj-tile.lg { --w:80px; } .mj-tile.md { --w:60px; } .mj-tile.sm { --w:30px; }
.mj-tile.back { background:var(--back); }
.mj-tile.back svg { visibility:hidden; }
.mj-tile[aria-pressed="true"] { transform:translateY(-6px); outline:2px solid var(--accent); }
.mj-tile.drawn { margin-left:10px; }
/* the index digit is drawn in currentColor: transparent hides it */
.noidx .mj-tile { color:transparent; }
.gi { width:48px; height:48px; display:inline-block; margin:4px; }
.row { display:flex; flex-wrap:wrap; gap:4px; align-items:flex-end; }
button.mj-tile { cursor:pointer; font:inherit; }
CSS

# The prototype pages inline the sheet WITHOUT the Stencil comment (a browser
# would print it as text) and with the lobby icon added to the defs.
(my $sheet_open = $header) =~ s/\A\{%#.*?%\}\n//s;

sub page {
	my ($title, $body, $extra_css) = @_;
	return "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"
		. "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
		. "<title>$title</title>\n<style>\n$css" . ($extra_css // '') . "</style>\n</head>\n<body>\n"
		. $sheet_open . $sheet . "\n" . $gi . "\n  </defs>\n</svg>\n" . $body . "</body>\n</html>\n";
}

my @codes = ((map { "m$_" } 1 .. 9), (map { "p$_" } 1 .. 9), (map { "s$_" } 1 .. 9),
	qw(we ws ww wn dr dg dw), (map { "f$_" } 1 .. 4), (map { "t$_" } 1 .. 4));

sub tiles {
	my ($size, $class) = @_;
	return '<div class="row' . ($class ? " $class" : '') . '">'
		. join('', map { qq{<span class="mj-tile $size" title="$_"><svg><use href="#mj-$_"/></svg></span>} } @codes)
		. '</div>';
}

my $faces = "<div class=\"wrap\">\n<h2>80 px</h2>" . tiles('lg')
	. "<h2>60 px</h2>" . tiles('md')
	. "<h2>44 px, the rack size</h2>" . tiles('')
	. "<h2>44 px, no index digit on the characters</h2>" . tiles('', 'noidx')
	. "<h2>30 px, a meld or a pool</h2>" . tiles('sm')
	. "<h2>the lobby icon at 48 px</h2><svg class=\"gi\"><use href=\"#gi-mahjong\"/></svg>"
	. "</div>\n<div class=\"wrap dark\">\n<h2>dark: 44 px</h2>" . tiles('')
	. "<h2>dark: the lobby icon</h2><svg class=\"gi\"><use href=\"#gi-mahjong\"/></svg>"
	. "<h2>dark: 30 px</h2>" . tiles('sm') . "</div>\n";

# the rack page: a 360 px frame
my $rack_css = <<'CSS';
.phone { width:360px; margin:8px auto; border:1px solid var(--line); background:var(--ground); padding:6px; box-sizing:border-box; }
.mj-seats { display:grid; grid-template-columns:1fr 1fr 1fr; gap:4px; font-size:12px; }
.mj-seat { background:var(--surface); border:1px solid var(--line); border-radius:6px; padding:4px; }
.mj-seat b { display:block; }
.mj-pool { display:grid; grid-template-columns:repeat(6, 1fr); gap:2px; margin:6px 0; }
.mj-centre { display:flex; justify-content:space-between; font-size:12px; color:var(--muted); margin:4px 0; }
.mj-rack { display:flex; flex-wrap:wrap; gap:3px; margin-top:8px; }
.mj-window { display:flex; gap:6px; flex-wrap:wrap; margin:8px 0; }
.mj-window button { min-height:44px; min-width:64px; font:inherit; border:1px solid var(--line); border-radius:8px; background:var(--surface); color:var(--ink); }
.mj-window .shape .mj-tile { --w:26px; }
.controls { display:flex; gap:6px; margin-top:8px; }
.controls button { min-height:44px; flex:1; font:inherit; border:1px solid var(--line); border-radius:8px; background:var(--surface); color:var(--ink); }
CSS

sub tile { my ($code, $class, $tag) = @_; $tag //= 'span'; return qq{<$tag class="mj-tile $class" title="$code"><svg><use href="#mj-$code"/></svg></$tag>}; }

my $rack = "<div class=\"phone\">\n"
	. '<div class="mj-seats">'
	. '<div class="mj-seat"><b>Left (S)</b>13 tiles<br>' . join('', map { tile($_, 'sm') } qw(m2 m3 m4)) . '</div>'
	. '<div class="mj-seat"><b>Across (W)</b>10 tiles<br>' . join('', map { tile($_, 'sm') } qw(we we we)) . join('', map { tile($_, 'sm back') } 1 .. 4) . '</div>'
	. '<div class="mj-seat"><b>Right (N)</b>13 tiles</div>'
	. '</div>'
	. '<div class="mj-centre"><span>Wall 62</span><span>East round, hand 3 of 16</span><span>You: East</span></div>'
	. '<div class="mj-pool">' . join('', map { tile($_, 'sm') } qw(wn dw m1 p9 s1 ww m9 dr p2 s7 we m5 s3 p6 wn dg s9 p1 m7 s5)) . '</div>'
	. '<div class="mj-window"><button>Pass</button><button class="shape">Chow ' . tile('m4', '') . tile('m6', '') . '</button><button class="shape">Chow ' . tile('m6', '') . tile('m7', '') . '</button><button>Pung</button></div>'
	. '<div class="mj-rack">' . join('', map { tile($_, '', 'button') } qw(m1 m2 m3 m4 m6 m7 p3 p3 p8 s2 s2 s2 dg))
	. tile('p5', 'drawn', 'button') . '</div>'
	. '<div class="controls"><button>Discard</button><button>Kong</button><button>Win</button></div>'
	. "</div>\n<div class=\"dark\"><div class=\"phone\"><div class=\"mj-rack\">" . join('', map { tile($_, '', 'button') } qw(m1 m2 m3 m4 m6 m7 p3 p3 p8 s2 s2 s2 dg)) . tile('p5', 'drawn', 'button') . "</div></div></div>\n";

mkdir $proto_dir unless -d $proto_dir;
for my $p (['faces.html', 'Mahjong faces', $faces, ''], ['rack.html', 'Mahjong rack at 360 px', $rack, $rack_css]) {
	my ($name, $title, $body, $extra) = @$p;
	open my $fh, '>', "$proto_dir/$name" or die "$proto_dir/$name: $!";
	print {$fh} page($title, $body, $extra);
	close $fh;
}

open my $gfh, '>', "$proto_dir/gi-mahjong.svg" or die "$proto_dir/gi-mahjong.svg: $!";
print {$gfh} $gi, "\n";
close $gfh;

printf "wrote %s (%d bytes), %s/{faces,rack}.html and gi-mahjong.svg\n", $sprite_path, -s $sprite_path, $proto_dir;
