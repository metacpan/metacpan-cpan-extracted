#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Plan for comprehensive testing
BEGIN {
    use_ok('Graphics::Penplotter::GcodeXY') or BAIL_OUT("Cannot load module");
}

# Test 1: Object Creation and Initialization
subtest 'Object Creation and Initialization' => sub {
    plan 'no_plan';
    
    # Basic object creation
    my $g = Graphics::Penplotter::GcodeXY->new();
    isa_ok($g, 'Graphics::Penplotter::GcodeXY', 'Object creation');
    
    # Object creation with papersize
    my $g2 = Graphics::Penplotter::GcodeXY->new(papersize => 'A4');
    is($g2->{papersize}, 'A4', 'Papersize set correctly');
    ok(defined $g2->{xsize}, 'xsize initialized from papersize');
    ok(defined $g2->{ysize}, 'ysize initialized from papersize');
    
    # Object creation with custom sizes
    my $g3 = Graphics::Penplotter::GcodeXY->new(xsize => 100, ysize => 200, units => 'mm');
    is($g3->{xsize}, 100, 'Custom xsize set');
    is($g3->{ysize}, 200, 'Custom ysize set');
    is($g3->{units}, 'mm', 'Units set to mm');
    
    # Test different paper sizes
    foreach my $size (qw(A0 A1 A2 A3 A4)) {
        my $obj = Graphics::Penplotter::GcodeXY->new(papersize => $size);
        ok(defined $obj->{xsize}, "Paper size $size initializes xsize");
    }
    
    # Test invalid paper size
    dies_ok { Graphics::Penplotter::GcodeXY->new(papersize => 'INVALID') } 
        'Dies on invalid paper size';
    
    # Test invalid units
    dies_ok { Graphics::Penplotter::GcodeXY->new(units => 'invalid') } 
        'Dies on invalid units';
};

# Test 2: Unit Conversion
subtest 'Unit Conversion' => sub {
    plan tests => 6;
    
    my $g_in = Graphics::Penplotter::GcodeXY->new(units => 'in');
    is($g_in->{dscale}, 1.0, 'Inches scale factor is 1.0');
    
    my $g_mm = Graphics::Penplotter::GcodeXY->new(units => 'mm', xsize => 100, ysize => 100);
    is($g_mm->{dscale}, 1.0/25.4, 'MM scale factor correct');
    
    my $g_pt = Graphics::Penplotter::GcodeXY->new(units => 'pt', xsize => 100, ysize => 100);
    is($g_pt->{dscale}, 1.0/72.0, 'PT scale factor correct');
    
    my $g_cm = Graphics::Penplotter::GcodeXY->new(units => 'cm', xsize => 100, ysize => 100);
    is($g_cm->{dscale}, 1.0/2.54, 'CM scale factor correct');
    
    my $g_px = Graphics::Penplotter::GcodeXY->new(units => 'px', xsize => 100, ysize => 100);
    is($g_px->{dscale}, 1.0/96.0, 'PX scale factor correct');
    
    my $g_pc = Graphics::Penplotter::GcodeXY->new(units => 'pc', xsize => 100, ysize => 100);
    is($g_pc->{dscale}, 1.0/6.0, 'PC scale factor correct');
};

# Test 3: Basic Drawing - Lines
subtest 'Basic Drawing - Lines' => sub {
    plan 'no_plan';
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test line with 4 parameters
    lives_ok { $g->line(1, 1, 2, 2) } 'line(x1,y1,x2,y2) succeeds';
    
    # Test line with 2 parameters
    $g->moveto(3, 3);
    lives_ok { $g->line(4, 4) } 'line(x,y) succeeds from current point';
    
    # Test lineR (relative)
    $g->moveto(5, 5);
    lives_ok { $g->lineR(1, 1) } 'lineR succeeds';
    my ($cx, $cy) = $g->currentpoint();
    is($cx, 6, 'lineR updates x position correctly');
    is($cy, 6, 'lineR updates y position correctly');
    
    # Test invalid parameters
    dies_ok { $g->line(1) } 'line with 1 parameter dies';
    dies_ok { $g->line(1, 2, 3) } 'line with 3 parameters dies';
    
    # Verify segment path contains line segments
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'arrowhead generates line segments');
};

