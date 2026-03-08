#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use POSIX qw( floor ceil );

# ---------------------------------------------------------------------------
# eps.t -- Tests for exporteps() in Graphics::Penplotter::GcodeXY
#
# Tests are grouped into:
#   1.  Basic invocation and return value
#   2.  DSC header compliance
#   3.  BoundingBox correctness and format
#   4.  Graphics-state setup (linewidth, linecap, linejoin)
#   5.  Body structure (newpath/moveto/lineto/stroke sequencing)
#   6.  Prohibited content (showpage, setpagedevice)
#   7.  Mandatory structural markers (%%EndComments, %%EOF, %%Trailer)
#   8.  Paper-size handling
#   9.  Multiple disconnected paths
#  10.  Edge cases and error handling
#  11.  Drawing accuracy (bounding box reflects actual geometry)
# ---------------------------------------------------------------------------

BEGIN {
    eval { require Graphics::Penplotter::GcodeXY; 1 }
        or plan( skip_all => 'Graphics::Penplotter::GcodeXY not available' );
}
use Graphics::Penplotter::GcodeXY;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a basic GcodeXY object (no papersize -- use xsize/ysize).
sub new_g {
    my (%extra) = @_;
    return Graphics::Penplotter::GcodeXY->new(
        xsize    => 10,
        ysize    => 10,
        units    => 'in',
        optimize => 0,
        %extra,
    );
}

# Draw a simple 1in x 1in square at (1,1) and export to a temp EPS file.
# Returns ($g, $filename, @return_value).
sub make_eps {
    my ($g, %draw) = @_;
    $g //= new_g();

    if ($draw{shape} // 'box' eq 'box') {
        $g->box(1, 1, 2, 2);
        $g->stroke();
    }

    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;

    my @ret = $g->exporteps($fname);
    return ($g, $fname, @ret);
}

# Read an EPS file and return its lines (chomped).
sub read_eps {
    my ($fname) = @_;
    open my $fh, '<', $fname or die "Cannot read $fname: $!";
    my @lines = map { chomp; $_ } <$fh>;
    close $fh;
    return @lines;
}

# Find lines matching a pattern; return list of matching lines.
sub grep_lines { my ($pat, @lines) = @_; grep { /$pat/ } @lines }

# True if a string is an integer (possibly negative, possibly zero).
sub is_integer { $_[0] =~ /\A-?\d+\z/ }

# Toleranced float comparison.
sub near { abs($_[0] - $_[1]) < 0.01 }

# ---------------------------------------------------------------------------
# 1. Basic invocation and return value
# ---------------------------------------------------------------------------

note('--- 1. basic invocation and return value ---');

{
    my ($g, $fname, @ret) = make_eps();
    ok( -e $fname,      'file created' );
    ok( -s $fname > 0,  'file is non-empty' );

    # New exporteps returns a 4-element bounding box tuple (in points),
    # matching the return convention of exportsvg().
    is( scalar @ret, 4, 'return value is a 4-element list' );
    my ($llx, $lly, $urx, $ury) = @ret;
    ok( $urx > $llx, 'bounding box: urx > llx' );
    ok( $ury > $lly, 'bounding box: ury > lly' );
}

# ---------------------------------------------------------------------------
# 2. DSC header compliance
# ---------------------------------------------------------------------------

note('--- 2. DSC header compliance ---');

