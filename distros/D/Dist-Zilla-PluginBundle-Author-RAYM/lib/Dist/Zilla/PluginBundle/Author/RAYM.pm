package Dist::Zilla::PluginBundle::Author::RAYM;
{
  $Dist::Zilla::PluginBundle::Author::RAYM::VERSION = '0.002';
}

# ABSTRACT: Dist::Zilla plugin bundle used by RAYM

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# if set, trigger FakeRelease instead of UploadToCPAN
has no_cpan => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    default => sub { $ENV{NO_CPAN} || $_[0]->payload->{no_cpan} || 0 }
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

sub configure {
    my $self = shift;

    my %basic_opts = (
        '-bundle' => '@Basic',
        '-remove' => [ 'Readme' ]
    );

    if ( $self->no_cpan ) {
        push @{ $basic_opts{'-remove'} }, 'UploadToCPAN';
        $self->add_plugins( 'FakeRelease' );
    }

    $self->add_bundle( '@Filter' => \%basic_opts );

    $self->add_plugins(        
        'PodWeaver',
        'MetaResourcesFromGit',
        'ReadmeFromPod',
        [
            'AutoPrereqs' => {
                length $self->skip_deps ? ( 'skip' => [ $self->skip_deps ] ) : ()
            }
        ],
        'PkgVersion',
        'Test::Compile',
        'NoSmartCommentsTests',
        'NextRelease',
        [
            'PruneFiles' => {
                'filenames' => 'dist.ini',
                length $self->skip_files ? ( 'match' => [ $self->skip_files ] ) : ()
            }
        ],
        'Git::NextVersion',
        [
            'Git::CommitBuild' => {
                branch          => '',                
                release_branch  => 'releases',
                release_message => ( $self->_get_changes || 'Build results of %h on %b' )
            }
        ],
        # CommitBuild -must- come before these
        'Git::Check',
        'Git::Commit',
        [
            'Git::Tag' => {
                branch => 'releases'
            }
        ],
        'Git::Push',
    );

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

Dist::Zilla::PluginBundle::Author::RAYM - Dist::Zilla plugin bundle used by RAYM

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This is the plugin bundle that RAYM uses. It is equivalent to:

 [@Filter]
 -bundle = @Basic
 -remove = Readme

 [PodWeaver]

 [ReadmeFromPod]

 [MetaResourcesFromGit]

 [AutoPrereqs]

 [PkgVersion]

 [Test::Compile]

 [NoSmartCommentsTests]

 [NextRelease]

 [FakeRelease]

 [PruneFiles]
 filename = dist.ini

 [Git::NextVersion]

 [Git::CommitBuild]
 branch          =
 release_branch  = releases
 release_message = <changelog section content>

 [Git::Check]

 [Git::Commit]

 [Git::Tag]

 [Git::Push]

=head1 RATIONALE

The bundle is desgined for projects which are hosted on C<github>.
More so, the project should have a C<master> branch where you do code
development, and a separete 'releases' branch which is where the
I<built> code is committed.

Use of the L<Dist::Zilla::Plugin::MetaResourcesFromGit> plugin creates links
at CPAN which point to the GitHub pages (the wiki page is used as the default
Homepage).

=head1 CONFIGURATION

The package version is determined by the L<Git::NextVersion> plugin;
this can be overridden by setting the environment variable C<V>:

  V=1.000 dzil build ...

If you provide the C<no_cpan> option with a true value to the bundle, or set
the environment variable C<NO_CPAN> to a true value, then the upload to CPAN
will be suppressed.

If you provide a value to the C<skip_deps> option then it will be passed to
the C<AutoPrereqs> Plugin as the C<skip> attribute.

If you provide a value to the C<skip_files> option then it will be passed to
the C<PruneFiles> Plugin as the C<match> attribute.

=head1 TIPS

Do not include a C<NAME>, C<VERSION>, C<AUTHOR> or C<LICENSE> POD section in
your code, they will be provided automatically.

=head1 CREDITS

This bundle is mostly stolen from Dist::Zilla::PluginBundle::Author::OLIVER.

=head1 AUTHOR

Ray Miller

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ray Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