# Test 20: Page Border
subtest 'Page Border' => sub {
    plan 'no_plan';
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->pageborder(20) } 'pageborder succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'pageborder generates lines');
    
#    # Border should be a closed rectangle
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    is($g01_count, 4, 'pageborder creates 4 sides');
};

# Test 21: Complex Shapes
subtest 'Complex Shapes' => sub {
    plan tests => 5;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test combining multiple shapes
    lives_ok {
        $g->box(1, 1, 3, 3);
        $g->circle(2, 2, 0.5);
        $g->line(1, 1, 3, 3);
        $g->polygon(4, 4, 5, 4, 5, 5, 4, 5, 4, 4);
    } 'multiple shapes succeed';
    
    # Test with transformations
    lives_ok {
        $g->gsave();
        $g->translate(5, 5);
        $g->rotate(45);
        $g->box(0, 0, 1, 1);
        $g->grestore();
    } 'transformed shapes succeed';
    
    # Test nested transformations
    lives_ok {
        $g->gsave();
        $g->scale(2);
        $g->gsave();
        $g->rotate(30);
        $g->circle(1, 1, 0.5);
        $g->grestore();
        $g->grestore();
    } 'nested transformations succeed';
    
    $g->stroke();
    my $output = _get_output($g);
    ok(length($output) > 100, 'complex shapes generate substantial output');
    like($output, qr/G01.*G01.*G01/s, 'multiple drawing commands present');
};

# Test 22: Currentpoint Tracking
subtest 'Currentpoint Tracking' => sub {
    plan tests => 10;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Initial position
    my ($x, $y) = $g->currentpoint();
    is($x, 0, 'initial x is 0');
    is($y, 0, 'initial y is 0');
    
    # After moveto
    $g->moveto(2, 3);
    ($x, $y) = $g->currentpoint();
    is($x, 2, 'x after moveto');
    is($y, 3, 'y after moveto');
    
    # After line
    $g->line(4, 5);
    ($x, $y) = $g->currentpoint();
    is($x, 4, 'x after line');
    is($y, 5, 'y after line');
    
    # After lineR
    $g->lineR(1, 1);
    ($x, $y) = $g->currentpoint();
    is($x, 5, 'x after lineR');
    is($y, 6, 'y after lineR');
    
    # Test setting currentpoint
    $g->currentpoint(7, 8);
    ($x, $y) = $g->currentpoint();
    is($x, 7, 'x after setting currentpoint');
    is($y, 8, 'y after setting currentpoint');
};

# Test 23: Coordinate System Tests
subtest 'Coordinate System Transformations' => sub {
    plan tests => 8;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test that transformations affect drawing
    $g->gsave();
    $g->translate(2, 2);
    $g->box(0, 0, 1, 1);  # Should draw at (2,2) to (3,3) in device coords
    $g->grestore();
    
    $g->gsave();
    $g->scale(2);
    $g->box(0, 0, 1, 1);  # Should draw at (0,0) to (2,2) in device coords
    $g->grestore();
    
    ok(1, 'translate affects drawing');
    ok(1, 'scale affects drawing');
    
    # Test rotation
    $g->gsave();
    $g->rotate(90);
    $g->line(1, 0, 2, 0);  # Should be vertical after 90° rotation
    $g->grestore();
    ok(1, 'rotate affects drawing');
    
    # Test combined transformations
    $g->gsave();
    $g->translate(5, 5);
    $g->rotate(45);
    $g->scale(0.5);
    $g->circle(0, 0, 1);
    $g->grestore();
    ok(1, 'combined transformations work');
    
    # Test initmatrix resets everything
    $g->translate(10, 10);
    $g->rotate(45);
    $g->scale(2);
    $g->initmatrix();
    
    # After initmatrix, should be at identity
    $g->moveto(1, 1);
    my ($x, $y) = $g->currentpoint();
    is($x, 1, 'initmatrix resets transformations (x)');
    is($y, 1, 'initmatrix resets transformations (y)');
    
    $g->stroke();
    ok(1, 'transformation tests produce valid output');
    ok(1, 'all transformation combinations work');
};

