package Dist::Zilla::PluginBundle::Author::ALEXBIO;
{
  $Dist::Zilla::PluginBundle::Author::ALEXBIO::VERSION = '2.07';
}

use strict;
use warnings;

use Moose;
use Dist::Zilla;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has 'repo' => (
	is	=> 'ro',
	isa	=> 'Maybe[Str]',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {repo} ?
				$_[0] -> payload -> {repo} : undef
		}
);

has 'makemaker' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {makemaker} ?
				$_[0] -> payload -> {makemaker} : 1
		}
);

has 'fake_release' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {fake_release} ?
				$_[0] -> payload -> {fake_release} : 0
		}
);

has 'pod_coverage' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {pod_coverage} ?
				$_[0] -> payload -> {pod_coverage} : 1
		}
);

has 'git_push' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {git_push} ?
				$_[0] -> payload -> {git_push} : 1
		}
);

has 'github' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub {
			defined $_[0] -> payload -> {github} ?
				$_[0] -> payload -> {github} : 1
		}
);

=head1 NAME

Dist::Zilla::PluginBundle::Author::ALEXBIO - Plugin bundle used by ALEXBIO

=head1 VERSION

version 2.07

=head1 SYNOPSIS

In your dist.ini:

    [@Author::ALEXBIO]

=head1 DESCRIPTION

B<Dist::Zilla::PluginBundle::Author::ALEXBIO> is the L<Dist::Zilla> plugin
bundle used by ALEXBIO.

It is equivalent to the following:

    [@Basic]
    [@GitHub]

    [MetaConfig]
    [MetaJSON]

    [AutoPrereqs]

    [Git::NextVersion]

    [PodVersion]
    [PkgVersion]

    [Test::Compile]
    [Test::CheckManifest]
    [PodSyntaxTests]
    [PodCoverageTests]

    [NextRelease]

    [Git::Commit]

    [Git::Tag]
    tag_message = %N %v

    [Git::Push]

    [InstallRelease]
    install_command = cpanm .

    [Clean]

=cut

sub configure {
	my $self = shift;

	# @Basic plugins but MakeMaker and UploadToCPAN
	$self -> add_plugins(
		'GatherDir',
		'PruneCruft',
		'ManifestSkip',
		'MetaYAML',
		'License',
		'Readme',
		'ExtraTests',
		'ExecDir',
		'ShareDir',
		'Manifest',
		'TestRelease',
		'ConfirmRelease',
	);

	# use MakeMaker if requested
	if ($self -> makemaker) {
		$self -> add_plugins(
			'MakeMaker'
		);
	}

	# github bundle
	if ($self -> github) {
		$self -> add_bundle(
			'GitHub' => {
				metacpan  => 1,
				repo      => $self -> repo
			}
		);
	}

	# bump version
	$self -> add_plugins(
		['Git::NextVersion' => { first_version => 0.01 }],
	);

	# core plugins
	$self -> add_plugins(
		'MetaConfig',
		'MetaJSON',
		'AutoPrereqs',
		'PodVersion',
		'PkgVersion'
	);

	$self -> add_plugins('NextRelease');

	# test plugins
	$self -> add_plugins(
		'Test::Compile',
		'Test::CheckManifest',
		'PodSyntaxTests'
	);

	if ($self -> pod_coverage) {
		$self -> add_plugins(
			'PodCoverageTests'
		);
	}

	# release plugins
	if ($self -> fake_release) {
		$self -> add_plugins('FakeRelease');
	} else {
		$self -> add_plugins(
			'Git::Commit',
			['Git::Tag' => { tag_message => '%N %v' }]
		);

		$self -> add_plugins('Git::Push') if $self -> git_push;

		$self -> add_plugins(['UploadToCPAN' => {
			pause_cfg_file => $ENV{'ZILLA_PAUSE_CFG'} || ''
		}]);
	}

	# after release
	$self -> add_plugins(
		['InstallRelease' => { install_command => 'cpanm .' }],
		'Clean'
	);
}

=head1 ATTRIBUTES

=over

=item C<makemaker>

If set to '1' (default), the C<MakeMaker> plugin is used.

=item C<fake_relase>

If set to '1', the release will be faked using the C<FakeRelease> plugin.

=item C<pod_coverage>

If set to '1' (default), the C<PodCoverageTest> plugin is used.

=item C<github>

If set to '1' (default), the C<GitHub> bundle is used.

=item C<git_push>

If set to '1' (default), the C<Git::Push> plugin is used.

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::PluginBundle::Author::ALEXBIO
