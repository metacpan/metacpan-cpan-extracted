package Dist::Zilla::PluginBundle::Author::JACQUESG;
$Dist::Zilla::PluginBundle::Author::JACQUESG::VERSION = '0.02';
use strict;
use warnings;

use Moose;
use Dist::Zilla;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has 'repo' => (
	is	=> 'ro',
	isa	=> 'Maybe[Str]',
	lazy	=> 1,
	default	=> sub
	{
		$_[0]->payload->{repo};
	}
);

has 'fake_release' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub
	{
		$_[0]->payload->{fake_release} // 0;
	}
);

has 'pod_coverage' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub
	{
		$_[0]->payload->{pod_coverage} // 1;
	}
);

has 'git_push' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub
	{
		$_[0]->payload->{git_push} // 1;
	}
);

has 'github' => (
	is	=> 'ro',
	isa	=> 'Bool',
	lazy	=> 1,
	default	=> sub
	{
		$_[0]->payload->{github} // 1;
	}
);

=head1 NAME

Dist::Zilla::PluginBundle::Author::JACQUESG - Plugin bundle used by JACQUESG

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your dist.ini:

    [@Author::JACQUESG]

=head1 DESCRIPTION

B<Dist::Zilla::PluginBundle::Author::JACQUESG> is the L<Dist::Zilla> plugin
bundle used by JACQUESG.

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


sub configure
{
	my ($self) = @_;

	# @Basic plugins but MakeMaker and UploadToCPAN
	$self->add_plugins
	(
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

	# github bundle
	if ($self->github)
	{
		$self->add_bundle
		(
			'GitHub' =>
			{
				metacpan  => 1,
				repo      => $self -> repo
			}
		);
	}

	# bump version
	$self->add_plugins
	(
		['Git::NextVersion' => { first_version => 0.01 }],
	);

	# core plugins
	$self->add_plugins
	(
		'MetaConfig',
		'MetaJSON',
		'AutoPrereqs',
		'PodVersion',
		'PkgVersion'
	);

	$self->add_plugins ('NextRelease');

	# test plugins
	$self->add_plugins
	(
		'Test::Compile',
		'Test::CheckManifest',
		'PodSyntaxTests'
	);

	if ($self->pod_coverage)
	{
		$self->add_plugins ('PodCoverageTests');
	}

	# release plugins
	if ($self->fake_release)
	{
		$self->add_plugins ('FakeRelease');
	}
	else
	{
		$self->add_plugins ('Git::Commit', ['Git::Tag' => { tag_message => '%N %v' }]);
		$self->add_plugins ('Git::Push') if ($self->git_push);
		$self->add_plugins (['UploadToCPAN' => { pause_cfg_file => $ENV{'ZILLA_PAUSE_CFG'} || '' }]);
	}

	# after release
	$self->add_plugins (['InstallRelease' => { install_command => 'cpanm .' }], 'Clean');
}

=head1 ATTRIBUTES

=over

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

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::PluginBundle::Author::JACQUESG
