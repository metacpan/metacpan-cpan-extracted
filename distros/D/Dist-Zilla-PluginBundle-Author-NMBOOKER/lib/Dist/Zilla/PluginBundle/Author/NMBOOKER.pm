use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::NMBOOKER;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $VERSION = '0.001';

use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;

sub configure {
    my ($self) = @_;

    $self->add_plugins(qw(
        Git::GatherDir
        Prereqs::FromCPANfile
    ));
    $self->add_bundle('@Filter', {
        '-bundle' => '@Basic',
        '-remove' => [ 'GatherDir', 'TestRelease', ],
    });

    $self->add_plugins(qw(
        AutoPrereqs
        ReadmeFromPod
        MetaConfig
        MetaJSON
        PodSyntaxTests
        Test::Compile
        Test::ReportPrereqs
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
        # Don't try to weave scripts. They have their own POD.
        [ PodWeaver => { finder => ':InstallModules' } ],
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::NMBOOKER

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::NMBOOKER]

=head1 DESCRIPTION

This generally implements the workflow that NMBOOKER's modules will use.

It is roughly equivalent to:

  [Git::GatherDir]
  [@Basic]

  [Prereqs::FromCPANfile]
  [AutoPrereqs]
  [ReadmeFromPod]
  [MetaConfig]
  [MetaJSON]
  [PodSyntaxTests]
  [Test::Compile]
  [Test::ReportPrereqs]
  [CheckChangesHasContent]
  [RewriteVersion]
  [NextRelease]
  [Repository]
  [PodWeaver]
  
  [Git::Commit / CommitGeneratedFiles]
  allow_dirty = dist.ini
  allow_dirty = Changes 
  allow_dirty = cpanfile 
  allow_dirty = LICENSE

  [Git::Tag]
  [BumpVersionAfterRelease]
  [Git::Commit / CommitVersionBump]
  allow_dirty_match = ^lib/
  commit_msg = "Bumped version number"

  [Git::Push]

  [Prereqs / TestMoreWithSubtests]
  -phase = test
  -type  = requires
  Test::More = 0.96

=head1 NAME

Dist::Zilla::PluginBundle::Author::NMBOOKER - Standard behaviour for NMBOOKER's modules

=head1 COPYRIGHT AND LICENSE

I've based this on a clone of L<Dist::Zilla::PluginBundle::Author::OpusVL>,
under the terms of the BSD license, so I hereby acknowledge their copyright.

Copyright (C) 2015, Nicholas Booker
Copyright (C) 2015, OpusVL

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Nicholas Booker <nmb+cpan@nickbooker.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Nicholas Booker.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
