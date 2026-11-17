package Holmgang::Images;
# Test helpers for images in cases (k27): tiny PNG and JPEG byte strings made in
# memory, and a fan suite whose case carries an image. Everything here is
# invented (ADR 0003).
use strict;
use warnings;
use Exporter qw( import );
use Compress::Zlib ();
use Path::Tiny ();

use Holmgang::SuiteDir qw( suite_dir $FAN_HEAD );

our @EXPORT_OK = qw( png jpeg image_suite $IMAGE_CASE );

# a grey PNG of $w x $h with the given shade (so two images differ in bytes)
sub png {
  my ( $w, $h, $shade ) = @_;
  $shade //= 0x80;
  my $raw = join '', map { "\0".( chr($shade) x $w ) } 1 .. $h;
  my $chunk = sub {
    my ( $type, $data ) = @_;
    return pack( 'N', length $data ).$type.$data.pack( 'N', Compress::Zlib::crc32( $type.$data ) );
  };
  return "\x89PNG\r\n\x1a\n"
    .$chunk->( 'IHDR', pack( 'NNCCCCC', $w, $h, 8, 0, 0, 0, 0 ) )
    .$chunk->( 'IDAT', Compress::Zlib::compress($raw) )
    .$chunk->( 'IEND', '' );
}

# the header of a baseline JPEG of $w x $h: SOI, an APP0 segment, SOF0; enough
# for the loader, which reads the frame header and never decodes
sub jpeg {
  my ( $w, $h ) = @_;
  my $app0 = "JFIF\0\x01\x01\0\0\x01\0\x01\0\0";
  return "\xFF\xD8"
    ."\xFF\xE0".pack( 'n', 2 + length $app0 ).$app0
    ."\xFF\xC0".pack( 'n', 17 )."\x08".pack( 'nn', $h, $w )."\x03"."\x01\x22\0\x02\x11\x01\x03\x11\x01"
    ."\xFF\xD9";
}

our $IMAGE_CASE = <<'Y';
id: c1
title: Cool the room as the picture says
messages:
  - role: user
    content: "Set the fan as the note in the picture says."
    images:
      - file: img/note.png
state: { fan: { level: off } }
rules:
  - { title: fan on high, state: fan.level, equals: high }
  - { title: nothing else, unchanged_except: [ fan.level ] }
solution: [ { tool: fan_set, args: { level: high } } ]
alternatives: [ { title: stepwise, calls: [ { tool: fan_set, args: { level: low } }, { tool: fan_set, args: { level: high } } ] } ]
wrong_solutions: [ { title: low only, calls: [ { tool: fan_set, args: { level: low } } ] } ]
Y

# image_suite( case => $yaml, files => { 'img/note.png' => $bytes }, %suite_dir_options )
sub image_suite {
  my ( %o ) = @_;
  my $files = delete $o{files} // { 'img/note.png' => png( 8, 6 ) };
  my $case  = delete $o{case}  // $IMAGE_CASE;
  my ( $dir, $id ) = suite_dir( %o, cases => { 'c1.yaml' => $case, %{ delete $o{more} || {} } } );
  for my $f ( sort keys %$files ) {
    my $p = Path::Tiny::path( $dir, $f );
    $p->parent->mkpath;
    $p->spew_raw( $files->{$f} );
  }
  return wantarray ? ( $dir, $id ) : $dir;
}

1;
