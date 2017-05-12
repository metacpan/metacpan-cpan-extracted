package Dist::Zilla::PluginBundle::Author::GABRIEL;

# ABSTRACT: Dist::Zilla configurantion for GABRIEL's projects
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:GABRIEL';

use Moose;
use Dist::Zilla;

with 'Dist::Zilla::Role::PluginBundle::Easy';


sub configure {
	my $self = shift;
	$self->add_plugins(
		'NameFromDirectory',
		'VersionFromModule',
		[
			AutoMetaResources => {
				'repository.github' => 'user:gabrielmad',
				'bugtracker.github' => 'user:gabrielmad',
				'homepage'          => "http://metacpan.org/release/%{dist}",
			}
		],
		[ GatherDir  => { include_dotfiles => 1     }],
		[ PruneCruft => { except => '^\.travis.yml' }],
		[
			'Git::CommitBuild' => {
				release_branch  => 'build/%b',
				release_message => 'Release build of v%v (on %b)',
			}
		],
		'ReadmeFromPod',
		[ 'ReadmeAnyFromPod', 'ReadmePodInRoot', { type => 'pod', filename => 'README.pod' } ],
		[
			ChangelogFromGit => {
				exclude_message => '(\.pod|commit|Travis|POD|forgot|typo|dist.ini|branch)'
			}
		],
		'Test::Compile',
		'MinimumPerl',
		'AutoPrereqs',
		'PodWeaver',
		'PodCoverageTests',
		'PodSyntaxTests',
		'ManifestSkip',
		'MetaYAML',
		'License',
		'Readme',
		'InstallGuide',
		'ExtraTests',
		'ExecDir',
		'ShareDir',
		'MakeMaker',
		'Manifest',
		'TestRelease',
		'ConfirmRelease',
		'UploadToCPAN',
	);

	return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GABRIEL - Dist::Zilla configurantion for GABRIEL's projects

=for Pod::Coverage configure

=for HTML <a href="https://travis-ci.org/gabrielmad/Dist-Zilla-PluginBundle-Author-GABRIEL"><img src="https://travis-ci.org/gabrielmad/Dist-Zilla-PluginBundle-Author-GABRIEL.svg?branch=build%2Fmaster"></a>

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    ; in dist.ini
    [@Author::GABRIEL]

=head1 DESCRIPTION

The same of:

	[NameFromDirectory]
	[VersionFromModule]

	[AutoMetaResources]
	repository.github = user:gabrielmad
	bugtracker.github = user:gabrielmad
	homepage          = http://metacpan.org/release/%{dist}

	[GatherDir]
	include_dotfiles = 1

	[PruneCruft]
	except = ^\.travis.yml

	[Git::CommitBuild]
	release_branch  = build/%b
	release_message = Release build of v%v (on %b)

	[ReadmeFromPod]
	[ReadmeAnyFromPod / ReadmePodInRoot]
	type = pod
	filename = README.pod

	[ChangelogFromGit]
	exclude_message = (\.pod|commit|Travis|POD|forgot|typo|dist.ini|branch)

	[MinimumPerl]
	[AutoPrereqs]

	[PodWeaver]
	[PodCoverageTests]
	[PodSyntaxTests]

	[ManifestSkip]
	[MetaYAML]
	[License]
	[Readme]
	[InstallGuide]
	[ExtraTests]
	[ExecDir]
	[ShareDir]
	[MakeMaker]
	[Manifest]

	[TestRelease]
	[ConfirmRelease]
	[UploadToCPAN]

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
