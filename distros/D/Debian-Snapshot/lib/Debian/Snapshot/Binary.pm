package Debian::Snapshot::Binary;
BEGIN {
  $Debian::Snapshot::Binary::VERSION = '0.003';
}
# ABSTRACT: information on a binary package

use Any::Moose;

use Debian::Snapshot::File;
use File::Spec;

has 'binary_version' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'name' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'package' => (
	is       => 'ro',
	isa      => 'Debian::Snapshot::Package',
	required => 1,
	handles  => [qw( _service )],
);

has 'binfiles' => (
	is       => 'ro',
	isa      => 'ArrayRef[HashRef]',
	lazy     => 1,
	builder  => '_binfiles_builder',
);

sub _binfiles_builder {
	my $self = shift;

	my $package    = $self->package->package;
	my $version    = $self->package->version;
	my $binpkg     = $self->name;
	my $binversion = $self->binary_version;

	my $json = $self->_service->_get_json(
		"/mr/package/$package/$version/binfiles/$binpkg/$binversion?fileinfo=1"
	);

	my @files = @{ $json->{result} };
	for (@files) {
		$_->{file} = Debian::Snapshot::File->new(
			hash => $_->{hash},
			_fileinfo => $json->{fileinfo}->{ $_->{hash} },
			_service  => $self->_service,
		);
	}

	return \@files;
}

sub _as_string {
	my $self = shift;
	return $self->name . "_" . $self->binary_version;
}

sub download {
	my ($self, %p) = @_;

	unless (exists $p{directory} || exists $p{filename}) {
		die "Either 'directory' or 'file' parameter is required.";
	}

	my $architecture = ref($p{architecture}) eq 'Regexp' ? $p{architecture}
	                 : qr/^\Q$p{architecture}\E$/;

	my @binfiles = grep $_->{architecture} =~ $architecture, @{ $self->binfiles };
	@binfiles = grep $_->{file}->archive($p{archive_name}), @binfiles if exists $p{archive_name};

	die "Found no file for " . $self->_as_string unless @binfiles;
	die "Found more than one file for " . $self->_as_string if @binfiles > 1;

	return $binfiles[0]->{file}->download(
		exists $p{archive_name} ? (archive_name => $p{archive_name}) : (),
		defined $p{directory} ? (directory => $p{directory}) : (),
		defined $p{filename} ? (filename => $p{filename}) : (),
		exists $p{overwrite} ? (overwrite => $p{overwrite}) : (),
	);
}

no Any::Moose;
1;



=pod

=head1 NAME

Debian::Snapshot::Binary - information on a binary package

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 binary_version

Version of the binary package.

=head2 name

Name of the binary package.

=head2 package

A L<Debian::Snapshot::Package|Debian::Snapshot::Package> object for the
associated source package.

=head2 binfiles

An arrayref of hashrefs with the following keys:

=over

=item architecture

Name of the architecture this package is for.  Can be a string or a regular
expression.

=item hash

Hash of this file.

=item file

A L<Debian::Snapshot::File|Debian::Snapshot::File> object for this file.

=back

=head1 METHODS

=head2 download(%params)

=over

=item architecture

(Required.) Name of the architecture to retrieve the .deb file for.

=item archive_name

(Optional.) Name of the archive to retrieve the package from.

=item directory

=item filename

=item overwrite

Passed to L<< Debian::Snapshot::File->download|Debian::Snapshot::File/"download(%params)" >>.

=back

=head1 SEE ALSO

L<Debian::Snapshot>

=head1 AUTHOR

  Ansgar Burchardt <ansgar@43-1.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ansgar Burchardt <ansgar@43-1.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

