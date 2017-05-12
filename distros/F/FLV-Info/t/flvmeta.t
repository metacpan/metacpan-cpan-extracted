#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 1 + 2 * 5; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Info');
}

my @samples = (
   {
      file => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      expect => {
      },
   },
   {
      file => File::Spec->catfile('t', 'samples', 'flash8.flv'),
      expect => {
      },
   },
);

my @cleanup;

END
{
   # Delete temp files
   unlink $_ for @cleanup;
}

for my $sample (@samples)
{
   # Read an FLV file and check selected metadata against expectations
   my $flv = FLV::File->new();
   $flv->parse($sample->{file});
   $flv->populate_meta();

   # Write the FLV back out as a temp file
   my ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   ok($flv->serialize($fh), 'serialize');
   close $fh;
   
   # Read the temp file back and compare it to the original -- should
   # be identical except for hash key ordering
   my $newflv = FLV::File->new();
   $newflv->parse($tempfilename, { record_positions => 1 });

   my @keyframes = $newflv->get_body->get_video_keyframes;
   is($newflv->get_meta('filesize'), -s $tempfilename, 'meta filesize');
   is_deeply($newflv->get_meta('keyframes')->{filepositions},
             [map {$_->_pos()} @keyframes], 'meta keyframe positions');
   is_deeply([map {sprintf '%.03f', $_} @{$newflv->get_meta('keyframes')->{times}}],
             [map {sprintf '%.03f', 0.001*$_->{start}} @keyframes], 'meta keyframe times');
             
   my $reader = FLV::Info->new();
   $reader->parse($tempfilename);
   like($reader->report(), qr/>>>/, 'keyframe metadata is in report');
}
