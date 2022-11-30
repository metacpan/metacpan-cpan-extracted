use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::ZMUGHAL::Basic;
# ABSTRACT: A plugin bundle that sets up a basic set of plugins for ZMUGHAL
$Dist::Zilla::PluginBundle::Author::ZMUGHAL::Basic::VERSION = '0.006';
use Moose;

use Dist::Zilla::Plugin::MetaJSON ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::AutoPrereqs ();
use Dist::Zilla::Plugin::PkgVersion ();
use Dist::Zilla::Plugin::CheckChangeLog ();
use Dist::Zilla::Plugin::GithubMeta ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::ReadmeAnyFromPod ();
use Dist::Zilla::Plugin::Git::CommitBuild ();
use Dist::Zilla::Plugin::Git ();

with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Basic',
		'-remove' => [ 'ExtraTests' ],
	});

	$self->add_plugins(
		qw(
			MetaJSON
			AutoPrereqs
			PkgVersion
			CheckChangeLog
			GithubMeta
			PodWeaver
			MinimumPerl
		)
	);

	$self->add_plugins(
		['MetaNoIndex' => {
			directory => [ qw(t xt inc share eg examples) ],
		}],
	);

	$self->add_plugins(
		['ReadmeAnyFromPod' => [
			#; generate README.pod in root (so that it can be displayed on GitHub)
			type => 'pod',
			filename => 'README.pod',
			location => 'root',
		]],

		['Git::CommitBuild' => [
			#; no build commits
			branch => '',
			#; release commits
			release_branch  => 'build/%b',
			release_message => 'Release build of v%v (on %b)',
		]],
	);

	$self->add_bundle(
		'Git' => {
			allow_dirty => [
					'dist.ini',
					'README'
				],
			push_to => [
					'origin',
					'origin build/master:build/master'
				] ,
		}
	);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ZMUGHAL::Basic - A plugin bundle that sets up a basic set of plugins for ZMUGHAL

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