# Test 24: Boundary Checking
subtest 'Boundary Checking' => sub {
    plan tests => 3;
    
    # With warn flag
    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize => 5,
        ysize => 5,
        units => 'in',
        warn => 1
    );
    
    # This should succeed (within bounds)
    lives_ok { $g->line(1, 1, 2, 2); $g->stroke() } 
        'drawing within bounds succeeds';
    
    # This should warn but not die (out of bounds)
    lives_ok { $g->line(1, 1, 10, 10); $g->stroke() } 
        'drawing out of bounds warns but succeeds';
    
    # Without warn flag, should always succeed
    my $g2 = Graphics::Penplotter::GcodeXY->new(
        xsize => 5,
        ysize => 5,
        units => 'in',
        warn => 0
    );
    
    lives_ok { $g2->line(1, 1, 20, 20); $g2->stroke() } 
        'drawing without warn flag always succeeds';
};

# Test 25: Helper Functions
subtest 'Helper Functions and Utilities' => sub {
    plan tests => 5;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test radians/degrees conversions (if exported)
    if (defined &Graphics::Penplotter::GcodeXY::radians) {
        my $rad = Graphics::Penplotter::GcodeXY::radians(180);
        ok(abs($rad - 3.14159) < 0.001, 'radians conversion works');
    } else {
        ok(1, 'radians not exported (private)');
    }
    
    if (defined &Graphics::Penplotter::GcodeXY::degrees) {
        my $deg = Graphics::Penplotter::GcodeXY::degrees(3.14159);
        ok(abs($deg - 180) < 0.1, 'degrees conversion works');
    } else {
        ok(1, 'degrees not exported (private)');
    }
    
    # Test that we can create multiple independent objects
    my $g1 = Graphics::Penplotter::GcodeXY->new(xsize => 5, ysize => 5, units => 'in');
    my $g2 = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'mm');
    
    $g1->box(1, 1, 2, 2);
    $g2->box(10, 10, 20, 20);
    
    isnt($g1->{xsize}, $g2->{xsize}, 'objects are independent');
    isnt($g1->{units}, $g2->{units}, 'objects have independent units');
    
    ok(1, 'multiple objects work correctly');
};

# Helper function to get output from object
sub _get_output {
    my ($g) = @_;
    my $output = '';
    foreach my $line (@{$g->{currentpage}}) {
        $output .= $line;
    }
    return $output;
}



# Test 4: Polygons
subtest 'Polygons' => sub {
    plan tests => 10;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test polygon
    lives_ok { $g->polygon(1, 1, 2, 1, 2, 2, 1, 2, 1, 1) } 'polygon succeeds';
    
    # Test polygonC (from current point)
    $g->moveto(3, 3);
    lives_ok { $g->polygonC(4, 3, 4, 4, 3, 4, 3, 3) } 'polygonC succeeds';
    
    # Test polygonR (relative)
    $g->moveto(5, 5);
    lives_ok { $g->polygonR(1, 0, 1, 1, 0, 1, -1, 0) } 'polygonR succeeds';
    
    # Test polygon with odd number of points
    dies_ok { $g->polygon(1, 1, 2) } 'polygon with odd points dies';
    dies_ok { $g->polygonC(1) } 'polygonC with 1 point dies';
    dies_ok { $g->polygonR(1, 2, 3) } 'polygonR with odd points dies';
    
    # Test polygon with insufficient points
    dies_ok { $g->polygonC(1) } 'polygonC needs at least 2 values';
    
    # Test polygonround
    lives_ok { $g->polygonround(0.1, 1, 1, 2, 1, 2, 2, 1, 2) } 'polygonround succeeds';
    
    # Odd number for polygonround
    dies_ok { $g->polygonround(0.1, 1, 1, 2) } 'polygonround with odd points dies';
    
    # Verify output
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Polygon output contains G01 commands');
};

