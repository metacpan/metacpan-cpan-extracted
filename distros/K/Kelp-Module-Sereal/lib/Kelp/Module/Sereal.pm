package Kelp::Module::Sereal;
$Kelp::Module::Sereal::VERSION = '2.10';
use Kelp::Base qw(Kelp::Module::Encoder);
use Sereal qw(get_sereal_encoder get_sereal_decoder);

sub encoder_name { 'sereal' }

sub build_encoder
{
	my ($self, $args) = @_;

	my $encoder_opts = $args->{encoder} // {};
	my $decoder_opts = $args->{decoder} // {};

	return Kelp::Module::Sereal::Facade->new(
		encoder => get_sereal_encoder($encoder_opts),
		decoder => get_sereal_decoder($decoder_opts),
	);
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);

	$self->register(sereal => $self->get_encoder);
}

package Kelp::Module::Sereal::Facade {
	use Kelp::Base;

	attr -encoder;
	attr -decoder;

	sub encode
	{
		my $self = shift;
		$self->encoder->encode(@_);
	}

	sub decode
	{
		my $self = shift;
		$self->decoder->decode(@_);
	}
}
$Kelp::Module::Sereal::Facade::VERSION = '2.10';

1;
__END__

=head1 NAME

Kelp::Module::Sereal - Sereal encoder / decoder for Kelp

=head1 SYNOPSIS

	# in config
	modules => [qw(Sereal)],
	modules_init => {
		Sereal => {
			encoder => {
				# encoder options
			},
			decoder => {
				# decoder options
			},
		},
	},

	# in your application
	my $encoded = $self->sereal->encode({
		type => 'structure',
		name => [qw(testing sereal)],
	});

	# Kelp 2.10 encoder factory
	my $new_sereal = $self->get_encoder(sereal => 'name');


=head1 DESCRIPTION

This is a very straightforward module that integrates the L<Kelp> framework
with the L<Sereal> serialization protocol. See L<Sereal::Encoder> and
L<Sereal::Decoder> for a full reference on the encoder and the decoder.

This module is compatible with Kelp 2.10 encoders feature, so you can use it as
a factory for Sereal encoders by calling C<get_encoder> on the Kelp app object.
It registers itself under the name B<sereal>.

=head1 METHODS INTRODUCED TO KELP

=head2 sereal

	my $sereal_module = $kelp->sereal;

Returns the instance of an encoder facade. You can use this instance to invoke
the methods listed below.

=head1 METHODS

=head2 encode

	my $encoded = $kelp->sereal->encode($data);

A shortcut to C<< $kelp->sereal->encoder->encode >>

=head2 encoder

	my $encoder_instance = $kelp->sereal->encoder;

Returns the instance of L<Sereal::Encoder>

=head2 decode

	my $decoded = $kelp->sereal->decode($sereal_string);

A shortcut to C<< $kelp->sereal->decoder->decode >>

=head2 decoder

	my $decoder_instance = $kelp->sereal->decoder;

Returns the instance of L<Sereal::Decoder>

=head1 CONFIGURATION

=head2 encoder

A hashref with all the arguments to L<Sereal::Encoder/new>.

=head2 decoder

A hashref with all the arguments to L<Sereal::Decoder/new>.

=head1 SEE ALSO

=over

=item * L<Kelp>, the framework

=item * L<Sereal>, the wrapper for the encoder / decoder

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 - 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

