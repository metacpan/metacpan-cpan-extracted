package FLV::MetaTag;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::AMFReader;
use FLV::AMFWriter;
use FLV::Util;
use FLV::Tag;

our $VERSION = '0.24';

=for stopwords FLVTool2 AMF

=head1 NAME

FLV::MetaTag - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 DESCRIPTION

As best I can tell, FLV meta tags are a pair of AMF data: one is the
event name and one is the payload.  I learned that from looking at
sample FLV files and reading the FLVTool2 code.

I've seen no specification for the meta tag, so this is all empirical
for me, unlike the other tags.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV meta tag from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

The majority of the work is done by FLV::AMFReader.

=cut

sub parse
{
   my $self     = shift;
   my $file     = shift;
   my $datasize = shift;

   $self->{data} = [ $self->_deserialize($file->get_bytes($datasize)) ];
   return;
}

sub _deserialize
{
   my $self    = shift;
   my $content = shift;

   return FLV::AMFReader->new($content)->read_flv_meta();
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::MetaTag->new;
   FLV::Tag->copy_tag($self, $copy);
   $copy->{data} = [ $self->_deserialize($self->serialize) ];
   return $copy;
}

=item $self->serialize()

Returns a byte string representation of the tag data.  Throws an
exception via croak() on error.

=cut

sub serialize
{
   my $self = shift;

   my $content = FLV::AMFWriter->new()->write_flv_meta(@{ $self->{data} });
   return $content;
}

=item $self->get_info()

Returns a hash of FLV metadata.  See FLV::Info for more details.

=cut

sub get_info
{
   my ($pkg, @tags) = @_;

   my @records;
   my %keys;
   for my $tag (@tags)
   {
      my $data = $tag->{data}->[1];
      if ($data)
      {
         my %fields;
         for my $key (keys %{$data})
         {
            my $value = $data->{$key};
            if (!defined $value)
            {
               $value = q{};
            }
            $value =~ s/ \A \s+    //xms;
            $value =~ s/    \s+ \z //xms;
            $fields{$key} = $value;
            $keys{$key}   = undef;
         }
         push @records, \%fields;
      }
   }
   my %info = $pkg->_get_info('meta', \%keys, \@records);
   return %info;
}

=item $self->get_values();

=item $self->get_value($key);

=item $self->set_value($key, $value);

These are convenience functions for interacting with an C<onMetadata>
hash.

C<get_values()> returns a hash of all metadata key-value pairs.
C<get_value($key)> returns a single value.  C<set_value()> has no return
value.

=cut

sub get_values
{
   my $self = shift;

   return if (!$self->{data});
   return if (@{ $self->{data} } < 2);
   return if ($self->{data}->[0] ne 'onMetaData');
   return %{ $self->{data}->[1] };
}

sub get_value
{
   my $self = shift;
   my $key  = shift;

   return if (!$self->{data});
   return if (@{ $self->{data} } < 2);
   return if ($self->{data}->[0] ne 'onMetaData');
   return $self->{data}->[1]->{$key};
}

sub set_value
{
   my ($self, @keyvalues) = @_;

   $self->{data} ||= [];
   if (@{ $self->{data} } < 2 || $self->{data}->[0] ne 'onMetaData')
   {
      unshift @{ $self->{data} }, 'onMetaData', {};
   }

   while (@keyvalues)
   {
      my ($key, $value) = splice @keyvalues, 0, 2;

      if (defined $value)
      {
         $self->{data}->[1]->{$key} = $value;
      }
      else
      {
         delete $self->{data}->[1]->{$key};
      }
   }

   return;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