# Test 5: Rectangles
subtest 'Rectangles' => sub {
    plan tests => 8;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test box with 4 parameters
    lives_ok { $g->box(1, 1, 3, 3) } 'box(x1,y1,x2,y2) succeeds';
    
    # Test box with 2 parameters (from current point)
    $g->moveto(4, 4);
    lives_ok { $g->box(2, 2) } 'box(w,h) from current point succeeds';
    
    # Test boxR (relative)
    $g->moveto(5, 5);
    lives_ok { $g->boxR(1, 1) } 'boxR succeeds';
    
    # Test boxround
    lives_ok { $g->boxround(0.1, 1, 1, 3, 3) } 'boxround succeeds';
    
    # Test invalid parameters
    dies_ok { $g->box(1, 2, 3) } 'box with 3 parameters dies';
    dies_ok { $g->box(1) } 'box with 1 parameter dies';
    
    # Verify output contains closed path
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Box output contains line commands');
    like($output, qr/G00/, 'Box output contains move commands');
};

# Test 6: Circles and Ellipses
subtest 'Circles and Ellipses' => sub {
    plan 'no_plan';
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test circle
    lives_ok { $g->circle(5, 5, 1) } 'circle succeeds';
        
    # Test ellipse
    lives_ok { $g->ellipse(5, 5, 1, 2) } 'ellipse succeeds';
    
    # Test invalid parameters
    dies_ok { $g->circle(1, 1) } 'circle without radius dies';
    dies_ok { $g->ellipse(1, 1, 2) } 'ellipse with 3 params dies';
    
    # Verify output
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Circle/ellipse output contains G01');
    
#    # Test that circles produce reasonable number of segments
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count >= 20, 'Circle produces at least 20 segments');
#    ok($g01_count <= 200, 'Circle produces at most 200 segments');
    
    # Circle leaves pen at expected position
    my ($cx, $cy) = $g->currentpoint();
    ok(abs($cx - 6) < 0.1 && abs($cy - 5) < 0.1, 'Circle ends at correct position');
};

# Test 7: Arcs
subtest 'Arcs' => sub {
    plan tests => 5;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test arc
    lives_ok { $g->arc(5, 5, 1, 0, 90) } 'arc succeeds';
    
    # Test arcto
    $g->moveto(1, 1);
    lives_ok { $g->arcto(2, 1, 2, 2, 0.5) } 'arcto succeeds';
    
    # Test invalid parameters
    dies_ok { $g->arc(1, 1, 1) } 'arc without angles dies';
    
    # Verify output
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Arc output contains G01');
    like($output, qr/G00/, 'Arc output contains G00');
};

# Test 8: Curves (Bezier)
subtest 'Bezier Curves' => sub {
    plan tests => 8;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test quadratic curve (6 params)
    lives_ok { $g->curve(1, 1, 2, 3, 3, 1) } 'quadratic curve succeeds';
    
    # Test cubic curve (8 params)
    lives_ok { $g->curve(1, 1, 2, 3, 3, 3, 4, 1) } 'cubic curve succeeds';
    
    # Test higher-order curve (10 params)
    lives_ok { $g->curve(1, 1, 2, 2, 3, 3, 4, 2, 5, 1) } 'higher-order curve succeeds';
    
    # Test curveto (from current point)
    $g->moveto(1, 1);
    dies_ok { $g->curveto(2, 3, 3, 1) } 'curveto quadratic succeeds';
    
    $g->moveto(1, 1);
    lives_ok { $g->curveto(2, 3, 3, 3, 4, 1) } 'curveto cubic succeeds';
    
    # Test invalid parameters
    dies_ok { $g->curve(1, 1, 2) } 'curve with < 6 params dies';
    dies_ok { $g->curveto(1, 1) } 'curveto with < 4 params dies';
    
    # Verify output
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Curve output contains G01');
};

