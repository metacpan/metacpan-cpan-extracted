use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::OpusVL;

use Moose;
use 5.014;
with (
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
    'Dist::Zilla::Role::PluginBundle::Config::Slicer',
);

our $VERSION = '0.014';
 
sub configure {
    my ($self) = @_;

    die "CPAN::Mini::Inject::REST hostname must be set in mcpani_host"
        if not $self->payload->{mcpani_host};

    my $remove = $self->payload->{ $self->plugin_remover_attribute } || [];
 
    $self->add_plugins(
        [
            'Git::GatherDir' =>
                GatherActualCode => {
                    exclude_filename => [
                        qw( LICENSE )
                    ]
                }
        ],
        [
            CopyFilesFromBuild =>
                CopyLicenseAndThings => {
                    copy => [ qw( LICENSE ) ]
                }
        ],
    qw(
        Prereqs::FromCPANfile
        PodWeaver
    ));
    $self->add_bundle('@Starter', {
        '-remove' => [ 'GatherDir', 'UploadToCPAN', 'TestRelease', @$remove ],
    });

    $self->add_plugins(qw(
        CheckChangesHasContent
        RewriteVersion
        NextRelease
        Repository
    ),
        [ Encoding => 
            CommonBinaryFiles => {
                match => '\.(png|jpg|db)$',
                encoding => 'bytes'
        } ],
        [ 'Git::Commit' =>
            CommitGeneratedFiles => { 
                allow_dirty => [ qw/dist.ini Changes cpanfile LICENSE/ ]
        } ],
        'ExecDir',
        [ ExecDir =>
            ScriptDir => { dir => 'script' }
        ],
    qw(
        Git::Tag
        BumpVersionAfterRelease
    ),
        ['Git::Commit' => 
            CommitVersionBump => { allow_dirty_match => '^lib/', commit_msg => "Bumped version number" } ],
        'Git::Push',
        ['CPAN::Mini::Inject::REST' => 
            $self->config_slice({
                mcpani_host => 'host',
                mcpani_port => 'port',
                mcpani_protocol => 'protocol',
            }) ],
        [ Prereqs => 'TestMoreWithSubtests' => {
            -phase => 'test',
            -type  => 'requires',
            'Test::More' => '0.96'
        } ],
    );
}
 
__PACKAGE__->meta->make_immutable;
no Moose;
 
1;

=encoding utf8

=head1 NAME

Dist::Zilla::PluginBundle::Author::OpusVL - Standard behaviour for OpusVL modules

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::OpusVL]
    mcpani_host = some.cpan.host

=head1 DESCRIPTION

This generally implements the workflow that OpusVL modules will use.

It is roughly equivalent to:

  [Git::GatherDir]
  [@Starter]
  ; ...but without GatherDir and UploadToCPAN or TestRelease

  [Prereqs::FromCPANfile]
  [CheckChangesHasContent]
  [RewriteVersion]
  [NextRelease]
  [Repository]
  [PodWeaver]
  finder = :InstallModules
  
  [Git::Commit / CommitGeneratedFiles]
  allow_dirty = dist.ini
  allow_dirty = Changes 
  allow_dirty = cpanfile 
  allow_dirty = LICENSE
  [ExecDir]
  dir = script

  [Git::Tag]
  [BumpVersionAfterRelease]
  [Git::Commit / CommitVersionBump]
  allow_dirty_match = ^lib/
  commit_msg = "Bumped version number"

  [Git::Push]
  [CPAN::Mini::Inject::REST]

  [Prereqs / TestMoreWithSubtests]
  -phase = test
  -type  = requires
  Test::More = 0.96

Your module files should contain:

  # ABSTRACT: frobnicates the whirligigs

  our $VERSION = '0.001';

For PodWeaver (the ABSTRACT) and RewriteVersion (the $VERSION).

Your script files should additionally contain

  # PODNAME: myscript

Modules and scripts should thus not contain a NAME section in their POD.

=head1 TODO

The two modules in this distribution need to be split into roles so we don't
have to provide dummy data for mcpani_host in the ToCPAN version that doesn't
use it.
