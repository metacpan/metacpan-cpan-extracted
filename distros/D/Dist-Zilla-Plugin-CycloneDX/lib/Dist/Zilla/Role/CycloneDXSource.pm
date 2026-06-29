package Dist::Zilla::Role::CycloneDXSource;
$Dist::Zilla::Role::CycloneDXSource::VERSION = '0.001';
use 5.020;

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use experimental 'signatures';

sub add_to_bom($self, $cyclone) {
	return;
}

sub cyclonedx_dist($self) {
	return ref($self) =~ s/::/-/gr;
}

sub cyclonedx_resources($self) {
	return {};
}

1;

# ABSTRACT: A role for plugins that adds information to the CycloneDX SBOM

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::CycloneDXSource - A role for plugins that adds information to the CycloneDX SBOM

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=head1 METHODS

=head2 add_to_bom

This method, taking a single L<SBOM::CycloneDX|SBOM::CycloneDX> object as argument. This can be manipulated, typically to add information to it.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
