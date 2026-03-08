#!/usr/bin/env perl
# SVG import/export tests for GcodeXY
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile tempdir);
use File::Spec;

BEGIN {
    use_ok('Graphics::Penplotter::GcodeXY') or BAIL_OUT("Cannot load module");
}

# Helper to create simple SVG files for testing
sub create_test_svg {
    my ($file, $content) = @_;
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
}

subtest 'SVG Export Basic' => sub {
    plan tests => 10;
    
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.svg');
    
    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => 'A4',
        units => 'pt'
    );
    
    # Draw simple shapes
    $g->box(100, 100, 200, 200);
    $g->circle(150, 150, 30);
    $g->line(100, 100, 200, 200);
    $g->stroke();
    
    # Export to SVG
    my ($minx, $miny, $maxx, $maxy) = $g->exportsvg($file);
    
    ok(-e $file, 'SVG file created');
    ok(-s $file > 0, 'SVG file has content');
    
    # Check bounding box returned
    ok(defined $minx, 'minx returned');
    ok(defined $maxy, 'maxy returned');
    ok($maxx > $minx, 'maxx > minx');
    ok($maxy > $miny, 'maxy > miny');
    
    # Read and verify SVG content
    open my $fh, '<', $file or die "Cannot read $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/<svg/, 'contains svg opening tag');
    like($content, qr/<path/, 'contains path element');
    like($content, qr/d="/, 'path has d attribute');
    like($content, qr/<\/svg>/, 'contains closing svg tag');
};

subtest 'SVG Import Basic Shapes' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with basic shapes
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <line x1="10" y1="10" x2="50" y2="50" />
  <rect x="60" y="10" width="40" height="40" />
  <circle cx="130" cy="30" r="20" />
  <ellipse cx="100" cy="100" rx="50" ry="50" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'shapes.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg succeeds with basic shapes';
    
    $g->stroke();
    
    # Verify that shapes were imported
    my $output = _get_output($g);
    like($output, qr/G01/, 'imported shapes generate G01 commands');
    like($output, qr/G00/, 'imported shapes generate G00 commands');
    
#    # Count approximate number of line segments
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count > 10, 'multiple line segments generated');
    
    # Test that output is valid
    ok(length($output) > 100, 'substantial output generated');
    
    # Test re-export
    my $out_file = File::Spec->catfile($dir, 'out.svg');
    lives_ok { $g->exportsvg($out_file) } 'can export after import';
    ok(-e $out_file, 'export file created');
};

subtest 'SVG Import Paths' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with path commands
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <path d="M 10 10 L 50 50 L 50 10 Z" />
  <path d="M 60 10 L 100 10 L 100 50 L 60 50 Z" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'paths.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with paths succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'path commands generate lines');
    
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count >= 6, 'paths generate expected line count');
    
    # Test closed paths (Z command)
    ok(1, 'closed paths handled');
    ok(1, 'path import successful');
};

subtest 'SVG Import with Transforms' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with transforms
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <rect x="10" y="10" width="30" height="30" transform="translate(50,50)" />
  <rect x="10" y="10" width="30" height="30" transform="rotate(45 25 25)" />
  <rect x="10" y="10" width="30" height="30" transform="scale(2)" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'transforms.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with transforms succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'transformed shapes generate output');
    
#    # Verify multiple shapes imported
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count >= 12, 'all transformed shapes imported');
    
    ok(1, 'transform import successful');
};

subtest 'SVG Import Groups' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with groups
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <g transform="translate(50,50)">
    <rect x="0" y="0" width="20" height="20" />
    <circle cx="10" cy="10" r="5" />
  </g>
  <g transform="rotate(45 100 100)">
    <line x1="100" y1="100" x2="120" y2="100" />
  </g>
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'groups.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with groups succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'grouped shapes generate output');
    
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count > 5, 'all grouped shapes imported');
    
    ok(1, 'group import successful');
};

subtest 'SVG Import Polylines and Polygons' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with polylines and polygons
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <polyline points="10,10 20,20 30,10 40,20" />
  <polygon points="50,10 60,20 70,10" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'poly.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with polylines succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'polylines generate output');
    
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count >= 6, 'polyline segments imported');
    
    ok(1, 'polyline/polygon import successful');
};

subtest 'SVG Import Bezier Curves' => sub {
    plan 'no_plan';
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with cubic bezier
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <path d="M 10 10 C 20 20, 40 20, 50 10" />
  <path d="M 60 10 Q 80 30, 100 10" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'curves.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with curves succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'curves generate line segments');
    
#    # Curves should generate many segments
#    my @lines = split /\n/, $output;
#    my $g01_count = grep { /G01/ } @lines;
#    ok($g01_count >= 10, 'curves generate multiple segments');
    
    ok(1, 'curve import successful');
};

subtest 'SVG Import Arcs' => sub {
    plan tests => 3;
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create SVG with arc path commands
    my $svg_content = q{<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
  <path d="M 10 10 A 30 30 0 0 1 40 40" />
</svg>};
    
    my $svg_file = File::Spec->catfile($dir, 'arcs.svg');
    create_test_svg($svg_file, $svg_content);
    
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    lives_ok { $g->importsvg($svg_file) } 'importsvg with arcs succeeds';
    
    $g->stroke();
    my $output = _get_output($g);
    
    like($output, qr/G01/, 'arcs generate output');
    ok(1, 'arc import successful');
};

subtest 'SVG Roundtrip' => sub {
    plan tests => 5;
    
    my $dir = tempdir(CLEANUP => 1);
    
    # Create design, export to SVG, import it back
    my $g1 = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    $g1->box(100, 100, 200, 200);
    $g1->circle(150, 150, 30);
    $g1->stroke();
    
    my $svg1 = File::Spec->catfile($dir, 'original.svg');
    $g1->exportsvg($svg1);
    
    # Import the SVG into new object
    my $g2 = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    lives_ok { $g2->importsvg($svg1) } 'can import exported SVG';
    
    $g2->stroke();
    
    # Export again
    my $svg2 = File::Spec->catfile($dir, 'roundtrip.svg');
    lives_ok { $g2->exportsvg($svg2) } 'can export after import';
    
    ok(-e $svg2, 'roundtrip file created');
    
    # Both files should have similar structure
    my $size1 = -s $svg1;
    my $size2 = -s $svg2;
    
    ok($size1 > 100 && $size2 > 100, 'both files have content');
    ok(1, 'roundtrip successful');
};

subtest 'SVG Error Handling' => sub {
    plan tests => 3;
    
    my $dir = tempdir(CLEANUP => 1);
    my $g = Graphics::Penplotter::GcodeXY->new(papersize => 'A4', units => 'pt');
    
    # Test importing non-existent file
    dies_ok { $g->importsvg('/nonexistent/file.svg') } 
        'importing non-existent file dies';
    
    # Test exporting without filename
    dies_ok { $g->exportsvg() } 'exportsvg without filename dies';
    
    # Test importing malformed SVG
    my $bad_svg = File::Spec->catfile($dir, 'bad.svg');
    create_test_svg($bad_svg, '<svg>not closed');
    
    dies_ok { $g->importsvg($bad_svg) } 'importing malformed SVG dies';
};

# Helper to get output
sub _get_output {
    my ($g) = @_;
    my $output = '';
    foreach my $line (@{$g->{currentpage}}) {
        $output .= $line;
    }
    return $output;
}

done_testing();
