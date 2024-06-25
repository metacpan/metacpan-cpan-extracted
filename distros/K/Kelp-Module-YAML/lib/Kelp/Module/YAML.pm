package Kelp::Module::YAML;
$Kelp::Module::YAML::VERSION = '1.00';
use Kelp::Base qw(Kelp::Module::Encoder);
use YAML::PP;

sub encoder_name { 'yaml' }

sub build_encoder
{
	my ($self, $args) = @_;

	return Kelp::Module::YAML::Facade->new(
		engine => YAML::PP->new(%$args)
	);
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);

	$self->register(yaml => $self->get_encoder);
}

package Kelp::Module::YAML::Facade {
	use Kelp::Base;

	attr -engine;

	sub encode
	{
		my $self = shift;
		$self->engine->dump_string(@_);
	}

	sub decode
	{
		my $self = shift;
		$self->engine->load_string(@_);
	}
}
$Kelp::Module::YAML::Facade::VERSION = '1.00';

1;
__END__

=head1 NAME

Kelp::Module::YAML - YAML encoder / decoder for Kelp

=head1 SYNOPSIS

	# in config
	modules => [qw(YAML)],
	modules_init => {
		YAML => {
			# options for the constructor
		},
	},

	# in your application
	my $encoded = $self->yaml->encode({
		type => 'structure',
		name => [qw(testing yaml)],
	});

	# Kelp 2.10 encoder factory
	my $new_yaml = $self->get_encoder(yaml => 'name');


=head1 DESCRIPTION

This is a very straightforward module that enriches the L<Kelp> framework
with L<YAML> serialization. It uses L<YAML::PP> behind the scenes.

This module is compatible with Kelp 2.10 encoders feature, so you can use it as
a factory for YAML processors by calling C<get_encoder> on the Kelp app object.
It registers itself under the name B<yaml>.

=head1 METHODS INTRODUCED TO KELP

=head2 yaml

	my $yaml_facade = $kelp->yaml;

Returns the instance of an yaml facade. You can use this instance to invoke
the methods listed below.

=head1 METHODS

=head2 encode

	my $encoded = $kelp->yaml->encode($data);

A shortcut to C<< $kelp->yaml->engine->dump_string >>

=head2 decode

	my $decoded = $kelp->yaml->decode($yaml);

A shortcut to C<< $kelp->yaml->engine->load_string >>

=head2 engine

	my $yaml_engine = $kelp->yaml->engine;

Returns the instance of L<YAML::PP>

=head1 CONFIGURATION

The entire configuration is fed to L<YAML::PP/new>.

=head1 SEE ALSO

=over

=item * L<Kelp>, the framework

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

