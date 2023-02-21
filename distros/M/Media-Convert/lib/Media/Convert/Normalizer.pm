package Media::Convert::Normalizer;

use Moose;

=head1 NAME

Media::Convert::Normalizer - normalize the audio of an asset.

=head1 SYNOPSIS

  Media::Convert::Normalizer->new(input => Media::Convert::Asset->new(...), output => Media::Convert::Asset->new(...))->run();

=head1 DESCRIPTION

C<Media::Convert::Normalizer> is a class to normalize the audio of a
given Media::Convert::Asset asset, using ffmpeg by default.

=head1 ATTRIBUTES

The following attributes are supported by
Media::Convert::Normalizer.

=head2 input

An L<Media::Convert::Asset> object for which the audio should be normalized.

Required.

=cut

has 'input' => (
	is => 'rw',
	isa => 'Media::Convert::Asset',
	required => 1,
);

=head2 output

An L<Media::Convert::Asset> object that the normalized audio will be
written to, together with the copied video from the input file (if any).

Required. Must point to a .mkv file.

=cut

has 'output' => (
	is => 'rw',
	isa => 'Media::Convert::Asset',
	required => 1,
);

=head2 impl

The normalizer implementation to use. Defaults to "ffmpeg". Valid
options: any subclass of this module, assumes it is in the
C<Media::Convert::Normalizer::> namespace.

=cut

has 'impl' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => 'ffmpeg',
);

=head1 METHODS

=head2 run

Performs the normalization.

=cut

sub run {
	my $self = shift;
	my $pkg = "Media::Convert::Normalizer::" . ucfirst($self->impl);
	eval "require $pkg;"; ## no critic(StringyEval)
	if($@) {
		die "$@: $!";
	}
	return $pkg->new(input => $self->input, output => $self->output)->run();
}

1;
