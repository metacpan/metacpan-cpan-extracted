#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Context;
use Moose;

use File::Save::Home ();
use Path::Class;

has homedir => (
	isa => "Path::Class::Dir",
	is  => "rw",
	lazy => 1,
	default => sub { Path::Class::dir($_[0]->find_homedir) },
);

has cache => (
	isa => "Object",
	is  => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->create_yamlcache($self->cache_storage);
	},
);

has cache_storage => (
	isa => "Path::Class::File",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->homedir->file("cache") },
);

has nntp_overviews => (
	isa => "Object",
	is  => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		warn "loading " . $self->nntp_overview_storage;
		$self->create_yamlcache($self->nntp_overview_storage);
	},
);

has nntp_overview_storage=> (
	isa => "Path::Class::File",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->homedir->file("nntp_overviews") },
);

sub find_homedir {
	my $self = shift;

	return File::Save::Home::make_subhome_directory(
		File::Save::Home::get_subhome_directory_status(".mailsum"),
	);
}

sub create_yamlcache {
	my ( $self, $path ) = @_;

	require Mail::Summary::Tools::YAMLCache;
	return Mail::Summary::Tools::YAMLCache->new( file => $path );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Context - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::CLI::Context;

=head1 DESCRIPTION

=cut