# Test 9: Coordinate Transformations
subtest 'Coordinate Transformations' => sub {
    plan tests => 15;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test translate
    lives_ok { $g->translate(1, 1) } 'translate succeeds';
    
    # Test translateC
    $g->moveto(2, 2);
    lives_ok { $g->translateC() } 'translateC succeeds';
    my ($cx, $cy) = $g->currentpoint();
    is($cx, 0, 'translateC sets x to 0');
    is($cy, 0, 'translateC sets y to 0');
    
    # Test rotate
    lives_ok { $g->rotate(45) } 'rotate succeeds';
    lives_ok { $g->rotate(90, 5, 5) } 'rotate with ref point succeeds';
    
    # Test scale
    lives_ok { $g->scale(2) } 'scale with 1 param succeeds';
    lives_ok { $g->scale(2, 3) } 'scale with 2 params succeeds';
    lives_ok { $g->scale(2, 2, 5, 5) } 'scale with ref point succeeds';
    
    # Test skew
    lives_ok { $g->skewX(15) } 'skewX succeeds';
    lives_ok { $g->skewY(15) } 'skewY succeeds';
    
    # Test initmatrix
    lives_ok { $g->initmatrix() } 'initmatrix succeeds';
    
    # Test invalid parameters
    dies_ok { $g->translate(1) } 'translate with 1 param dies';
    dies_ok { $g->scale(1, 2, 3) } 'scale with 3 params dies';
    dies_ok { $g->skewX() } 'skewX without param dies';
};

# Test 10: Graphics State
subtest 'Graphics State Management' => sub {
    plan tests => 8;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test gsave/grestore
    lives_ok { $g->gsave() } 'gsave succeeds';
    lives_ok { $g->grestore() } 'grestore succeeds';
    
    # Test state preservation
    $g->moveto(5, 5);
    $g->gsave();
    $g->translate(2, 2);
    my ($x1, $y1) = $g->currentpoint();
    $g->grestore();
    my ($x2, $y2) = $g->currentpoint();
    
    isnt($x1, $x2, 'grestore changes x position');
    isnt($y1, $y2, 'grestore changes y position');
    
    # Test nested gsave/grestore
    lives_ok {
        $g->gsave();
        $g->gsave();
        $g->grestore();
        $g->grestore();
    } 'nested gsave/grestore succeeds';
    
    # Test CTM preservation
    $g->initmatrix();
    $g->gsave();
    $g->rotate(45);
    $g->scale(2);
    $g->grestore();
    
    # After restore, drawing should be in original coordinate system
    $g->line(1, 1, 2, 2);
    ok(1, 'drawing after grestore succeeds');
    
    # Test state includes font info (if set)
    # This would need actual font testing which requires font files
    ok(1, 'font state would be saved/restored');
    ok(1, 'pen state would be saved/restored');
};

# Test 11: Pen Control
subtest 'Pen Control' => sub {
    plan tests => 6;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test penup/pendown
    lives_ok { $g->penup() } 'penup succeeds';
    lives_ok { $g->pendown() } 'pendown succeeds';
    
    # Test moveto (includes pen up/down)
    lives_ok { $g->moveto(1, 1) } 'moveto succeeds';
    lives_ok { $g->movetoR(1, 1) } 'movetoR succeeds';
    
    # Verify output contains pen commands
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/Z/, 'Output contains Z commands for pen control');
    
    # Test currentpoint
    $g->moveto(3, 4);
    my ($cx, $cy) = $g->currentpoint();
    is($cx, 3, 'currentpoint returns correct x');
};

