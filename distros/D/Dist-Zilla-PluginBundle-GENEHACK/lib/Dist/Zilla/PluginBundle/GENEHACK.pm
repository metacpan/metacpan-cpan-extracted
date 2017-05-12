package Dist::Zilla::PluginBundle::GENEHACK;
our $AUTHORITY = 'cpan:GENEHACK';
$Dist::Zilla::PluginBundle::GENEHACK::VERSION = '0.700';
# ABSTRACT: BeLike::GENEHACK when you zilla your dist


use Moose;
use namespace::autoclean;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::Plugin::GatherDir;

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Basic;

use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::Authority;
use Dist::Zilla::Plugin::MinimumPerl;
use Dist::Zilla::Plugin::PkgVersion;
use Dist::Zilla::Plugin::TaskWeaver;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::GithubMeta;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::ExtraTests;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::Test::EOL;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::InstallRelease;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::Twitter;
use Dist::Zilla::Plugin::Run;

has homepage => (
  is      => 'ro' ,
  isa     => 'Maybe[Str]' ,
  lazy    => 1 ,
  default => sub { $_[0]->payload->{homepage} } ,
);

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{task} },
);

sub configure {
  my $self = shift;

  $self->add_plugins(['GatherDir' => {
    exclude_match    => '^release.*' ,
    exclude_filename => [ 'dist.ini' , 'INSTALL' ],
  }]);

  $self->add_bundle('Filter' => {
    bundle => '@Basic' ,
    remove => [ 'GatherDir' , 'Readme' ] ,
  });

  $self->add_plugins(
    # auto-versioning from git
    'Git::NextVersion',

    # automatically build deps list
    'AutoPrereqs' ,

    # does what it says on the tin
    'CheckChangesHasContent' ,

    # include $VERSION in all files
    'PkgVersion',

    # munge files to add authority info
    [ 'Authority' => { authority => 'cpan:GENEHACK' , do_metadata => 1 } ],

    # automagically determine minimum required perl version
    'MinimumPerl' ,

  );

  # weave together POD bits or build a task module
  if ($self->is_task) { $self->add_plugins('TaskWeaver') }
  else {                $self->add_plugins('PodWeaver')  }

  $self->add_plugins(
    # include a bunch of dist::zilla meta info in META.* files
    'MetaConfig' ,

    # include a META.json file in addition to META.yml
    'MetaJSON' ,
  );

  my $github_meta_config = { issues => 1 };
  $github_meta_config->{homepage} = $self->homepage
    if $self->homepage;

  $self->add_plugins(
    [ 'GithubMeta' => $github_meta_config ] ,

    # auto-make INSTALL
    'InstallGuide' ,

    # and copy it from the build
    [ 'CopyFilesFromBuild' => { copy => 'INSTALL' } ],

    # munge Changes
    'NextRelease' ,

    # testing is good.
    'ExtraTests' ,

    # really good
    'PodCoverageTests' ,
    'PodSyntaxTests' ,

    # oh, so very good
    'Test::EOL' ,
    'Test::Compile' ,

    # git magic
    ['Git::Commit' => { add_files_in => 'releases/' } ],
    'Git::Tag',

    # install dist after release
    [ 'InstallRelease' => { install_command => 'cpanm .' } ] ,

    'Git::Push',

    # tweet releases. because i can.
    'Twitter' ,

    ['Run::BeforeBuild' => {
      run => 'rm -f Makefile.PL' ,
    }],

    ['Run::AfterBuild' => {
      run => [
        'cp %d/Makefile.PL ./' ,
        "git status --porcelain | grep 'M Makefile.PL' && git commit -m 'auto-committed by dist.ini' Makefile.PL || echo Makefile.PL up to date" ,
      ] ,
    }],

    ['Run::Release' => {
      run          => 'mv %a ./releases/' ,
      add_files_in => 'releases/' ,
    }] ,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::GENEHACK - BeLike::GENEHACK when you zilla your dist

=head1 VERSION

version 0.700

=head1 SYNOPSIS

Loads the stuff I find myself using all the time. Currently equivalent to
this:

    [GatherDir]
    exclude_match    = ^release.*
    exclude_filename = dist.ini
    exclude_filename = INSTALL

    [@Filter]
    -bundle = @Basic
    -remove = GatherDir
    -remove = Readme

    [Git::NextVersion]

    [AutoPrereqs]
    [CheckChangesHasContent]
    [Authority]
    authority='cpan:GENEHACK'
    do_metadata=1
    [MinimumPerl]
    [PkgVersion]
    [Taskweaver]   ; if is_task is set
    [PodWeaver]    ; if is_task is NOT set
    [MetaConfig]
    [MetaJSON]
    [GithubMeta]
    ; if needed, override homepage with 'homepage' param to @GENEHACK
    issues = 1
    [InstallGuide]
    [CopyFilesFromBuild]
    copy=INSTALL
    [NextRelease]
    [ExtraTests]
    [PodCoverageTests]
    [PodSyntaxTests]
    [EOLTests]
    [Test::Compile]
    [Git::Tag]
    [Git::Commit]
    add_files_in = releases/
    [InstallRelease]
    install_command='cpanm .'
    [Git::Push]
    [Twitter]
    [Run::BeforeBuild]
    run = rm -f Makefile.PL
    [Run::AfterBuild]
    run = cp %d/Makefile.PL ./
    run = git status --porcelain | grep 'M Makefile.PL' && git commit -m 'auto-committed by dist.ini' Makefile.PL || echo Makefile.PL up to date
    [Run::Release]
    run = mv %a ./releases/
    add_files_in = releases/

=for Pod::Coverage configure

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
