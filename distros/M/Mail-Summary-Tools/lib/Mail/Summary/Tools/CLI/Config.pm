#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Config;
use Moose;

use File::Save::Home ();
use Path::Class;
use YAML::Syck;

has homedir => (
	isa => "Path::Class::Dir",
	is  => "rw",
	lazy => 1,
	default => sub { Path::Class::dir($_[0]->find_homedir) },
);

has config_file => (
	isa => "Path::Class::File",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->homedir->file("config") },
);

has config => (
	isa => "HashRef",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->_load_config },
);

sub find_homedir {
	my $self = shift;

	return File::Save::Home::make_subhome_directory(
		File::Save::Home::get_subhome_directory_status(".mailsum"),
	);
}

sub defaults {
	my $self = shift;
	$self->config->{defaults} || {};
}

sub option_value {
	my ( $self, $command, $option ) = @_;
	my $defaults = $self->defaults;

	for ( $command, "all" ) {
		if ( exists $defaults->{$_}{$option} ) {
			return $defaults->{$_}{$option};
		}
	}

	return;
}

sub _load_config {
	my $self = shift;

	if ( -e $self->config_file ) {
		YAML::Syck::LoadFile( $self->config_file->stringify );
	} else {
		return {};
	}
}

1;
