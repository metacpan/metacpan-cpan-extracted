package FLV::ToMP3;

use warnings;
use strict;
use 5.008;

use FLV::File;
use FLV::Util;
use FLV::AudioTag;
use English qw(-no_match_vars);
use Carp;

our $VERSION = '0.24';

=for stopwords MP3 transcodes framerate

=head1 NAME

FLV::ToMP3 - Convert audio from a FLV file into an MP3 file

=head1 LICENSE

See L<FLV::Info>

=head1 SYNOPSIS

   use FLV::ToMP3;
   my $converter = FLV::ToMP3->new();
   $converter->parse_flv($flv_filename);
   $converter->save($mp3_filename);

See also L<flv2mp3>.

=head1 DESCRIPTION

Extracts audio data from an FLV file and constructs an MP3 file.  See
the L<flv2mp3> command-line program for a nice interface and a
detailed list of caveats and limitations.

=head1 METHODS

=over

=item $pkg->new()

Instantiate a converter.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless { flv => FLV::File->new() }, $pkg;
   $self->{flv}->empty();
   return $self;
}

=item $self->parse_flv($flv_filename)

Open and parse the specified FLV file.

=cut

sub parse_flv
{
   my $self   = shift;
   my $infile = shift;

   $self->{flv}->parse($infile);
   $self->{flv}->populate_meta();

   $self->_validate();

   return;
}

sub _validate
{
   my $self = shift;

   my $acodec = $self->{flv}->get_meta('audiocodecid');
   if (!defined $acodec)
   {
      die "No audio data found\n";
   }
   if ($acodec != 2)
   {
      die "Audio format $AUDIO_FORMATS{$acodec} not supported; "
          . "only MP3 audio allowed\n";
   }
   return;
}

=item $self->save($mp3_filename)

Write out an MP3 file.  Note: this is usually called only after
C<parse_flv()>.  Throws an exception upon error.

=cut

sub save
{
   my $self    = shift;
   my $outfile = shift;

   $self->_validate();

   my $outfh = FLV::Util->get_write_filehandle($outfile);
   if (!$outfh)
   {
      die 'Failed to write MP3 file: ' . $OS_ERROR;
   }

   for my $tag ($self->{flv}->{body}->get_tags())
   {
      next if (!$tag->isa('FLV::AudioTag'));
      print {$outfh} $tag->{data};
   }
   close $outfh or die 'Failed to finish writing file';
   return;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