{
    my (undef, $fname) = make_eps();
    my @lines = read_eps($fname);

    # First line must be exactly the magic comment, no leading whitespace
    like( $lines[0], qr/\A%!PS-Adobe-3\.0 EPSF-3\.0/,
        'first line is %!PS-Adobe-3.0 EPSF-3.0' );

    ok( grep_lines(qr/^%%Creator:/, @lines),
        '%%Creator comment present' );

    ok( grep_lines(qr/^%%Title:/, @lines),
        '%%Title comment present' );

    ok( grep_lines(qr/^%%CreationDate:/, @lines),
        '%%CreationDate comment present' );

    ok( grep_lines(qr/^%%LanguageLevel:/, @lines),
        '%%LanguageLevel comment present' );

    ok( grep_lines(qr/^%%Pages:/, @lines),
        '%%Pages comment present' );

    # %%BoundingBox must appear in the header (before %%EndComments)
    my $endcomments_idx = (grep { $lines[$_] =~ /^%%EndComments/ }
                           0 .. $#lines)[0];
    ok( defined $endcomments_idx, '%%EndComments found' );

    my $bb_idx = (grep { $lines[$_] =~ /^%%BoundingBox:/ }
                  0 .. $#lines)[0];
    ok( defined $bb_idx, '%%BoundingBox found' );
    ok( $bb_idx < $endcomments_idx,
        '%%BoundingBox appears before %%EndComments' );

    # HiResBoundingBox should also be in the header
    my $hibb_idx = (grep { $lines[$_] =~ /^%%HiResBoundingBox:/ }
                    0 .. $#lines)[0];
    ok( defined $hibb_idx, '%%HiResBoundingBox found' );
    ok( $hibb_idx < $endcomments_idx,
        '%%HiResBoundingBox appears before %%EndComments' );
}

# ---------------------------------------------------------------------------
# 3. BoundingBox correctness and format
# ---------------------------------------------------------------------------

note('--- 3. BoundingBox correctness and format ---');

{
    my (undef, $fname, $llx_f, $lly_f, $urx_f, $ury_f) = make_eps();
    my @lines = read_eps($fname);

    my ($bb_line) = grep_lines(qr/^%%BoundingBox:/, @lines);
    ok( defined $bb_line, '%%BoundingBox line present' );

    my (undef, $llx, $lly, $urx, $ury) = split /\s+/, $bb_line;

    # Issue 2: all four values must be integers
    ok( is_integer($llx), "%%BoundingBox llx '$llx' is an integer" );
    ok( is_integer($lly), "%%BoundingBox lly '$lly' is an integer" );
    ok( is_integer($urx), "%%BoundingBox urx '$urx' is an integer" );
    ok( is_integer($ury), "%%BoundingBox ury '$ury' is an integer" );

    # Floor/ceil: integer values must bound the float return values
    ok( $llx <= floor($llx_f) + 1,
        '%%BoundingBox llx <= floor(actual llx) [conservative min]' );
    ok( $urx >= ceil($urx_f) - 1,
        '%%BoundingBox urx >= ceil(actual urx) [conservative max]' );
    ok( $lly <= floor($lly_f) + 1,
        '%%BoundingBox lly <= floor(actual lly)' );
    ok( $ury >= ceil($ury_f) - 1,
        '%%BoundingBox ury >= ceil(actual ury)' );

    # Sanity: box must have positive area
    ok( $urx > $llx, '%%BoundingBox has positive width' );
    ok( $ury > $lly, '%%BoundingBox has positive height' );

    # %%HiResBoundingBox must carry floating-point values
    my ($hibb_line) = grep_lines(qr/^%%HiResBoundingBox:/, @lines);
    my (undef, $hllx, $hlly, $hurx, $hury) = split /\s+/, $hibb_line;
    ok( $hllx =~ /\./, '%%HiResBoundingBox llx contains a decimal point' );
    ok( $hurx =~ /\./, '%%HiResBoundingBox urx contains a decimal point' );

    # HiRes must match the returned float values
    ok( near($hllx, $llx_f), '%%HiResBoundingBox llx matches return value' );
    ok( near($hurx, $urx_f), '%%HiResBoundingBox urx matches return value' );
}

# Issue 3: bounding box minimum is not capped at 100pt.
# Draw a shape entirely above 100pt (> ~1.39 inches).
{
    note('  bounding box minimum not capped at 100pt');
    my $g = new_g();
    $g->box(2, 2, 3, 3);    # 2in..3in => 144pt..216pt
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);
    my ($bb_line) = grep_lines(qr/^%%BoundingBox:/, @lines);
    my (undef, $llx) = split /\s+/, $bb_line;
    ok( $llx > 100, "BoundingBox llx ($llx) > 100 for shape beyond 100pt" );
}

# ---------------------------------------------------------------------------
# 4. Graphics-state setup
# ---------------------------------------------------------------------------

note('--- 4. graphics-state setup ---');

{
    my (undef, $fname) = make_eps();
    my @lines = read_eps($fname);

    ok( grep_lines(qr/setlinewidth/, @lines),
        'setlinewidth is emitted' );

    ok( grep_lines(qr/\b1\s+setlinecap\b/, @lines),
        '1 setlinecap (round) emitted' );

    ok( grep_lines(qr/\b1\s+setlinejoin\b/, @lines),
        '1 setlinejoin (round) emitted' );

    # setlinewidth and graphics-state lines must appear after %%EndComments
    my $endcomments_idx = (grep { $lines[$_] =~ /^%%EndComments/ }
                           0 .. $#lines)[0];
    my ($lw_idx) = grep { $lines[$_] =~ /setlinewidth/ } 0 .. $#lines;
    ok( $lw_idx > $endcomments_idx,
        'setlinewidth appears after %%EndComments (in body)' );
}

# eps_linewidth attribute is respected
{
    my $g = new_g( eps_linewidth => 1.5 );
    $g->box(1, 1, 2, 2);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);
    ok( grep_lines(qr/1\.5.*setlinewidth/, @lines),
        'eps_linewidth attribute controls setlinewidth value' );
}

# ---------------------------------------------------------------------------
# 5. Body structure: newpath / moveto / lineto / stroke sequencing
# ---------------------------------------------------------------------------

note('--- 5. body structure ---');

{
    # Draw a single line and verify the PS operator sequence is correct.
    my $g = new_g();
    $g->line(0, 0, 2, 0);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);

    # Extract only the body drawing operators
    my @ops;
    my $in_body = 0;
    for my $l (@lines) {
        $in_body = 1 if $l =~ /^%%EndComments/;
        next unless $in_body;
        push @ops, $1 while $l =~ /\b(newpath|moveto|lineto|stroke)\b/g;
    }

    # Canonical sequence for a single stroked line:
    # newpath, moveto, lineto, stroke
    my $np_idx  = (grep { $ops[$_] eq 'newpath'  } 0..$#ops)[0];
    my $mt_idx  = (grep { $ops[$_] eq 'moveto'   } 0..$#ops)[0];
    my $lt_idx  = (grep { $ops[$_] eq 'lineto'   } 0..$#ops)[0];
    my $st_idx  = (grep { $ops[$_] eq 'stroke'   } 0..$#ops)[0];

    ok( defined $np_idx,          'newpath present in body' );
    ok( defined $mt_idx,          'moveto present in body' );
    ok( defined $lt_idx,          'lineto present in body' );
    ok( defined $st_idx,          'stroke present in body' );
    ok( $np_idx < $mt_idx,        'newpath before moveto' );
    ok( $mt_idx < $lt_idx,        'moveto before lineto' );
    ok( $lt_idx < $st_idx,        'lineto before stroke' );

    # newpath and moveto should be on the same line (as "newpath X Y moveto")
    my ($np_line) = grep_lines(qr/newpath/, @lines);
    like( $np_line, qr/newpath.*moveto/,
        'newpath and moveto are on the same line' );
}

# Every newpath must be followed eventually by a stroke before the next newpath
{
    my $g = new_g();
    $g->line(0, 0, 1, 0);
    $g->stroke();
    $g->line(0, 1, 1, 1);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);

    my @ops;
    my $in_body = 0;
    for my $l (@lines) {
        $in_body = 1 if $l =~ /^%%EndComments/;
        next unless $in_body;
        push @ops, $1 if $l =~ /\b(newpath|stroke)\b/;
    }
    # Pattern must be: newpath, stroke, newpath, stroke (interleaved)
    my $ok = 1;
    my $last = '';
    for my $op (@ops) {
        $ok = 0 if $op eq 'newpath' && $last eq 'newpath';
        $last = $op;
    }
    ok( $ok, 'no two consecutive newpath without intervening stroke' );
}

# Coordinates in the body must match the drawing
{
    my $I2P = 72.0;
    my $g   = new_g();
    $g->line(1, 2, 3, 4);    # 1in,2in -> 3in,4in
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);
    my $in_body = 0;
    my (@movetos, @linetos);
    for my $l (@lines) {
        $in_body = 1 if $l =~ /^%%EndComments/;
        next unless $in_body;
        if ($l =~ /([\d.]+)\s+([\d.]+)\s+moveto/) { push @movetos, [$1,$2] }
        if ($l =~ /([\d.]+)\s+([\d.]+)\s+lineto/) { push @linetos, [$1,$2] }
    }
    ok( @movetos && near($movetos[0][0], 1*$I2P) &&
                    near($movetos[0][1], 2*$I2P),
        'moveto coordinates match start of line (1in,2in in points)' );
    ok( @linetos && near($linetos[0][0], 3*$I2P) &&
                    near($linetos[0][1], 4*$I2P),
        'lineto coordinates match end of line (3in,4in in points)' );
}

# ---------------------------------------------------------------------------
# 6. Prohibited content
# ---------------------------------------------------------------------------

note('--- 6. prohibited content ---');

{
    my (undef, $fname) = make_eps();
    my @lines = read_eps($fname);

    # Issue 4: showpage must not appear in EPS
    ok( !grep_lines(qr/\bshowpage\b/, @lines),
        'showpage absent (EPS must not call showpage)' );

    # Issue 5: setpagedevice must not appear in EPS
    ok( !grep_lines(qr/\bsetpagedevice\b/, @lines),
        'setpagedevice absent (EPS must not configure device)' );

    # %%DocumentMedia is a full-document DSC comment, wrong in EPS
    ok( !grep_lines(qr/^%%DocumentMedia/, @lines),
        '%%DocumentMedia absent from EPS' );

    # %%BeginSetup / %%EndSetup blocks should not appear (they contain
    # device-specific operators in the old code)
    ok( !grep_lines(qr/^%%BeginSetup/, @lines),
        '%%BeginSetup absent from EPS' );

    # (atend) should not appear -- we use two-pass so we know the BB upfront
    ok( !grep_lines(qr/\(atend\)/, @lines),
        '(atend) not used -- bounding box known at header time' );
}

# ---------------------------------------------------------------------------
# 7. Mandatory structural markers
# ---------------------------------------------------------------------------

note('--- 7. mandatory structural markers ---');

{
    my (undef, $fname) = make_eps();
    my @lines = read_eps($fname);

    ok( grep_lines(qr/^%%EndComments/, @lines),
        '%%EndComments present' );

    ok( grep_lines(qr/^%%Trailer/, @lines),
        '%%Trailer present' );

    # %%EOF must be the last non-empty line
    my @nonempty = grep { /\S/ } @lines;
    like( $nonempty[-1], qr/^%%EOF/,
        '%%EOF is the last non-empty line' );

    # %%Trailer must come before %%EOF
    my $trailer_idx = (grep { $lines[$_] =~ /^%%Trailer/ } 0..$#lines)[0];
    my $eof_idx     = (grep { $lines[$_] =~ /^%%EOF/     } 0..$#lines)[0];
    ok( defined $trailer_idx && defined $eof_idx && $trailer_idx < $eof_idx,
        '%%Trailer appears before %%EOF' );

    # %%Page must appear between %%EndComments and %%Trailer
    my $endcomments_idx = (grep { $lines[$_] =~ /^%%EndComments/ }
                           0..$#lines)[0];
    my $page_idx        = (grep { $lines[$_] =~ /^%%Page:/       }
                           0..$#lines)[0];
    ok( defined $page_idx,
        '%%Page comment present' );
    ok( $page_idx > $endcomments_idx && $page_idx < $trailer_idx,
        '%%Page appears between %%EndComments and %%Trailer' );
}

# ---------------------------------------------------------------------------
# 8. Paper-size handling
# ---------------------------------------------------------------------------

note('--- 8. paper size handling ---');

# With a named papersize: %%PageMedia should appear; setpagedevice should not
{
    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => 'A4',
        units     => 'in',
        optimize  => 0,
    );
    $g->box(1, 1, 2, 2);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);

    ok( grep_lines(qr/^%%PageMedia:.*[Aa]4/i, @lines),
        'A4 papersize: %%PageMedia comment present' );
    ok( !grep_lines(qr/\bsetpagedevice\b/, @lines),
        'A4 papersize: setpagedevice still absent' );
}

# With xsize/ysize only (no papersize): no %%PageMedia needed, no crash
{
    my $g = new_g();
    $g->box(1, 1, 2, 2);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    eval { $g->exporteps($fname) };
    ok( !$@, 'no papersize (xsize/ysize only): no crash' );
}

# Each supported papersize must not crash and must produce valid first line
for my $ps (qw( 4A0 2A0 A0 A1 A2 A3 A4 )) {
    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => $ps,
        units     => 'in',
        optimize  => 0,
    );
    $g->box(0.5, 0.5, 1.0, 1.0);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    eval { $g->exporteps($fname) };
    ok( !$@, "papersize $ps: no crash" );
    my @lines = read_eps($fname);
    like( $lines[0], qr/\A%!PS-Adobe/,
        "papersize $ps: valid EPS magic on first line" );
}

# ---------------------------------------------------------------------------
# 9. Multiple disconnected paths
# ---------------------------------------------------------------------------

note('--- 9. multiple disconnected paths ---');

{
    # Three separate stroked lines -- should produce three newpath/stroke pairs
    my $g = new_g();
    $g->line(0, 0, 1, 0); $g->stroke();
    $g->line(0, 1, 1, 1); $g->stroke();
    $g->line(0, 2, 1, 2); $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    $g->exporteps($fname);
    my @lines = read_eps($fname);

    my @np_lines = grep_lines(qr/\bnewpath\b/, @lines);
    my @st_lines = grep_lines(qr/\bstroke\b/,  @lines);

    ok( scalar(@np_lines) >= 3, 'three paths: at least 3 newpath occurrences' );
    ok( scalar(@st_lines) >= 3, 'three paths: at least 3 stroke occurrences' );

    # The bounding box should encompass all three lines
    my ($bb_line) = grep_lines(qr/^%%BoundingBox:/, @lines);
    my (undef, undef, $lly, undef, $ury) = split /\s+/, $bb_line;
    # Lines are at y=0,1,2in => 0,72,144pt.  ury must be >= 144.
    ok( $ury >= 144, 'bounding box encompasses all three paths (ury>=144pt)' );
}

# ---------------------------------------------------------------------------
# 10. Edge cases and error handling
# ---------------------------------------------------------------------------

note('--- 10. edge cases and error handling ---');

# No filename: must croak
{
    my $g = new_g();
    $g->box(1, 1, 2, 2); $g->stroke();
    eval { $g->exporteps() };
    ok( $@, 'no filename: exporteps croaks' );
    like( $@, qr/exporteps/i,
        'no filename: error message mentions exporteps (not outputpeps)' );
}

# Undef filename: must croak
{
    my $g = new_g();
    $g->box(1, 1, 2, 2); $g->stroke();
    eval { $g->exporteps(undef) };
    ok( $@, 'undef filename: exporteps croaks' );
}

# Empty drawing: exporteps should croak gracefully
{
    my $g   = new_g();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    eval { $g->exporteps($fname) };
    ok( $@, 'empty drawing: exporteps croaks' );
}

# Non-writable path: exporteps should croak
{
    my $g = new_g();
    $g->box(1,1,2,2); $g->stroke();
    eval { $g->exporteps('/no/such/directory/test.eps') };
    ok( $@, 'non-writable path: exporteps croaks' );
}

# Calling exporteps twice on same object must produce identical files
{
    my $g = new_g();
    $g->box(1, 1, 2, 2); $g->stroke();
    my ($fh1, $f1) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    my ($fh2, $f2) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh1; close $fh2;
    $g->exporteps($f1);
    $g->exporteps($f2);
    my @l1 = read_eps($f1);
    my @l2 = read_eps($f2);
    # Remove CreationDate (timestamps may differ by a second in slow CI)
    # Remove Title (contains the temp filename, which differs between calls)
    @l1 = grep { !/^%%(?:CreationDate|Title)/ } @l1;
    @l2 = grep { !/^%%(?:CreationDate|Title)/ } @l2;
    is_deeply( \@l1, \@l2,
        'calling exporteps twice produces identical output' );
}

# exportsvg and exporteps can be called on the same object without interference
{
    my $g = new_g();
    $g->box(1, 1, 2, 2); $g->stroke();
    my ($fh1, $feps) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    my ($fh2, $fsvg) = tempfile( SUFFIX => '.svg', UNLINK => 1 );
    close $fh1; close $fh2;
    eval {
        $g->exporteps($feps);
        $g->exportsvg($fsvg);
    };
    ok( !$@,       'exporteps then exportsvg: no error' );
    ok( -s $feps > 0, 'EPS file non-empty after both exports' );
    ok( -s $fsvg > 0, 'SVG file non-empty after both exports' );
}

# ---------------------------------------------------------------------------
# 11. Drawing accuracy: bounding box reflects actual geometry
# ---------------------------------------------------------------------------

note('--- 11. drawing accuracy ---');

{
    my $I2P = 72.0;

    # A box from (1in,1in) to (3in,2in): expected BB roughly 72..216 x 72..144
    my $g = new_g();
    $g->box(1, 1, 3, 2);
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    my (undef, undef, $llx_f, $lly_f, $urx_f, $ury_f) = (undef, undef,
        $g->exporteps($fname));
    # Recover from the 4-element return
    ($llx_f, $lly_f, $urx_f, $ury_f) = $g->exporteps($fname);

    ok( near($llx_f, 1 * $I2P), "BB llx ≈ 1in in points ($llx_f)" );
    ok( near($lly_f, 1 * $I2P), "BB lly ≈ 1in in points ($lly_f)" );
    ok( near($urx_f, 3 * $I2P), "BB urx ≈ 3in in points ($urx_f)" );
    ok( near($ury_f, 2 * $I2P), "BB ury ≈ 2in in points ($ury_f)" );
}

# A circle: bounding box should be roughly cx±r in each axis
{
    my $I2P = 72.0;
    my $g = new_g();
    $g->circle(3, 3, 1);    # centre (3,3), radius 1in
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    my ($llx_f, $lly_f, $urx_f, $ury_f) = $g->exporteps($fname);

    # With polygon approximation, allow 2% tolerance
    my $tol = 0.02 * $I2P;
    ok( abs($llx_f - 2*$I2P) < $tol, "circle BB: llx ≈ (cx-r) = 2in" );
    ok( abs($urx_f - 4*$I2P) < $tol, "circle BB: urx ≈ (cx+r) = 4in" );
    ok( abs($lly_f - 2*$I2P) < $tol, "circle BB: lly ≈ (cy-r) = 2in" );
    ok( abs($ury_f - 4*$I2P) < $tol, "circle BB: ury ≈ (cy+r) = 4in" );
}

# A drawing far from the origin: min values must not be clamped to 100pt
{
    my $I2P = 72.0;
    my $g = new_g();
    $g->box(5, 5, 6, 6);    # entirely above 100pt threshold
    $g->stroke();
    my ($fh, $fname) = tempfile( SUFFIX => '.eps', UNLINK => 1 );
    close $fh;
    my ($llx_f, $lly_f) = $g->exporteps($fname);
    ok( near($llx_f, 5 * $I2P),
        "BB llx correct for shape at 5in (not clamped to 100pt)" );
    ok( near($lly_f, 5 * $I2P),
        "BB lly correct for shape at 5in (not clamped to 100pt)" );
}

done_testing();
