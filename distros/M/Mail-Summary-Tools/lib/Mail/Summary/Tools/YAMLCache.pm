#!/usr/bin/perl

package Mail::Summary::Tools::YAMLCache;
use Moose;

use YAML::Syck ();

has data => (
	isa => "HashRef",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->_load_data || {} },
);

has file => (
	isa => "Path::Class::File",
	is  => "ro",
	required => 1,
);

sub get {
	my ( $self, $long_key ) = @_;
	my ( $container, $key ) = $self->_find_container( $long_key );
	$container->{$key};
}

sub set {
	my ( $self, $long_key, $value ) = @_;
	my ( $container, $key ) = $self->_find_container( $long_key );	

	$container->{$key} = $value;
}

sub delete {
	my ( $self, $long_key ) = @_;
	my ( $container, $key ) = $self->_find_container( $long_key );
	delete $container->{$key};
}

sub _find_container {
	my ( $self, $long_key ) = @_;	
	my @key = split ':', $long_key;
	my $key = pop @key;

	$key = pop(@key) . ":$key" if $key[-1] =~ /^(?:https?|ftp)$/;

	my $container = $self->data;

	foreach my $subkey ( @key ) {
		$container = $container->{$subkey} ||= {};
	}

	return ($container, $key);
}

sub _load_data {
	my $self = shift;
	local $@;
	eval { YAML::Syck::LoadFile( $self->file->stringify ) };
}

sub _save_data {
	my ( $self, $data ) = @_;
	YAML::Syck::DumpFile( $self->file->stringify, $data );
}

sub DEMOLISH {
	my $self = shift;
	$self->_save_data($self->data);	
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::YAMLCache - A low performance cache which is easy to
edit/fix.

=head1 SYNOPSIS

	use Mail::Summary::Tools::YAMLCache;

	my $cache = Mail::Summary::Tools::YAMLCache->new(
		file => Path::Class::file("/tmp/foo"),
	);

	$cache->get("foo:bar");

	$cache->set("foo:bar", "moose");

=head1 DESCRIPTION

This is a hacky implementation of the L<Cache> API, suitable for caching long
lived values, like shortened links, and links to google group threads (which
require L<WWW::Mechanize> under normal circumstances).

The main point of this module is to create a file that is easy to
edit/alter/delete, not to be performant or multiprocess friendly.

=cut


