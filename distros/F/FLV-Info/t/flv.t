#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 12 + 2 * 18; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Info');
}

my @samples = (
   {
      file => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      expect => {
         video_codec => 'Sorenson H.263',
         duration => '7418',
         audio_format => 'MP3',
         audio_type => 'stereo',
         meta_framerate => '20',

         has_video => 1,
         has_audio => 1,
         tags => 435,
         video_tags => 149,
         audio_tags => 285,
         meta_tags => 1,
      },
   },
   {
      file => File::Spec->catfile('t', 'samples', 'flash8.flv'),
      expect => {
         video_codec => 'On2 VP6',
         duration => '7418',
         audio_format => 'MP3',
         audio_type => 'stereo',
         meta_framerate => '20',

         has_video => 1,
         has_audio => 1,
         tags => 435,
         video_tags => 149,
         audio_tags => 285,
         meta_tags => 1,
      },
   },
);

my @cleanup;

END
{
   # Delete temp files
   unlink $_ for @cleanup;
}

{
   my $reader = FLV::Info->new();
   eval { $reader->parse('nosuchfile.flv'); };
   like($@, qr/Failed to read FLV file/, 'parse non-existent file');

   my ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse empty file');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'foo';
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse non-flv file');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'FLV';
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse non-flv file');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'foo' x 1000;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Not an FLV file/, 'parse long non-flv file');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 200, 0, 9;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/only understand FLV version 1/, 'parse badly versioned flv header');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 1, 128, 9;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Reserved header flags are non-zero/, 'parse reserved-flag using flv header');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 1, 0, 8;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Illegal value for body offset/, 'parse too-small length flv header');

   ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCNC', 1, 0, 10, 0;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse long flv header');

   eval { $reader->get_file()->serialize(); };
   like($@, qr/Please specify a filehandle/, 'serialize with no filehandle');

   # Expect a failure with a warning
   local $SIG{__WARN__} = sub{};
   ok(!$reader->get_file()->serialize($fh), 'serialize with closed filehandle');
}

for my $sample (@samples)
{
   # Read an FLV file and check selected metadata against expectations
   my $reader = FLV::Info->new();
   ok(!scalar $reader->get_info(), 'get_info');
   $reader->parse($sample->{file});
   ok(scalar $reader->get_info(), 'get_info');
   ok($reader->report(), 'report');

   my $flv = $reader->get_file();
   is($flv->get_filename(), $sample->{file}, 'get_filename');

   my %info = (
      $reader->get_info(),
      'has_video'  => $flv->get_header()->has_video(),
      'has_audio'  => $flv->get_header()->has_audio(),
      'tags'       => scalar $flv->get_body()->get_tags(),
      'video_tags' => scalar $flv->get_body()->get_video_frames(),
      'audio_tags' => scalar $flv->get_body()->get_audio_packets(),
      'meta_tags'  => scalar $flv->get_body()->get_meta_tags(),
      #'end_time'   => $flv->get_body()->end_time(),
   );

   #use Data::Dumper;
   #diag Dumper \%info;
   #diag Dumper [$flv->get_body()->get_meta_tags()];
   for my $key (sort keys %{$sample->{expect}})
   {
      is($info{$key}, $sample->{expect}->{$key}, $sample->{file}.' - '.$key);
   }

   # Write the FLV back out as a temp file
   my ($fh, $tempfilename) = tempfile();
   die if (! -f $tempfilename);
   push @cleanup, $tempfilename;
   ok($flv->serialize($fh), 'serialize');
   close $fh;
   
   # Read the temp file back and compare it to the original -- should
   # be identical except for hash key ordering
   my $rereader = FLV::Info->new();
   $rereader->parse($tempfilename);
   my $newflv = $rereader->get_file();

   # remove filename properties which are guaranteed to differ
   $flv->{filename} = undef;
   $newflv->{filename} = undef;
   is_deeply($newflv, $flv, 'compare re-serialized');
   # read it again, this time via filehandle
   open my $fh2, '<', $tempfilename or die;
   binmode $fh2 or die;
   $rereader->parse($fh2);
   close $fh2;
   is_deeply($newflv, $flv, 'compare re-serialized');
}
