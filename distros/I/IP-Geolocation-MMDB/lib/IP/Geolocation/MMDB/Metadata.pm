package IP::Geolocation::MMDB::Metadata;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.010;

sub new {
    my ($class, %attrs) = @_;

    my $self = bless \%attrs, $class;

    return $self;
}

sub binary_format_major_version {
    my ($self) = @_;

    return $self->{binary_format_major_version};
}

sub binary_format_minor_version {
    my ($self) = @_;

    return $self->{binary_format_minor_version};
}

sub build_epoch {
    my ($self) = @_;

    return $self->{build_epoch};
}

sub database_type {
    my ($self) = @_;

    return $self->{database_type};
}

sub languages {
    my ($self) = @_;

    return $self->{languages};
}

sub description {
    my ($self) = @_;

    return $self->{description};
}

sub ip_version {
    my ($self) = @_;

    return $self->{ip_version};
}

sub node_count {
    my ($self) = @_;

    return $self->{node_count};
}

sub record_size {
    my ($self) = @_;

    return $self->{record_size};
}

1;
__END__

=encoding UTF-8

=head1 NAME

IP::Geolocation::MMDB::Metadata - Metadata from a MaxMind DB file

=head1 VERSION

version 1.010

=head1 SYNOPSIS

  use IP::Geolocation::MMDB;
  my $db = IP::Geolocation::MMDB->new(file => 'City.mmdb');
  my $metadata = $db->metadata;

=head1 DESCRIPTION

A class for metadata from a MaxMind DB file.

=head1 SUBROUTINES/METHODS

=head2 new

  my $metadata = IP::Geolocation::MMDB::Metadata->new(
    binary_format_major_version => 2,
    binary_format_minor_version => 0,
    build_epoch   => time,
    database_type => 'City',
    languages     => [qw(en fr pt-BR)],
    description   => {
      en => 'IP to city',
      fr => 'IP vers ville',
    },
    ip_version    => 6,
    node_count    => 3829268,
    record_size   => 28,
  );

Returns a new metadata object.

=head2 binary_format_major_version

  my $major_version = $metadata->binary_format_major_version;

Returns the database format's major version number.

=head2 binary_format_minor_version

  my $minor_version = $metadata->binary_format_minor_version;

Returns the database format's minor version number.

=head2 build_epoch

  my $t = gmtime $metadata->build_epoch;

Returns the database's build timestamp as an epoch number.

=head2 database_type

  my $database_type = $metadata->database_type;

Returns a free-form string indicating the database type.

=head2 languages

  for my $language (@{$metadata->languages}) {
    say $language;
  }

Returns a reference to an array of locale codes indicating what languages this
database has information for.

=head2 description

  my %description_for = %{$metadata->description};
  for my $language (keys %description_for) {
    my $description = $description_for{$language};
    say "$language: $description";
  }

Returns a reference to a hash that maps locale codes to strings that describe
the database content.

=head2 ip_version

  my $ip_version = $metadata->ip_version;

Returns 4 or 6.

=head2 node_count

  my $node_count = $metadata->node_count;

Returns the number of nodes in the database's search tree.

=head2 record_size

  my $record_size = $metadata->record_size;

Returns the record size for nodes in the database's search tree.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

L<IP::Geolocation::MMDB>

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
