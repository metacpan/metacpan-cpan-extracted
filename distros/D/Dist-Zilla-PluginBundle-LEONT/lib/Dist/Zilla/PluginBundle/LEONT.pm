package Dist::Zilla::PluginBundle::LEONT;
$Dist::Zilla::PluginBundle::LEONT::VERSION = '0.014';
use strict;
use warnings;

use Moose;
with qw/Dist::Zilla::Role::PluginBundle::Easy Dist::Zilla::Role::PluginBundle::PluginRemover Dist::Zilla::Role::PluginBundle::Config::Slicer/;

has install_tool => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		$self->payload->{install_tool};
	},
);

has fast => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
		my $self = shift;
		$self->payload->{fast};
	},
);

my @plugins_early = (qw/
GatherDir
PruneCruft
ManifestSkip
MetaYAML
License
Readme
/,
[ ExecDir => { dir => 'script' } ],
qw/
ShareDir
Manifest

AutoPrereqs
MetaJSON
Repository
Bugtracker
Git::NextVersion
MetaProvides::Package

NextRelease
CheckChangesHasContent
Git::Contributors
/);

# AutoPrereqs should be before installtool (for BuildSelf), InstallGuide should be after it.
# UploadToCPAN should be after @Git

my @plugins_late = (qw/
RunExtraTests
TestRelease
ConfirmRelease
UploadToCPAN

PodWeaver
PkgVersion

PodSyntaxTests
PodCoverageTests/,
[ 'Test::Compile', { xt_mode => -d 't' } ],
);

my @bundles = qw/Git/;

my %tools = (
	eumm          => [ 'MakeMaker' ],
	mb            => [ 'ModuleBuild' ],
	mbc           => [ qw/ModuleBuild::Custom Meta::Dynamic::Config/ ],
	mbt           => [ 'ModuleBuildTiny' ],
	self          => [ 'BuildSelf' ],
	'mbt+mb'      => [ 'ModuleBuildTiny::Fallback' ],
	'mbt+mb+eumm' => [ 'ModuleBuildTiny::Fallback', 'MakeMaker::Fallback' ],
	none => [],
);

sub configure {
	my $self = shift;

	my $tool = $tools{ $self->install_tool };
	confess 'No known tool ' . $self->install_tool if not $tool;
	$self->add_plugins(@plugins_early);
	$self->add_plugins($self->fast ? 'MinimumPerlFast' : 'MinimumPerl');
	$self->add_plugins(@{$tool});
	$self->add_bundle("\@$_") for @bundles;
	$self->add_plugins(@plugins_late);
	$self->add_plugins('InstallGuide') if @{$tool};
	return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

# ABSTRACT: LEONT's dzil bundle

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::LEONT - LEONT's dzil bundle

=head1 VERSION

version 0.014

=head1 DESCRIPTION

This is currently identical to the following setup:

    ; @Basic except for MakeMaker, ExecDir, TestRelease and ExtraTests
    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [Readme]
    [ShareDir]
    [Manifest]
    [ConfirmRelease]
    [UploadToCPAN]

    [ExecDir]
    dir = script

    [RunExtraTests]
    [AutoPrereqs]
    [MetaJSON]
    [Repository]
    [Bugtracker]
    [MinimumPerl] ; [MinimumPerlFast] if fast=true
    [Git::NextVersion]
    
    [NextRelease]
    [CheckChangesHasContent]

    ($install_tool dependent modules)

    [InstallGuide]

    [PodWeaver]
    [PkgVersion]
    
    [PodSyntaxTests]
    [PodCoverageTests]
    [Test::Compile]
    xt_mode = 1 ; unless no other tests
    
    [@Git]
    [Git::Contributors]

=head2 Parameters

=head2 install_tool

This parameter can currently have 5 different values:

=over 4

=item * eumm

Use ExtUtils::MakeMaker

=item * mb

Use Module::Build

=item * mbc

Use Module::Build with the ModuleBuild::Custom plugin

=item * mbt

Use Module::Build::Tiny

=item * self

Use the installing module to bootstrap itself

=item * mbt+mb

Use Module::Build::Tiny with a Module::Build fallback

=item * mbt+mb+eumm

Use Module::Build::Tiny with a Module::Build and a ExtUtils::MakeMaker fallback

=item * none

Don't let this bundle add an install tool, this will need to be set manually. This also disables C<[InstallGuide]>.

=back

=head3 fast

This picks some alternative modules. Currently it replaces MinimumPerl by MinimumPerlFast.

=head3 tracker

This picks which bugtracker to use, options are C<github> and C<rt>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