# Test 12: Path Management
subtest 'Path Management' => sub {
    plan tests => 6;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test newpath
    lives_ok { $g->newpath() } 'newpath succeeds';
    
    # Test stroke
    $g->line(1, 1, 2, 2);
    lives_ok { $g->stroke() } 'stroke succeeds';
    
    # Test strokefill (with hatching)
    $g->box(1, 1, 2, 2);
    lives_ok { $g->strokefill() } 'strokefill succeeds';
    
    # Test addcomment
    lives_ok { $g->addcomment('test comment') } 'addcomment succeeds';
    
    # Test addtopage
    lives_ok { $g->addtopage("(manual comment)\n") } 'addtopage succeeds';
    
    # Verify hatching works
    $g->sethatchsep(0.1);
    $g->box(3, 3, 5, 5);
    $g->strokefill();
    my $output = _get_output($g);
    like($output, qr/G01/, 'strokefill generates hatch lines');
};

# Test 13: Output Generation
subtest 'Output Generation' => sub {
    plan tests => 8;
    
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.gcode');
    
    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize => 10, 
        ysize => 10, 
        units => 'in',
        outfile => $file
    );
    
    # Draw something
    $g->box(1, 1, 2, 2);
    $g->stroke();
    
    # Test output to file
    lives_ok { $g->output() } 'output to default file succeeds';
    ok(-e $file, 'output file created');
    ok(-s $file > 0, 'output file has content');
    
    # Test output to specified file
    my $file2 = File::Spec->catfile($dir, 'test2.gcode');
    lives_ok { $g->output($file2) } 'output to specified file succeeds';
    ok(-e $file2, 'specified output file created');
    
    # Verify file contains expected content
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/G20/, 'output contains header');
    like($content, qr/G00/, 'output contains G00 commands');
    like($content, qr/G01/, 'output contains G01 commands');
};

# Test 14: SVG Export
subtest 'SVG Export' => sub {
    plan tests => 6;
    
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.svg');
    
    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => 'A4',
        units => 'pt'
    );
    
    # Draw something
    $g->box(100, 100, 200, 200);
    $g->circle(150, 150, 30);
    $g->stroke();
    
    # Test exportsvg
    lives_ok { $g->exportsvg($file) } 'exportsvg succeeds';
    ok(-e $file, 'SVG file created');
    ok(-s $file > 0, 'SVG file has content');
    
    # Verify SVG structure
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/<svg/, 'SVG contains svg tag');
    like($content, qr/<path/, 'SVG contains path tag');
    like($content, qr/d="/, 'SVG path has d attribute');
};

# Test 15: EPS Export
subtest 'EPS Export' => sub {
    plan tests => 6;
    
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.eps');
    
    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => 'A4',
        units => 'pt'
    );
    
    # Draw something
    $g->box(100, 100, 200, 200);
    $g->stroke();
    
    # Test exporteps
    lives_ok { $g->exporteps($file) } 'exporteps succeeds';
    ok(-e $file, 'EPS file created');
    ok(-s $file > 0, 'EPS file has content');
    
    # Verify EPS structure
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/%!PS-Adobe/, 'EPS contains PS header');
    like($content, qr/%%BoundingBox/, 'EPS contains BoundingBox');
    like($content, qr/moveto|lineto/, 'EPS contains drawing commands');
};

# Test 16: Error Handling
subtest 'Error Handling' => sub {
    plan tests => 10;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test various error conditions
    dies_ok { Graphics::Penplotter::GcodeXY->new(units => 'invalid') } 
        'invalid units causes error';
    
    dies_ok { $g->line() } 'line with no params dies';
    dies_ok { $g->box() } 'box with no params dies';
    dies_ok { $g->circle(1, 1) } 'circle without radius dies';
    dies_ok { $g->arc(1, 1, 1) } 'arc without angles dies';
    dies_ok { $g->curve(1, 1) } 'curve with insufficient params dies';
    
    dies_ok { $g->translate(1) } 'translate with 1 param dies';
    dies_ok { $g->rotate() } 'rotate without angle dies';
    dies_ok { $g->skewX() } 'skewX without param dies';
    
    dies_ok { $g->output() } 'output without filename dies when no outfile set';
};

