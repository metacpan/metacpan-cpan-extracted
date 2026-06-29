package Dist::Zilla::Plugin::CycloneDX;
$Dist::Zilla::Plugin::CycloneDX::VERSION = '0.001';
use 5.020;

use Moose;
with qw/Dist::Zilla::Role::FileGatherer/;
use MooseX::Types::Moose 'Str';
use namespace::autoclean;
use experimental qw/signatures postderef lexical_subs/;
no autovivification;

use Carp;
use Dist::Zilla::File::InMemory;
use Time::Piece;
use URI::PackageURL;

use SBOM::CycloneDX 1.08;
use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::ExternalReference;
use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Metadata;
use SBOM::CycloneDX::Metadata::Lifecycle;
use SBOM::CycloneDX::OrganizationalContact;
use SBOM::CycloneDX::Tools;
use SBOM::CycloneDX::Util qw/cpan_meta_to_spdx_license cyclonedx_component/;

has filename => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	default => sub($self) {
		my $name    = $self->zilla->name;
		my $version = $self->zilla->version;
		return "CPAN-META/$name-$version.cdx.json";
	}
);

my %simple_resource = (
	homepage       => 'website',
	x_mailing_list => 'mailing-list',
	x_MailingList  => 'mailing-list',
	x_mailinglist  => 'mailing-list',
	x_mastodon     => 'social',
	x_twitter      => 'social',
	x_wiki         => 'documentation',
);

my sub make_externs($module, $resources) {
	my @externs = SBOM::CycloneDX::ExternalReference->new(type => 'documentation', url => "https://metacpan.org/pod/$module");
	if (my $tracker = $resources->{bugtracker}{web}) {
		push @externs, SBOM::CycloneDX::ExternalReference->new(type => 'issue-tracker', url => $tracker);
	}
	if (my $repo = $resources->{repository}{web}) {
		push @externs, SBOM::CycloneDX::ExternalReference->new(type => 'vcs', url => $repo);
	}
	if (my $irc = $resources->{x_IRC}) {
		my $url = ref $irc ? $irc->{url} : $irc;
		push @externs, SBOM::CycloneDX::ExternalReference->new(type => 'chat', url => $url);
	}
	for my $key (keys %simple_resource) {
		if (my $url = $resources->{$key}) {
			push @externs, SBOM::CycloneDX::ExternalReference->new(type => $simple_resource{$key}, url => $url);
		}
	}
	return sort { $a->type cmp $b->type } @externs;
}

sub make_purl($name, $version) {
	return URI::PackageURL->new(
		type      => 'cpan',
		namespace => '',
		name      => $name,
		version   => $version,
	);
}

my sub make_root_component($meta) {
	my $purl    = make_purl($meta->{name}, $meta->{version});
	my $bom_ref = sprintf '%s@%s', $meta->{name}, $meta->{version};
	my $module  = $meta->{name} =~ s/-/::/gr;
	my @externs = make_externs($module, $meta->{resources});

	return SBOM::CycloneDX::Component->new(
		type                => 'library',
		group               => 'CPAN',
		name                => $meta->{name},
		version             => $meta->{version},
		description         => $meta->{abstract},
		bom_ref             => $bom_ref,
		purl                => $purl,
		external_references => \@externs,
	);
}

my sub to_organization($author) {
	my ($name, $email) = $author =~ /([^<]+?)\s+<([^>]+)>/ or croak "Could not parse author '$author'";
	return SBOM::CycloneDX::OrganizationalContact->new(name => $name, email => $email);
}

my sub make_licenses($meta) {
	if (my $spdx_expr = $meta->{x_spdx_expression}) {
		return SBOM::CycloneDX::License->new($spdx_expr);
	} else {
		my @raw = map { cpan_meta_to_spdx_license($_) } $meta->{license}->@*;
		return map { SBOM::CycloneDX::License->new($_) } @raw;
	}
}

my %self_resources = (
	bugtracker => {
		web    => 'https://github.com/Leont/dist-zilla-plugin-cyclonedx/issues',
	},
	repository => {
		web    => 'https://github.com/Leont/dist-zilla-plugin-cyclonedx',
	},
	x_IRC      => 'irc://irc.perl.org/#distzilla',
);

my sub make_tool_component($module, $dist, $resources = {}) {
	my @externs = make_externs($module, $resources);
	my $version = $module->VERSION;
	my %args = (
		type                => 'library',
		group               => 'CPAN',
		name                => $dist,
		external_references => \@externs,
	);
	if ($version) {
		$args{version} = $version;
		$args{purl}    = make_purl($dist, $version);
	}
	return SBOM::CycloneDX::Component->new(%args);
}

my sub make_tools($plugins) {
	my $distname = __PACKAGE__ =~ s/::/-/gr;
	my @tools = make_tool_component(__PACKAGE__, $distname, \%self_resources);
	push @tools, map { make_tool_component(ref($_), $_->cyclonedx_dist, $_->cyclonedx_resources) } $plugins->@*;
	push @tools, cyclonedx_component;

	return SBOM::CycloneDX::Tools->new(components => \@tools);
}

my sub make_metadata($meta, $plugins) {
	my $component = make_root_component($meta);
	my @authors   = map { to_organization($_) } $meta->{author}->@*;
	my $timestamp = SBOM::CycloneDX::Timestamp->new($ENV{TIMESTAMP} // scalar gmtime);
	my @licenses  = make_licenses($meta);
	my @lifecycle = SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'pre-build');
	my $tools     = make_tools($plugins);

	return SBOM::CycloneDX::Metadata->new(
		component  => $component,
		authors    => \@authors,
		timestamp  => $timestamp,
		licenses   => \@licenses,
		lifecycles => \@lifecycle,
		tools      => $tools,
	);
}

sub gather_files($self) {
	my @plugins  = $self->zilla->plugins_with(-CycloneDXSource)->@*;
	my $metadata = make_metadata($self->zilla->distmeta, \@plugins);
	my $bom      = SBOM::CycloneDX->new(metadata => $metadata);

	for my $plugin (@plugins) {
		$plugin->add_to_bom($bom);
	}

	local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /Net::IDN::Encode/ };
	if (my @errors = $bom->validate) {
		croak "Errors found in BOM: @errors";
	}

	$self->add_file(Dist::Zilla::File::InMemory->new(
		name            => $self->filename,
		encoded_content => $bom->to_string,
	));

	return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: CycloneDX files in dzil generated dists

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CycloneDX - CycloneDX files in dzil generated dists

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This module adds a CycloneDX SBOM file to your distribution. By default this will only contain information that's already contained in the META files, but this can be extended by other plugins that implement the L<CycloneDXSource|Dist::Zilla::Role::CycloneDXSource> role.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
