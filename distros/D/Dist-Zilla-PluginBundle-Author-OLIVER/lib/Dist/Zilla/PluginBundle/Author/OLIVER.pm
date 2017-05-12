package Dist::Zilla::PluginBundle::Author::OLIVER;
BEGIN {
  $Dist::Zilla::PluginBundle::Author::OLIVER::VERSION = '1.122720';
}

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# if set, trigger FakeRelease instead of UploadToCPAN
has no_cpan => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    default => sub { $ENV{NO_CPAN} || $_[0]->payload->{no_cpan} || 0 }
);

# major version number to help skip legacy versions
has major_version => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { $ENV{M} || $_[0]->payload->{major_version} || 1 }
);

# skip these dependencies
has skip_deps => (
    is  => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub { $_[0]->payload->{skip_deps} || '' },
);

# skip these files
has skip_files => (
    is  => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub { $_[0]->payload->{skip_files} || '' },
);

# skip these plugins from @Basic bundle
has skip_plugin => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { $_[0]->payload->{skip_plugin} || [] },
);

sub mvp_multivalue_args { qw(skip_plugin) }

sub configure {
    my $self = shift;

    $self->add_plugins(qw/
        MetaResourcesFromGit
        ReadmeFromPod
    /);

    my %basic_opts = (
        '-bundle' => '@Basic',
        '-remove' => [ 'Readme', @{ $self->skip_plugin } ],
    );

    if ($self->no_cpan) {
        $basic_opts{'-remove'}
            = [ 'Readme', @{ $self->skip_plugin }, 'UploadToCPAN' ];
        $self->add_plugins('FakeRelease');
    }

    $self->add_bundle('@Filter' => \%basic_opts);

    $self->add_plugins([ 'AutoVersion' => {
        'major' => $self->major_version
    }]);

    $self->add_plugins([ 'AutoPrereqs' => {
        length $self->skip_deps ?
            ('skip' => [ $self->skip_deps ]) : ()
    }]);

    $self->add_plugins(qw/
        NextRelease
        PkgVersion
        PickyPodWeaver
        MetaJSON
    /);

    $self->add_plugins([ 'PruneFiles' => {
        'filenames' => 'dist.ini',
        length $self->skip_files ?
            ('match' => [ $self->skip_files ]) : ()
    }]);

    # CommitBuild -must- come before @Git
    $self->add_plugins([ 'Git::CommitBuild' => {
        'branch' => '',
        'release_branch' => 'master',
        'message' => ($self->_get_changes
            || 'Build results of %h (on %b)'),
    }]);

    $self->add_bundle('@Git' => {
        'commit_msg' => 'Bumped changelog following rel. v%v'
    });
}

# stolen from Dist::Zilla::Plugin::Git::Commit
sub _get_changes {
    my $self = shift;

    # parse changelog to find commit message
    my $changelog = Dist::Zilla::File::OnDisk->new( { name => 'Changes' } );
    my $newver    = '{{\$NEXT}}';
    my @content   =
        grep { /^$newver(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog->content;
    shift @content; # drop the version line
    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return commit message
    return join("\n", @content, ''); # add a final \n
} # end _get_changes

__PACKAGE__->meta->make_immutable;
no Moose;
1;


=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::OLIVER - Dists like OLIVER's

=head1 VERSION

version 1.122720

=head1 DESCRIPTION

This is the plugin bundle that OLIVER uses. It is equivalent to:

 [MetaResourcesFromGit]
  
 [ReadmeFromPod]
 [@Filter]
 -bundle = @Basic
 -remove = Readme
  
 [AutoVersion]
 [NextRelease]
 [PkgVersion]
 [PickyPodWeaver]
 [AutoPrereqs]
 [MetaJSON]

 [PruneFiles]
 filenames = dist.ini
  
 [Git::CommitBuild]
 branch =
 release_branch = master
 message = <changelog section content>
  
 [@Git]
 commit_msg = Bumped changelog following rel. v%v 

=head1 RATIONALE

The intention is to have a sane L<http://github.com> layout and at the same
time supporting CPAN upload.

Development take place on a C<devel> branch at GitHub and then releases are
committed to the C<master> branch which is the default for user access. Commit
messages to the C<master> are the content of the latest section in the
C<Changes> file.

Use of the L<Dist::Zilla::Plugin::MetaResourcesFromGit> plugin creates links
at CPAN which point to the GitHub pages (the wiki page is used as the default
Homepage).

A minor customization to the L<Pod::Weaver> plugin restricts POD munging only
to those files containing an C<ABSTRACT> statement.

=head1 CONFIGURATION

If you provide the C<no_cpan> option with a true value to the bundle, or set
the environment variable C<NO_CPAN> to a true value, then the upload to CPAN
will be suppressed.

If you provide a value to the C<major_version> option then it will be passed
to the C<AutoVersion> Plugin as the C<major> attribute.

If you provide a value to the C<skip_deps> option then it will be passed to
the C<AutoPrereqs> Plugin as the C<skip> attribute.

If you provide a value to the C<skip_files> option then it will be passed to
the C<PruneFiles> Plugin as the C<match> attribute.

If you provide one or more instaces of the C<skip_plugin> option, then the
values will be removed from the list of plugins imported from the C<@Basic>
Plugin Bundle.

=head1 TIPS

Do not include a C<NAME>, C<VERSION>, C<AUTHOR> or C<LICENSE> POD section in
your code, they will be provided automatically. However please do include an
abstract for documented libraries via a comment like so:

 # ABSTRACT: here is my abstract statement

The bundle is desgined for projects which are hosted on C<github>. More so,
the project should have a C<master> branch which is where the I<built> code
is committed, and a I<separate> branch where you do code development. The
module author uses a C<devel> branch for this purpose. On C<github> you can
then leave the C<master> branch as the default branch for web browsing.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

# ABSTRACT: Dists like OLIVER's

