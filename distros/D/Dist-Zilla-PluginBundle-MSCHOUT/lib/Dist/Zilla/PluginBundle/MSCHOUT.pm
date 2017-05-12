package Dist::Zilla::PluginBundle::MSCHOUT;
$Dist::Zilla::PluginBundle::MSCHOUT::VERSION = '0.31';
# ABSTRACT: Use L<Dist::Zilla> like MSCHOUT does

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{task} }
);

sub configure {
    my $self = shift;

    my $args = $self->payload;

    my $upload = $$args{no_upload} ? 0 : 1;
    my $release_branch = $$args{release_branch} || 'build/releases';
    my $use_travis = $$args{use_travis} ? 1 : 0;

    my @remove = qw(PodVersion);

    # if not uploading, remove the upload plugin, and the confirmation plugin
    unless ($upload) {
        push @remove, 'UploadToCPAN', 'ConfirmRelease';
    }

    $self->add_plugins('CheckPrereqsIndexed');

    $self->add_bundle(Filter => {
        bundle => '@Classic',
        remove => \@remove
    });

    # add FakeRelease plugin if uploads are off
    unless ($upload) {
        $self->add_plugins('FakeRelease');
    }

    $self->add_plugins(
        qw(
            AutoPrereqs
            Repository
            Bugtracker
            Homepage
            Signature
            MetaJSON
            ArchiveRelease
        ),
        # update release in Changes file
        [ NextRelease => { format => '%-2v  %{yyyy-MM-dd}d' } ]
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

    # we must add Travis before Git::CommitBuild because CommitBuild needs to
    # include the .travis.yml file
    if ($use_travis) {
        $self->add_plugins(
            [ 'TravisYML' => { build_branch => $release_branch } ]
        );
    }

    $self->add_plugins(
        qw(
            Git::Check
            Git::Commit
        ),
        [ 'Git::CommitBuild' => { release_branch => $release_branch } ],
        [ 'Git::Tag'         => { branch => $release_branch } ],
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

    if ($$args{use_twitter} and $upload) {
        $self->add_plugins(
            [ Twitter => { hash_tags => '#perl' } ]
        );
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::MSCHOUT - Use L<Dist::Zilla> like MSCHOUT does

=head1 VERSION

version 0.31

=head1 DESCRIPTION

This is the pluginbundle that MSCHOUT uses. Use it as:

 [@MSCHOUT]

Optionally, for a dist that you do not want to upload to CPAN:
 [@MSCHOUT]
 no_upload = 1

It's equivalent to:

 [@Filter]
 bundle = @Classic
 remove = PodVersion

 [AutoPrereqs]
 [PodWeaver]
 [Repository]
 [Bugtracker]
 [Homepage]
 [Signature]
 [MetaJSON]
 [ArchiveRelease]
 [NextRelease]
    format = "%-2v  %{yyyy-MM-dd}d"
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

The following configuration settings are available:

=over 4

=item *

no_upload

Disables C<UploadToCPAN> and C<ConfirmRelease>.  Adds C<FakeRelease>.

=item *

release_branch

Sets the release branch name.  Default is C<build/releases>.

=item *

task

Replaces C<Pod::Weaver> with C<Task::Weaver> and uses C<AutoVersion> instead of
C<Git::NextVersion>

=item *

use_travis

Enables the L<TravisYML|Dist::Zilla::Plugin::TravisYML> Dist Zilla plugin.

=item *

use_twitter

Enables the L<Twitter|Dist::Zilla::Plugin::Twitter> Dist Zilla plugin.  If
C<no_upload> is set, this plugin is skipped.

=back

=for Pod::Coverage configure

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/dist-zilla-pluginbundle-mschout>
and may be cloned from L<git://github.com/mschout/dist-zilla-pluginbundle-mschout.git>

=head1 BUGS

Please report any bugs or feature requests to bug-dist-zilla-pluginbundle-mschout@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-MSCHOUT

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
