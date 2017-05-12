package FLV::Header;

use warnings;
use strict;
use 5.008;
use Carp;

use base 'FLV::Base';

our $VERSION = '0.24';

=for stopwords FLVTool2

=head1 NAME

FLV::Header - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item FLV::Header->new()

Create a new instance.

=item FLV::Header->create_from_body($body)

Given an FLV::Body instance, construct a new header.

=cut

sub create_from_body
{
   my $pkg  = shift;
   my $body = shift || croak 'no body specified';

   my $header = $pkg->new;

   for my $tag ($body->get_tags)
   {
      if ($tag->isa('FLV::VideoTag'))
      {
         $header->{has_video} = 1;
      }
      elsif ($tag->isa('FLV::AudioTag'))
      {
         $header->{has_audio} = 1;
      }
   }

   return $header;
}


=item $self->parse($fileinst)

Takes a FLV::File instance and extracts the FLV header from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.  The interpretation is a bit stricter than
other FLV parsers (for example FLVTool2).

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;

   my $content = $file->get_bytes(9);
   my ($signature, $version, $flags, $offset) = unpack 'A3CCN', $content;

   if ($signature ne 'FLV')
   {
      die 'Not an FLV file at byte ' . $file->get_pos(-9);
   }

   if ($version != 1)
   {
      die 'Internal error: I only understand FLV version 1';
   }

   #if (0 != ($flags & 0xfa))
   if (0 != ($flags & 0xf0))
   {
      die 'Reserved header flags are non-zero at byte ' . $file->get_pos(-5);
   }

   if ($offset < 9)
   {
      die 'Illegal value for body offset at byte ' . $file->get_pos(-4);
   }

   $self->{has_audio} = $flags & 0x04 ? 1 : undef;
   $self->{has_video} = $flags & 0x01 ? 1 : undef;

   # Seek ahead in file
   if ($offset > 9)
   {
      $file->get_bytes($offset - 9);
   }

   return;
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::Header->new;
   for my $key (qw( has_audio has_video )) {
      $copy->{$key} = $self->{$key};
   }
   return $copy;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV header.  If that representation is not
complete, this throws an exception via croak().  Returns the number of
bytes written.

=cut

sub serialize
{
   my $self = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';

   my $flags
       = ($self->{has_audio} ? 0x04 : 0) | ($self->{has_video} ? 0x01 : 0);
   my $header = pack 'A3CCN', 'FLV', 1, $flags, 9;
   my $result = print {$filehandle} $header;
   return $result ? length $header : 0;
}

=item $self->has_video()

Returns a boolean indicating if the FLV header predicts that video
data is enclosed in the stream.

This value is not consulted internally.

=cut

sub has_video
{
   my $self = shift;
   return $self->{has_video};
}

=item $self->has_audio()

Returns a boolean indicating if the FLV header predicts that audio
data is enclosed in the stream.

This value is not consulted internally.

=cut

sub has_audio
{
   my $self = shift;
   return $self->{has_audio};
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
