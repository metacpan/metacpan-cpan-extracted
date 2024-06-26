package Kelp::Module::YAML;
$Kelp::Module::YAML::VERSION = '2.00';
use Kelp::Base qw(Kelp::Module::Encoder);
use YAML::PP;

our $content_type = 'text/yaml';
our $content_type_re = qr{^text/yaml}i;

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

	require Kelp::Module::YAML::KelpExtensions
		if delete $args{kelp_extensions};

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
$Kelp::Module::YAML::Facade::VERSION = '2.00';

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

A single special flag exists, C<kelp_extensions> - if passed and true, YAML
extensions for Kelp modules will be installed, adding some new methods to base
Kelp packages:

=over

=item * Kelp::Request

Adds C<is_yaml>, C<yaml_param> and C<yaml_content> methods, all working like
json counterparts.

=item * Kelp::Response

Adds C<yaml> method and an ability for C<render> to turn a reference into YAML
with proper content type.

=item * Kelp::Test

Adds C<yaml_cmp> and C<yaml_content> methods, working like their json counterparts.

=back

The rest of the configuration is fed to L<YAML::PP/new>.

YAML content type for the extensions is deduced based on content of
C<$Kelp::Module::YAML::content_type> and
C<$Kelp::Module::YAML::content_type_re> variables and is C<text/yaml> by
default.

=head1 CAVEATS

While C<encode> and C<decode> methods in the facade will handle call context
and multiple YAML documents just fine, the installed extensions to Kelp
components will work in a scalar (single-document) mode. To avoid mistakes,
C<yaml_content> in request will return C<undef> if there is more than one
document in the request, since in scalar context YAML::PP will return just the
first one, ignoring the rest of the data.

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