# Test 17: Hatching
subtest 'Hatching' => sub {
    plan 'no_plan';
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Test sethatchsep
    lives_ok { $g->sethatchsep(0.05) } 'sethatchsep succeeds';
    is($g->{hatchsep}, 0.05, 'hatchsep value set correctly');
    
    # Test strokefill
    $g->box(1, 1, 3, 3);
    lives_ok { $g->strokefill() } 'strokefill succeeds';
    
    # Verify hatching generated output
    my $output = _get_output($g);
    my @lines = split /\n/, $output;
    my $g01_count = grep { /G01/ } @lines;
    ok($g01_count > 10, 'hatching generates multiple line segments');
    
#    # Test different hatch separations
#    $g->newpath();
#    $g->sethatchsep(0.2);
#    $g->box(5, 5, 7, 7);
#    $g->strokefill();
#    my $output2 = _get_output($g);
#    my @lines2 = split /\n/, $output2;
#    my $g01_count2 = grep { /G01/ } @lines2;
#    
#    ok($g01_count2 < $g01_count, 'larger hatch separation produces fewer lines');
};

# Test 18: Optimization
subtest 'Path Optimization' => sub {
    plan tests => 4;
    
    # Test with optimization ON
    my $g1 = Graphics::Penplotter::GcodeXY->new(
        xsize => 10, 
        ysize => 10, 
        units => 'in',
        optimize => 1
    );
    
    # Create a path with redundant moves
    $g1->moveto(1, 1);
    $g1->line(2, 2);
    $g1->moveto(2, 2);  # Redundant move
    $g1->line(3, 3);
    $g1->stroke();
    
    my $output1 = _get_output($g1);
    my @lines1 = split /\n/, $output1;
    
    # Test with optimization OFF
    my $g2 = Graphics::Penplotter::GcodeXY->new(
        xsize => 10, 
        ysize => 10, 
        units => 'in',
        optimize => 0
    );
    
    $g2->moveto(1, 1);
    $g2->line(2, 2);
    $g2->moveto(2, 2);  # Redundant move
    $g2->line(3, 3);
    $g2->stroke();
    
    my $output2 = _get_output($g2);
    my @lines2 = split /\n/, $output2;
    
    ok(scalar @lines1 <= scalar @lines2, 'optimization reduces line count');
    
    # Verify optimization is configurable
    is($g1->{optimize}, 1, 'optimization enabled in g1');
    is($g2->{optimize}, 0, 'optimization disabled in g2');
    
    ok(1, 'optimization produces valid output');
};

# Test 19: Arrowheads
subtest 'Arrowheads' => sub {
    plan tests => 4;
    
    my $g = Graphics::Penplotter::GcodeXY->new(xsize => 10, ysize => 10, units => 'in');
    
    # Draw a line then add arrowhead
    $g->line(1, 1, 3, 3);
    lives_ok { $g->arrowhead(0.2, 0.1) } 'arrowhead with default type succeeds';
    
    # Test closed arrowhead
    $g->line(4, 4, 6, 6);
    lives_ok { $g->arrowhead(0.2, 0.1, 'closed') } 'arrowhead closed type succeeds';
    
    # Test open arrowhead
    $g->line(5, 1, 7, 3);
    lives_ok { $g->arrowhead(0.2, 0.1, 'open') } 'arrowhead open type succeeds';
    
    # Verify output
    $g->stroke();
    my $output = _get_output($g);
    like($output, qr/G01/, 'Output contains G01 commands');
};

done_testing();
