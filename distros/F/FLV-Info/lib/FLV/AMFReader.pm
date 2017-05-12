package FLV::AMFReader;

use warnings;
use strict;
use 5.008;
use English qw(-no_match_vars);

use AMF::Perl::Util::Object;
use AMF::Perl::IO::InputStream;
use base 'AMF::Perl::IO::Deserializer';

our $VERSION = '0.24';

=for stopwords AMF Remoting

=head1 NAME

FLV::AMFReader - Wrapper for the AMF::Perl deserializer

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of AMF::Perl::IO::Deserializer.

That class is optimized for Flash Remoting communications.  We are
instead just interested in the protocol for the data payload of those
messages, since that's all that FLV carries.

So, this class is a hack.  We override the AMF::Perl::IO::Deserializer
constructor so that it doesn't start parsing immediately.  Also, we
pass it a string instead of an instantiated
AMF::Perl::IO::InputStream.

Also, as of this writing AMF::Perl was at v0.15, which lacked support
for hashes.  So, we hack that in.  Hopefully we did it in a
future-friendly way...

=over

=item $pkg->new($content)

Creates a minimal AMF::Perl::IO::Deserializer instance.

=cut

sub new
{
   my $pkg     = shift;
   my $content = shift;

   my $input_stream = AMF::Perl::IO::InputStream->new($content);
   return bless { inputStream => $input_stream }, $pkg;
}

=item $self->read_flv_meta()

Returns an array of anonymous data structures.

Parse AMF data from a block of FLV data.  This method of very lenient.
If there are any parsing errors, that data is just ignored and any
successfully parsed data is returned.

We expect there to be exactly two return values, but this method is
generic and is happy to return anywhere from zero to twenty data.

=cut

sub read_flv_meta
{
   my $self = shift;

   my @data;
   local $EVAL_ERROR = undef;
   ## no critic (RequireCheckingReturnValueOfEval)
   eval {
      for my $iter (1 .. 20)
      {
         my $type = $self->{inputStream}->readByte();
         push @data, $self->readData($type);
      }
   };
   return @data;
}

=item $self->readMixedArray()

Returns a populated hashref.

This is a workaround for versions of AMF::Perl which did not handle
hashes (namely v0.15 and earlier).  This method is only installed if a
method of the same name does not exist in the superclass.

This should be removed when a newer release of AMF::Perl is available.

=item $self->readData($type)

This is a minimal override of readData() in the superclass to add
support for mixed arrays (aka hashes).

As above, it is only installed if AMF::Perl::IO::Deserializer lacks a
readMixedArray() method.

=cut

if (!__PACKAGE__->can('readMixedArray'))
{
   *readMixedArray = sub {
      my ($self) = @_;

      # This length is actually unused!  How odd...
      # Instead, a value with datatype == 9 is the end flag
      my $length = $self->{inputStream}->readLong();

      return $self->readObject();
   };

   *readData = sub {
      my ($self, $type) = @_;

      if (8 == $type)
      {
         return $self->readMixedArray();
      }
      else
      {
         return $self->SUPER::readData($type);
      }
   };
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
