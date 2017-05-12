#!/usr/bin/perl -w
use strict;
use Font::FreeType;

die "Usage: $0 font-filename\n"
  unless @ARGV == 1;
my ($filename) = @ARGV;

my $face = Font::FreeType->new->face($filename);

print "Family name: ", $face->family_name, "\n";
print "Style name: ", $face->style_name, "\n"
  if defined $face->style_name;
print "PostScript name: ", $face->postscript_name, "\n"
  if defined $face->postscript_name;

my @properties;

push @properties, 'Bold' if $face->is_bold;
push @properties, 'Italic' if $face->is_italic;
print join('  ', @properties), "\n" if @properties;

@properties = ();
push @properties, 'Scalable' if $face->is_scalable;
push @properties, 'Fixed width' if $face->is_fixed_width;
push @properties, 'Kerning' if $face->has_kerning;
push @properties, 'Glyph names' .
                  ($face->has_reliable_glyph_names ? '' : ' (unreliable)')
  if $face->has_glyph_names;
push @properties, 'SFNT' if $face->is_sfnt;
push @properties, 'Horizontal' if $face->has_horizontal_metrics;
push @properties, 'Vertical' if $face->has_vertical_metrics;
print join('  ', @properties), "\n" if @properties;

print "Units per em: ", $face->units_per_em, "\n" if $face->units_per_em;
if ($face->is_scalable) {
    my $bb = $face->bounding_box;
    print sprintf('Global BBox: (%d,%d):(%d,%d)',
                  map { $bb->$_ } qw/x_min y_min x_max y_max/),
        "\n";
    print "Ascent: ", $face->ascender, "\n";
    print "Descent: ", $face->descender, "\n";
    print "Text height: ", $face->height, "\n";
}
print "Number of glyphs: ", $face->number_of_glyphs, "\n";
print "Number of faces: ", $face->number_of_faces, "\n"
  if $face->number_of_faces > 1;

if ($face->fixed_sizes) {
    print "Fixed sizes:\n";
    foreach my $size ($face->fixed_sizes) {
        print "    ",
              join ', ',
              map { exists $size->{$_} ? sprintf "$_ %g", $size->{$_} : () }
              qw( size width height x_res_dpi y_res_dpi );
        print "\n";
    }
}

# vi:ts=4 sw=4 expandtab
