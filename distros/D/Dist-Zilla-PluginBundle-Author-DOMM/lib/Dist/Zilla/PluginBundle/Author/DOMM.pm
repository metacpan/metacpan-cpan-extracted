package Dist::Zilla::PluginBundle::Author::DOMM;

# ABSTRACT: Dist::Zilla config suiting my needs

our $VERSION = '0.912'; # VERSION

use Moose;
use namespace::autoclean;
with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::PluginRemover
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

use Dist::Zilla::Plugin::Git::GatherDir;
use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::ManifestSkip;
use Dist::Zilla::Plugin::License;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::ModuleBuild;
use Dist::Zilla::Plugin::Manifest;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::CPANFile;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::ShareDir;
use Dist::Zilla::Plugin::ExtraTests;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::OurPkgVersion;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::TestRelease;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::GithubMeta;
use Dist::Zilla::Plugin::SourceHutMeta;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::ConfirmRelease;
use Dist::Zilla::Plugin::UploadToCPAN;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Clean;

has homepage => (
  is      => 'ro' ,
  isa     => 'Maybe[Str]' ,
  lazy    => 1 ,
  default => sub { $_[0]->payload->{homepage} } ,
);

has bugtracker => (
  is      => 'ro' ,
  isa     => 'Maybe[Str]' ,
  lazy    => 1,
  default => sub { $_[0]->payload->{bugtracker} } ,
);

sub configure {
    my $self = shift;

    $self->add_plugins(
        [ 'Git::GatherDir' =>
            { exclude_filename => [qw/README.pod META.json cpanfile LICENSE/] }],
        'PruneCruft',
        'ManifestSkip',
        'License',
        [ MetaNoIndex => {
            directory => [qw/t xt examples/],
        }],
        ['MetaProvides::Package' => { meta_noindex => 1 } ],
        'MetaJSON',
        'ModuleBuild',
        'Manifest',
        ['AutoPrereqs' => {skips=>['^strict$','^warnings$', '^utf8$']}],
        'CPANFile',
        'ExecDir',
        'ShareDir',
        'ExtraTests',
        'CheckChangesHasContent',
        ['NextRelease' => {
            format=>'%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ}d%{ (TRIAL RELEASE)}T',
        }],
        'OurPkgVersion',
        'PodWeaver',
        'InstallGuide',
        ['Test::Compile' => {
            fake_home => 1,
            fail_on_warning=>'none',
        }],
        'TestRelease',
        [ 'ReadmeAnyFromPod' => { # TODO escaping of '::' in metacpan urls in readme
            type=>'markdown',
            filename=>'README.md',
            location=>'build',
        }],
        [ 'CopyFilesFromBuild' => { copy => ['README.md', 'cpanfile', 'LICENSE'] } ],
        # TODO default homepage should be metacpan!
        ['GithubMeta' => {
            issues=>1,
            ($self->homepage ? (homepage => $self->homepage) : ()),
        }],
        ['SourceHutMeta' => {
            bugtracker => $self->bugtracker,
            ($self->homepage ? (homepage => $self->homepage) : ()),
        }],
        [ 'Git::Check' => {
            allow_dirty => [qw/dist.ini Changes README.md cpanfile/]
        }],
        'ConfirmRelease',
        'UploadToCPAN',
        [ 'Git::Commit' => 'Commit_Dirty_Files' => {
            allow_dirty => [qw/dist.ini Changes README.md/],
            commit_msg => 'Release %V'
        }],
        ['Git::NextVersion' => {
            first_version => '0.900',
            version_regexp => '^(\d+\..+)$',
        }],
        ['Git::Tag' => {
            tag_format => '%v',
            tag_message => 'release %v',
        }],
        [ 'Git::Push' => { push_to => ['origin'] } ],
        'Clean',
    );
}

q{ listening to: FM4 Jahrescharts 2020};

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::DOMM - Dist::Zilla config suiting my needs

=head1 VERSION

version 0.912

=head1 DESCRIPTION

My feeble attempt to come up with a suitable and unified (for me) Dist::Zilla config.

This seems a bit saner then my previous approach (copy C<dist.ini> from project to project, each time with some slight changes). I do think that setting Dist::Zilla up is way too much work, but I don't agree with all the opinions in Dist::Milla, so here we are...

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
