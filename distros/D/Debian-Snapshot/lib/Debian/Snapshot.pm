package Debian::Snapshot;
BEGIN {
  $Debian::Snapshot::VERSION = '0.003';
}
# ABSTRACT: interface to snapshot.debian.org

use Any::Moose;

use Debian::Snapshot::Package;
use JSON ();
use LWP::UserAgent;

has 'user_agent' => (
	is      => 'rw',
	isa     => 'LWP::UserAgent',
	lazy    => 1,
	builder => '_build_user_agent',
);

has 'url' => (
	is      => 'rw',
	isa     => 'Str',
	default => 'http://snapshot.debian.org',
);

sub _build_user_agent {
	my $ua = LWP::UserAgent->new;
	$ua->agent("Debian-Snapshot/$Debian::Snapshot::VERSION ");
	$ua->env_proxy;
	return $ua;
}

sub _get {
	my $self = shift;
	my $url  = shift;
	$url = $self->url . $url;

	my $response = $self->user_agent->get($url, @_);

	die $response->status_line unless $response->is_success;
	return $response->decoded_content;
}

sub _get_json {
	my $self = shift;
	my $json = $self->_get(@_);
	return JSON::decode_json($json);
}

sub binaries {
	my ($self, $name, $version) = @_;

	my $json = $self->_get_json("/mr/binary/$name/");

	my @binaries = map $self->package($_->{source}, $_->{version})
	                        ->binary($_->{name}, $_->{binary_version}),
	                   @{ $json->{result} };

	if (defined $version) {
		$version = qr/^\Q$version\E$/ unless ref($version) eq 'Regexp';
		@binaries = grep $_->binary_version =~ $version, @binaries;
	}

	return \@binaries;
}

sub file {
	my ($self, $hash) = @_;
	Debian::Snapshot::File->new(
		hash     => $hash,
		_service => $self,
	);
}

sub package {
	my ($self, $package, $version) = @_;
	return Debian::Snapshot::Package->new(
		_service => $self,
		package => $package,
		version => $version,
	);
}

sub packages {
	my ($self) = @_;

	my $json = $self->_get_json("/mr/package/");
	my @package = map $_->{package}, @{ $json->{result} };

	return \@package;
}

sub package_versions {
	my ($self, $package) = @_;

	my $json = $self->_get_json("/mr/package/$package/");
	my @versions = map $_->{version}, @{ $json->{result} };
	return \@versions;
}

no Any::Moose;
1;



=pod

=head1 NAME

Debian::Snapshot - interface to snapshot.debian.org

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Debian::Snapshot;
  my $s = Debian::Snapshot->new;

  my $p = $s->package("package", "version"); # see Debian::Snapshot::Package
  my @package_names   = @{ $s->packages };
  my @source_versions = @{ $s->package_versions("source-package") };

  my @bs = @{ $s->binaries("binary") };      # see Debian::Snapshot::Binary

  my $f = $s->file($sha1hash);               # see Debian::Snapshot::File

=head1 DESCRIPTION

This module provides an interface to the snapshot.debian.org service.

=head1 ATTRIBUTES

=head2 url

URL used to contact the snapshot service.
Defaults to C<http://snapshot.debian.org>.

=head2 user_agent

The L<LWP::UserAgent|LWP::UserAgent> object used to query the server.

=head1 METHODS

=head2 binaries($name, $version?)

Returns an arrayref of L<Debian::Snapshot::Binary|Debian::Snapshot::Binary>
objects for the binary package named C<$name>.

If the optional parameter C<$version> is present, only return binaries whose
binary version matches C<$version> which might be either a string or a regular
expression.

=head2 file($hash)

Returns a L<Debian::Snapshot::File|Debian::Snapshot::File> object for the file
with the given C<$hash>.

=head2 package($package, $version)

Returns a L<Debian::Snapshot::Package|Debian::Snapshot::Package> object for the
source package C<$package> version C<$version>.

=head2 packages

Returns an arrayref of source package names.

=head2 package_versions($package)

Returns an arrayref of versions for source package C<$package>.

=head1 SEE ALSO

L<http://snapshot.debian.org/>

=head1 AUTHOR

  Ansgar Burchardt <ansgar@43-1.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ansgar Burchardt <ansgar@43-1.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

