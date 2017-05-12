#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 1 + 1 * 11; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Splice');
}

my @samples = (
   {
      file => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      expect => {
         duration => 7400,
         last_time => 7418,
         one_frame => 50,
         video_tags => 149,
         audio_tags => 285,
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
   my $expect = $sample->{expect};
   my $total_tags = $expect->{video_tags} + $expect->{audio_tags};

   my $outfile = (tempfile)[1];
   push @cleanup, $outfile;

   my $instance = FLV::File->new;
   $instance->parse($sample->{file});
   is($instance->get_body->last_start_time, $expect->{last_time}, 'verify expected duration (sanity)');

   for my $in1 ($sample->{file}, $instance) {
      for my $in2 ($sample->{file}, $instance) {
         my $s = FLV::Splice->new();
         $s->add_input($in1);
         $s->add_input($in2);
         $s->save($outfile);

         my $check = FLV::File->new;
         $check->parse($outfile);
         is($check->get_body->get_video_frames + $check->get_body->get_audio_packets,
            2 * ($expect->{video_tags} + $expect->{audio_tags}), 'verify size doubled');
         my $end = $check->get_header->has_video
             ? [$check->get_body->get_video_frames]->[-1]->{start}
             : [$check->get_body->get_audio_packets]->[-1]->{start};
         is($end, 2 * $expect->{duration} + $expect->{one_frame},
            'verify duration doubled');
      }
   }

   my $s = FLV::Splice->new();
   $s->add_input($instance);
   $s->add_input($instance);
   $s->add_input($instance);
   $s->add_input($instance);
   $s->save($outfile);

   my $check = FLV::File->new;
   $check->parse($outfile);
   is($check->get_body->get_video_frames + $check->get_body->get_audio_packets,
      4 * ($expect->{video_tags} + $expect->{audio_tags}), 'verify size quadrupled');
   my $end = $check->get_header->has_video
       ? [$check->get_body->get_video_frames]->[-1]->{start}
       : [$check->get_body->get_audio_packets]->[-1]->{start};
   is($end, 4 * $expect->{duration} + 3 * $expect->{one_frame},
      'verify duration quadrupled');
}
