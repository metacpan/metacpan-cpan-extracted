#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Digest::MD5 qw(md5_hex);
use Test::More tests => 7 + 2 * 20; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Info');
   use_ok('FLV::FromSWF');
   use_ok('FLV::ToSWF');
}

my @samples = (
   {
      swffile => File::Spec->catfile('t', 'samples', 'flash6.swf'),
      flvfile => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      comparemeta => [qw(framerate audiocodecid videocodecid width height)],
   },
   {
      swffile => File::Spec->catfile('t', 'samples', 'flash8.swf'),
      flvfile => File::Spec->catfile('t', 'samples', 'flash8.flv'),
      comparemeta => [qw(framerate audiocodecid videocodecid width height)],
   },
);

my @cleanup;

# SWF -> FLV

{
   my $converter = FLV::FromSWF->new();
   eval { $converter->parse_swf('nosuchfile.swf'); };
   like($@, qr/Can't open/, 'FromSWF parse non-existent file');

   eval { $converter->save(File::Spec->catfile('nosuchdir/file.flv')); };
   like($@, qr/Failed to write/, 'FromSWF impossible output filename');
}

for my $sample (@samples)
{
   my $reader = FLV::Info->new();
   $reader->parse($sample->{flvfile});
   my $origflv = $reader->get_file();

   my $converter = FLV::FromSWF->new();
   $converter->parse_swf($sample->{swffile});

   # Write the FLV back out as a temp file
   my ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   close $fh;
   $converter->save($tempfilename);

   my $rereader = FLV::Info->new();
   $rereader->parse($tempfilename);
   my $newflv = $rereader->get_file();

   for my $key (@{$sample->{comparemeta}})
   {
      is($newflv->get_meta($key), $origflv->get_meta($key), 'FromSWF meta '.$key);
   }

   is(scalar $newflv->get_body()->get_video_frames(),
      scalar $origflv->get_body()->get_video_frames(), 'FromSWF video frames');
   #is(scalar $newflv->get_body()->get_audio_packets(),
   #   scalar $origflv->get_body()->get_audio_packets(), 'FromSWF audio packets');
   is(scalar $newflv->get_body()->get_meta_tags(),
      scalar $origflv->get_body()->get_meta_tags(), 'FromSWF meta tags');

   #for my $tag ($newflv->get_body()->get_video_frames(),
   #             $origflv->get_body()->get_video_frames())
   #{
   #   $tag->{data_length} = length $tag->{data};
   #   $tag->{data_md5} = md5_hex($tag->{data});
   #   delete $tag->{data};
   #}

   is_deeply([$newflv->get_body()->get_video_frames()],
             [$origflv->get_body()->get_video_frames()],
             'FromSWF detailed videotag comparison');

   my @newaudio = map {$_->{data}} $newflv->get_body()->get_audio_packets();
   my @origaudio = map {$_->{data}} $origflv->get_body()->get_audio_packets();
   my $newaudio = join q{}, @newaudio;
   my $origaudio = join q{}, @origaudio;

   # Deliberately ignore omitted trailing audio
   # This is an issue with the On2 Flix 8.004 FLV vs. SWF **encoders**
   if (length $newaudio < length $origaudio)
   {
      $origaudio = substr $newaudio, 0, length $newaudio;
   }

   # This test is silly, given the above
   is(length($newaudio), length($origaudio), 'FromSWF detailed audio data comparison');

   is(md5_hex($newaudio), md5_hex($origaudio), 'FromSWF detailed audio data comparison');
}

# FLV -> SWF

{
   my $converter = FLV::ToSWF->new();
   eval { $converter->parse_flv('nosuchfile.flv'); };
   like($@, qr/Failed to read FLV file/, 'ToSWF parse non-existent file');

   eval { $converter->save(File::Spec->catfile('nosuchdir/file.swf')); };
   like($@, qr/Can't open/, 'ToSWF impossible output filename');
}

for my $sample (@samples)
{
   my $converter = FLV::ToSWF->new();
   $converter->parse_flv($sample->{flvfile});
   my $origflv = $converter->{flv};
   # Write the SWF back out as a temp file
   my ($fh, $tempswf) = tempfile();
   die if (! -f $tempswf);
   push @cleanup, $tempswf;
   close $fh;
   $converter->save($tempswf);

   my $reconverter = FLV::FromSWF->new();
   $reconverter->parse_swf($tempswf);
   my $newflv = $reconverter->{flv};

   for my $key (@{$sample->{comparemeta}})
   {
      is($newflv->get_meta($key), $origflv->get_meta($key), 'ToSWF meta '.$key);
   }

   is(scalar $newflv->get_body()->get_video_frames(),
      scalar $origflv->get_body()->get_video_frames(), 'ToSWF video frames');
   #is(scalar $newflv->get_body()->get_audio_packets(),
   #   scalar $origflv->get_body()->get_audio_packets(), 'ToSWF audio packets');
   is(scalar $newflv->get_body()->get_meta_tags(),
      scalar $origflv->get_body()->get_meta_tags(), 'ToSWF meta tags');

   is_deeply([$newflv->get_body()->get_video_frames()],
             [$origflv->get_body()->get_video_frames()],
             'ToSWF detailed videotag comparison');
   
   # Need to account for the fact that SWF lumps audio frames together but FLV doesn't
   my @newaudio = map {$_->{data}} $newflv->get_body()->get_audio_packets();
   my @origaudio = map {$_->{data}} $origflv->get_body()->get_audio_packets();
   my $newaudio = join q{}, @newaudio;
   my $origaudio = join q{}, @origaudio;
   
   # Reconstitute orig with the same gaps as new
   my $bytes = 0;
   @origaudio = map {my $o=$bytes;$bytes+=length;substr $origaudio, $o, length} @newaudio;
   if ($bytes < length $origaudio)
   {
      $origaudio[-1] .= substr $origaudio, $bytes;
   }

   ## Even more detailed tests.  Turn these on to find the exact error if the "detailed" tests below fail
   if (0)
   {
      for my $i (0..$#newaudio)
      {
         is(length($newaudio[$i]), length($origaudio[$i]), 'length '.$i);
         is(md5_hex($newaudio[$i]), md5_hex($origaudio[$i]), 'md5 '.$i);
      }
   }

   is(length($newaudio), length($origaudio), 'detailed audio data comparison');
   is(md5_hex($newaudio), md5_hex($origaudio), 'detailed audio data comparison');
}


END
{
   # Delete temp files
   unlink $_ for @cleanup;
}
