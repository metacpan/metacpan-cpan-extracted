package FLV::Splice;

use warnings;
use strict;
use 5.008;

use FLV::File;
use FLV::Util;
use List::MoreUtils qw(any);
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $VERSION = '0.24';

=for stopwords FLVs codec AVC framerates

=head1 NAME

FLV::Splice - Concatenate FLV files into new files

=head1 ACKNOWLEDGMENTS

This feature was created with financial support from John Drago
(CPAN:JOHND).  Thanks!

=head1 LICENSE

See L<FLV::Info>

=head1 SYNOPSIS

   use FLV::Splic;
   my $converter = FLV::Splice->new();
   $converter->add_input('first.flv');
   $converter->add_input('second.flv');
   $converter->save('output.flv');

=head1 DESCRIPTION

Concatenates compatible FLV movies into a single file.  In this
context, 'compatible' means that they have the same video and audio
codec.  It is possible that this tool will produce unplayable movies,
for example concatenating AVC content will likely fail because each
segment has its own binary configuration block.

This tool may also produce unplayable content if the segments have
different framerates.  That depends on the player implementation.

=head1 METHODS

=over

=item $pkg->new()

Instantiate a converter.

=cut

sub new
{
   my $pkg = shift;

   my $start = { time => 0 };
   my $self = bless {
      start         => 0,
      nvideo        => 0,
      naudio        => 0,
      last_vid_time => 0,
      last_aud_time => 0,
   }, $pkg;
   return $self;
}

=item $self->add_input($flv_filename)

=item $self->add_input($flv_instance)

Open and append the specified FLV file.  Alternatively, you may pass an
instantiated and parsed L<FLV::File> instance.

=cut

sub add_input  ## no critic (Complexity)
{
   my $self   = shift;
   my $infile = shift;

   my $flv;
   if (ref $infile && $infile->isa('FLV::File'))
   {
      $flv = $infile->clone;
   }
   else
   {
      $flv = FLV::File->new;
      $flv->parse($infile);
   }

   if ($self->{flv})
   {
      # add 2nd, 3rd, etc
      if (($self->{flv}->get_header->has_video || 0) !=
          ($flv->get_header->has_video || 0))
      {
         die 'One FLV has video and the other does not';
      }
      if (($self->{flv}->get_header->has_audio || 0) !=
          ($flv->get_header->has_audio || 0))
      {
         die 'One FLV has audio and the other does not';
      }
      for my $tag ($flv->get_body->get_tags)
      {
         $tag->{start} += $self->{start};
         push @{$self->{flv}->get_body->{tags}}, $tag;
      }
   }
   else
   {
      # add 1st
      $self->{flv} = $flv;
   }

   # validate and count
   for my $tag ($flv->get_body->get_tags)
   {
      if ($tag->isa('FLV::VideoTag'))
      {
         if (!$self->{nvideo}++)
         {
            $self->{video_codec} = $tag->{codec};
         }
         elsif ($tag->{codec} != $self->{video_codec})
         {
            die 'FLV has inconsistent video codecs';
         }
         $self->{last_vid_time} = $tag->{start};
      }
      elsif ($tag->isa('FLV::AudioTag'))
      {
         if (!$self->{naudio}++)
         {
            $self->{audio_codec} = $tag->{format};
         }
         elsif ($tag->{format} != $self->{audio_codec})
         {
            die 'FLV has inconsistent audio codecs';
         }
         $self->{last_aud_time} = $tag->{start};
      }
   }

   $self->{one_frame}
       ||= 1 < $self->{nvideo} ? $self->{last_vid_time} / ($self->{nvideo} - 1)
       :   1 < $self->{naudio} ? $self->{last_aud_time} / ($self->{naudio} - 1)
       : die 'FLV has no media';

   $self->{start}
       = ($self->{nvideo} ? $self->{last_vid_time} : $self->{last_aud_time})
           + $self->{one_frame};

   return;
}

=item $self->save($outfile)

Serialize the combined FLV to file.

=cut

sub save
{
   my $self    = shift;
   my $outfile = shift;

   my $outfh = FLV::Util->get_write_filehandle($outfile);
   if (!$outfh)
   {
      die 'Failed to write FLV file: ' . $OS_ERROR;
   }

   $self->{flv}->populate_meta();
   $self->{flv}->serialize($outfh);

   return;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
