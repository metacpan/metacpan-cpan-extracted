package Git::ReleaseRepo::Repository;
{
  $Git::ReleaseRepo::Repository::VERSION = '0.006';
}

use Moose;
extends 'Git::Repository::Plugin';
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catfile catdir );

# The list of subs to install into the object
sub _keywords { qw(
    submodule submodule_git outdated_tag outdated_branch checkout list_version_refs
    list_versions latest_version list_release_branches latest_release_branch
    version_sort show_ref ls_remote has_remote has_branch release_prefix
    current_release current_branch run_cmd
) }

# I do not like this, but I can't think of any better way to have a default
# that does the right thing and does what I mean
has release_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'v',
);

sub submodule {
    my ( $self ) = @_;
    my %submodules;
    for my $line ( $self->run( 'submodule' ) ) {
        # <status><SHA1 hash> <submodule> (ref name)
        $line =~ m{^.(\S+)\s(\S+)};
        $submodules{ $2 } = $1;
    }
    return wantarray ? %submodules : \%submodules;
}

sub submodule_git {
    my ( $self, $module ) = @_;
    my $git = Git::Repository->new(
        work_tree => catdir( $self->work_tree, $module ),
    );
    if ( $self->release_prefix ) {
        $git->release_prefix( $self->release_prefix );
    }
    return $git;
}

sub outdated_branch {
    my ( $self, $branch ) = @_;
    $branch ||= "master";
    my %submod_refs = $self->submodule;
    my @outdated;
    for my $submod ( keys %submod_refs ) {
        my $ref = "refs/remotes/origin/$branch";
        my $subgit = $self->submodule_git( $submod );
        my %remote = $subgit->show_ref;
        if ( !exists $remote{ $ref } || $submod_refs{ $submod } ne $remote{ $ref } ) {
            push @outdated, $submod;
        }
    }
    return @outdated;
}

sub outdated_tag {
    my ( $self, $tag ) = @_;
    my %submod_refs = $self->submodule;
    my @outdated;
    for my $submod ( keys %submod_refs ) {
        my $ref = "refs/tags/$tag";
        my $subgit = $self->submodule_git( $submod );
        my %remote = $subgit->show_ref;
        if ( !exists $remote{ $ref } || $submod_refs{ $submod } ne $remote{ $ref } ) {
            push @outdated, $submod;
        }
    }
    return @outdated;
}

sub checkout {
    my ( $self, $commit ) = @_;
    # git will not remove submodule directories, in case they have stuff in them
    # So let's compare the list and see what we need to remove
    my %current_submodule = $self->submodule;
    $commit //= "master";
    my $cmd = $self->command( checkout => $commit );
    my @stderr = readline $cmd->stderr;
    my @stdout = readline $cmd->stdout;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not checkout '$commit'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }
    $cmd = $self->command( submodule => update => '--init' );
    @stderr = readline $cmd->stderr;
    @stdout = readline $cmd->stdout;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not update submodules to '$commit'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }

    # Remove any submodule directories that no longer belong
    my @missing = grep { exists $current_submodule{ $_ } }
                map { s{^[?]*\s+|/$}{}g; $_ }
                grep { /^[?]{2}/ }
                $self->run( status => '--porcelain' );
    remove_tree( catdir( $self->work_tree, $_ ) ) for @missing;
}

sub list_version_refs {
    my ( $self, $match, $rel_branch ) = @_;
    my $prefix = $rel_branch // $self->release_prefix;
    my %refs = $self->show_ref;
    my @versions = reverse sort version_sort grep { m{^$prefix} } map { (split "/", $_)[-1] } grep { m{^refs/$match/} } keys %refs;
    return @versions;
}

sub list_versions {
    my ( $self, $rel_branch ) = @_;
    return $self->list_version_refs( 'tags', $rel_branch );
}

sub latest_version {
    my ( $self, $rel_branch ) = @_;
    my @versions = $self->list_versions( $rel_branch );
    return $versions[0];
}

sub list_release_branches {
    my ( $self, $ref ) = @_;
    $ref ||= 'heads';
    return $self->list_version_refs( $ref );
}

sub latest_release_branch {
    my ( $self, $ref ) = @_;
    my @branches = $self->list_release_branches( $ref );
    return $branches[0];
}

sub version_sort {
    # Assume Semantic Versioning style, plus prefix
    # %s.%i.%i%s
    my @a = $a =~ /^\D*(\d+)[.](\d+)(?:[.](\d+))?/;
    my @b = $b =~ /^\D*(\d+)[.](\d+)(?:[.](\d+))?/;

    # Assume the 3rd number is 0 if not given
    $a[2] //= 0;
    $b[2] //= 0;

    my $format = ( "%03i" x @a );
    return sprintf( $format, @a ) cmp sprintf( $format, @b );
}

sub show_ref {
    my ( $self ) = @_;
    my %refs;
    my $cmd = $self->command( 'show-ref', '--head' );
    while ( defined( my $line = readline $cmd->stdout ) ) {
        # <SHA1 hash> <symbolic ref>
        my ( $ref_id, $ref_name ) = split /\s+/, $line;
        $refs{ $ref_name } = $ref_id;
    }
    return wantarray ? %refs : \%refs;
}

sub ls_remote {
    my ( $self ) = @_;
    my %refs;
    my $cmd = $self->command( 'ls-remote', 'origin' );
    while ( defined( my $line = readline $cmd->stdout ) ) {
        # <SHA1 hash> <symbolic ref>
        my ( $ref_id, $ref_name ) = split /\s+/, $line;
        $refs{ $ref_name } = $ref_id;
    }
    return wantarray ? %refs : \%refs;
}
#memoize( 'ls_remote', NORMALIZER => sub { return shift->work_tree } );

sub has_remote {
    my ( $self, $name ) = @_;
    return grep { $_ eq $name } $self->run( 'remote' );
}

sub has_branch {
    my ( $self, $name ) = @_;
    return grep { $_ eq $name } map { s/[*]?\s+//; $_ } $self->run( 'branch' );
}

sub current_branch {
    my ( $self ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $self->run( 'branch' );
    return $branches[0];
}

sub current_release {
    my ( $self ) = @_;
    $self->command( 'fetch', '--tags' );
    my %ref = $self->show_ref;
    my @tags = ();
#    ; use Data::Dumper;
#    ; warn Dumper \%ref;
    for my $key ( keys %ref ) {
        next unless $key =~ m{^refs/tags};
        if ( $ref{$key} eq $ref{HEAD} ) {
            my ( $tag ) = $key =~ m{/([^/]+)$};
            push @tags, $tag;
        }
    }
#    ; warn "Found: " . Dumper \@tags;
    my $version = [ sort version_sort @tags ]->[0];
#    ; warn "Current release: $version";
    return $version;
}

sub run_cmd {
    my ( $self, @command ) = @_;
    my $cmd = $self->command( @command );
    my $stdout = readline $cmd->stdout;
    my $stderr = readline $cmd->stderr;
    $cmd->close;
    my $code = $cmd->exit;
    return ( $code, $stdout, $stderr );
}

1;
