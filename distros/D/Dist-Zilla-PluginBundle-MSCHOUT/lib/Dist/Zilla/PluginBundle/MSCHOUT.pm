#
# This file is part of Dist-Zilla-PluginBundle-MSCHOUT
#
# This software is copyright (c) 2023 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Dist::Zilla::PluginBundle::MSCHOUT;
$Dist::Zilla::PluginBundle::MSCHOUT::VERSION = '0.40';
# ABSTRACT: Use L<Dist::Zilla> like MSCHOUT does

use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean 0.09;

use Dist::Zilla 4.102341;

use Dist::Zilla::PluginBundle::Classic;
use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git 1.101230;

use Dist::Zilla::Plugin::AuthorSignatureTest;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::AutoVersion;
use Dist::Zilla::Plugin::CheckPrereqsIndexed;
use Dist::Zilla::Plugin::FakeRelease;
use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::GithubMeta;
use Dist::Zilla::Plugin::InsertCopyright;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MinimumPerl;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::Prereqs::AuthorDeps;
use Dist::Zilla::Plugin::RemovePrereqs;
use Dist::Zilla::Plugin::Signature;
use Dist::Zilla::Plugin::TaskWeaver 0.093330;
use Dist::Zilla::Plugin::Twitter;

use Pod::Elemental::Transformer::List;
use Pod::Weaver::Plugin::SingleEncoding;
use Pod::Weaver::Section::AllowOverride;

with qw(Dist::Zilla::Role::PluginBundle::Easy
        Dist::Zilla::Role::PluginBundle::Config::Slicer
        Dist::Zilla::Role::PluginBundle::PluginRemover);

has is_task => (is => 'lazy', isa => 'Bool');

has release_branch => (is => 'lazy', isa => 'Str');

has upload => (is => 'lazy', isa => 'Bool');

sub configure {
    my $self = shift;

    my $args = $self->payload;

    my @remove = qw(PodVersion);

    # if not uploading, remove the upload plugin, and the confirmation plugin
    unless ($self->upload) {
        push @remove, 'UploadToCPAN', 'ConfirmRelease';
    }

    $self->add_plugins('CheckPrereqsIndexed');

    $self->add_bundle(Filter => {
        bundle => '@Classic',
        remove => \@remove
    });

    # add FakeRelease plugin if uploads are off
    unless ($self->upload) {
        $self->add_plugins('FakeRelease');
    }

    $self->add_plugins(
        qw(
            AutoPrereqs
            AuthorSignatureTest
            MinimumPerl
            InsertCopyright
            Signature
            Prereqs::AuthorDeps
            MetaProvides::Package
            MetaJSON
        ),
        # update release in Changes file
        [ NextRelease => { format => '%-2v  %{yyyy-MM-dd}d' } ],
        [ GithubMeta => { issues => 1 } ]
    );

    if ($self->is_task) {
        $self->add_plugins(
            'TaskWeaver',
            [ AutoVersion => { time_zone => 'America/Chicago' } ]
        );
    }
    else {
        $self->add_plugins(
            [ PodWeaver => { config_plugin => '@MSCHOUT' } ],
            [ 'Git::NextVersion' => { first_version => '0.01' } ]
        );
    }

    $self->add_plugins(
        [ 'Git::Check' ],
        'Git::Commit',
        [ 'Git::CommitBuild' => { release_branch => $self->release_branch } ],
        [ 'Git::Tag'         => { branch => $self->release_branch } ],
        [
            'Git::Push'        => {
                push_to => [
                    'origin master:master',
                    'origin build/releases:build/releases'
                ]
            }
        ],
    );

    # Module::Signature requires a massive wad of dependencies, and is
    # optional.  Remove it from the PREREQ list.
    $self->add_plugins(
        [ RemovePrereqs => { remove => 'Module::Signature' } ]
    );
}

sub _option {
    my ($self, $name, $default) = @_;

    if (exists $self->payload->{$name}) {
        return $self->payload->{$name}
    }
    else {
        return $default;
    }
}

sub _build_is_task {
    my $self = shift;

    # recognize older option name "task" if present
    my $task = $self->_option('task');
    if (defined $task) {
        return $task;
    }

    $self->_option('is_task', 0);
}

sub _build_release_branch {
    my $self = shift;

    $self->_option('release_branch', 'build/releases');
}

sub _build_upload {
    my $self = shift;

    ! $self->_option('no_upload', 0);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::MSCHOUT - Use L<Dist::Zilla> like MSCHOUT does

=head1 VERSION

version 0.40

=head1 DESCRIPTION

This is the pluginbundle that MSCHOUT uses. Use it as:

 [@MSCHOUT]

It's equivalent to:

 [@Filter]
 bundle = @Classic
 remove = PodVersion

 [AutoPrereqs]
 [AuthorSignatureTest]
 [MinimumPerl]
 [InsertCopyright]
 [PodWeaver]
 [Signature]
 [MetaJSON]
 [NextRelease]
    format = "%-2v  %{yyyy-MM-dd}d"

 [GithubMeta]
    issues = 1

 [Git::Check]
 [Git::Commit]
 [Git::NextVersion]
    first_version = 0.01
 [Git::CommitBuild]
    release_branch = build/releases
 [Git::Tag]
    branch = build/releases
 [Git::Push]

=head2 Options

Plugins can be removed from the bundle via L<Dist::Zilla::PluginBundle::PluginRemover>:

 [@MSCHOUT]
 -remove = AutoPrereqs
 ...

The following configuration settings are available:

=over 4

=item *

is_task

Replaces C<Pod::Weaver> with C<Task::Weaver> and uses C<AutoVersion> instead of
C<Git::NextVersion>

=item *

no_upload

Disables C<UploadToCPAN> and C<ConfirmRelease>.  Adds C<FakeRelease>.

=item *

release_branch

Sets the release branch name.  Default is C<build/releases>.
C<no_upload> is set, this plugin is skipped.

=back

This PluginBundle supports C<ConfigSlicer>, so you can pass in options to the
plugins used like this:

  [@MSCHOUT]
  RemovePrereqs.remove = Module::Signature

This PluginBundle also supports C<PluginRemover>, so removing a plugin is as simple as:

  [@MSCHOUT]
  -remove = NextRelease

=for Pod::Coverage configure

=head1 SOURCE

The development version is on github at L<https://https://github.com/mschout/dist-zilla-pluginbundle-mschout>
and may be cloned from L<git://https://github.com/mschout/dist-zilla-pluginbundle-mschout.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/dist-zilla-pluginbundle-mschout/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
